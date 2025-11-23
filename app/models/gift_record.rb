class GiftRecord < ApplicationRecord
  include WebpConvertible
  require "tempfile"
  # リレーション
  belongs_to :user
  belongs_to :event
  belongs_to :gift_person, foreign_key: "gift_people_id"
  has_many :favorites, dependent: :destroy
  belongs_to :gift_item_category, optional: true
  has_many :comments, dependent: :destroy

  # Active Storage - 複数画像対応
  has_many_attached :images
  # 動的に生成したOGP画像（S3に保存）
  has_one_attached :ogp_image

  belongs_to :parent_gift_record, class_name: "GiftRecord", optional: true
  has_many :return_gifts, class_name: "GiftRecord", foreign_key: "parent_gift_record_id"

  # Enum定義
  enum :gift_direction, { given: 0, received: 1 }
  enum :return_status, {
    not_required: 0,    # お返し不要
    planned: 1,         # お返し予定
    completed: 2        # お返し完了
  }

  # コールバック（データ整合性の自動保証）
  before_validation :sync_return_gift_flag
  before_validation :set_return_deadline
  after_commit :refresh_generated_ogp_image, on: :update, if: :saved_change_to_item_name?
  # 画像は登録・更新時にWebPへ非同期変換（共通Concernで処理）
  webp_convert_for :images

  # 必須フィールドのバリデーション（統一されたエラーメッセージ）
  validates :item_name, presence: { message: "を入力してください" }, length: { maximum: 30 }
  validates :gift_at, presence: { message: "を選択してください" }
  validates :event_id, presence: { message: "を選択してください" }
  validates :gift_people_id, presence: { message: "を選択してください" }

  validates :commentable, inclusion: { in: [ true, false ] }

  validates :parent_gift_record_id, presence: true, if: :is_return_gift?
  validates :parent_gift_record_id, absence: true, unless: :is_return_gift?
  validates :needs_return, inclusion: { in: [ false ] }, if: :is_return_gift?

  # オプションフィールドのバリデーション
  validates :amount, numericality: { greater_than: 0, allow_nil: true }
  validates :memo, length: { maximum: 300 }

  # カスタムバリデーション
  validate :gift_at_is_valid_date
  validate :gift_at_is_reasonable_date
  validate :images_validation

  validates :return_deadline, presence: true, if: -> { needs_return? && !is_return_gift? }

  # OGP画像戦略の決定
  def ogp_strategy
    case
    when suitable_ogp_images.any?
      :use_suitable_uploaded_image
    # 実体のある画像のみを判定対象にする（削除直後の残骸などを除外）
    when valid_image_attachments.any?
      :use_first_image_resized
    when item_name.present?
      :generate_dynamic_text_image
    else
      :use_default_image
    end
  end

  def ogp_image_url(request)
  begin
    helpers = Rails.application.routes.url_helpers

    strategy = ogp_strategy
    result = case strategy
    when :use_suitable_uploaded_image
              handle_suitable_uploaded_image(helpers, request)

    when :use_first_image_resized
              handle_first_image_resized(request)

    when :generate_dynamic_text_image
              handle_dynamic_text_image(helpers, request)

    when :use_default_image
              # モデル内で直接 image_url は使えないため、フォールバックURLを使用
              default_ogp_fallback_url(request)

    else
              default_ogp_fallback_url(request)
    end

    result

    rescue => e
      Rails.logger.error "Error in ogp_image_url: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      # 例外が発生した場合のフォールバック
      fallback_url = default_ogp_fallback_url(request)
      fallback_url
    end
  end

  # OGP用リサイズ画像
  def ogp_resized_image
    attachment = valid_image_attachments.first
    return nil unless attachment

    attachment.variant(
      resize_to_fill: [ 1200, 630 ],
      format: :png,
      background: "white",
      gravity: "center"
    )
  end

  # 最初の画像をリサイズして使用
  def handle_first_image_resized(request)
    first_attachment = valid_image_attachments.first
    return handle_default_image(request) unless first_attachment

    begin
      # 画像をOGPに適したサイズにリサイズ
      resized_url = Rails.application.routes.url_helpers.rails_representation_url(
        first_attachment.variant(resize_to_limit: [ 1200, 630 ]),
        host: request.base_url
      )

      resized_url
    rescue => e
      Rails.logger.error "Error resizing first image: #{e.message}"
      handle_default_image(request)
    end
  end

  # アップロード済みでOGPに適した画像を使用
  # - 適合画像の先頭を 1200x630 に収まるようリサイズし、公開URLを返す
  # - 失敗時は元の画像URL、さらに失敗時はデフォルト画像へフォールバック
  def handle_suitable_uploaded_image(helpers, request)
    attachment = suitable_ogp_images.first
    return handle_default_image(request) unless attachment

    begin
      variant = attachment.variant(resize_to_limit: [ 1200, 630 ])
      url = helpers.rails_representation_url(variant.processed, host: request.base_url)
      url = url.sub(%r{^http://}, "https://") if Rails.env.production?
      url
    rescue => e
      Rails.logger.warn "Variant generation failed for suitable image: #{e.message}"
      begin
        url = helpers.rails_blob_url(attachment, host: request.base_url)
        url = url.sub(%r{^http://}, "https://") if Rails.env.production?
        url
      rescue => e2
        Rails.logger.error "Blob URL generation failed: #{e2.message}"
        handle_default_image(request)
      end
    end
  end

  # テキストから動的にOGP画像を生成して使用
  # - S3へ添付した上で公開URLを返す
  def handle_dynamic_text_image(helpers, request)
    ensure_generated_ogp!
    if ogp_image.attached?
      url = helpers.rails_blob_url(ogp_image, host: request.base_url)
      url = url.sub(%r{^http://}, "https://") if Rails.env.production?
      url
    else
      default_ogp_fallback_url(request)
    end
  rescue => e
    Rails.logger.error "Dynamic OGP handling error: #{e.message}"
    default_ogp_fallback_url(request)
  end

 def handle_default_image(request)
  # image_urlを使って完全なURLを取得
  helpers = ActionController::Base.helpers

  # 完全なURLを生成（ドメイン + アセットハッシュ込み）
  url = helpers.image_url("ogp.webp", host: request.base_url)

  # 本番環境でのHTTPS強制
  url = url.sub(%r{^http://}, "https://") if Rails.env.production?

  url
rescue => e
  Rails.logger.error "Error getting default image: #{e.message}"
  # フォールバックもimage_urlを使用
  fallback_url = helpers.image_url("ogp.webp", host: request.base_url)
  fallback_url.sub(%r{^http://}, "https://") if Rails.env.production?
  fallback_url
end

  # OGPに適した画像の抽出
  def suitable_ogp_images
    @suitable_ogp_images ||= valid_image_attachments.select { |img| image_suitable_for_ogp?(img) }
  end

  # 生成OGPの作成と添付（S3へ）
  def ensure_generated_ogp!
    return if ogp_image.attached?

    text = item_name.presence || "ギフト記録"
    image = OgpCreator.build(text)
    tempfile = Tempfile.new([ "ogp_#{id}", ".webp" ])
    tempfile.binmode
    tempfile.write(image.to_blob)
    tempfile.rewind

    ogp_image.attach(
      io: tempfile,
      filename: "ogp_#{id}.webp",
      content_type: "image/webp"
    )

    image.destroy!
    tempfile.close!
  rescue => e
    Rails.logger.error "OGP生成/添付エラー: #{e.message}"
  end

  def refresh_generated_ogp_image
    return unless ogp_strategy == :generate_dynamic_text_image

    ogp_image.purge if ogp_image.attached?
    ensure_generated_ogp!
  rescue => e
    Rails.logger.error "OGP再生成エラー: #{e.message}"
  end

  def default_ogp_fallback_url(request)
    OgpUrlService.default_fallback_url(request)
  end


  # スコープ（クエリの再利用性と可読性向上）
  scope :recent, -> { order(created_at: :desc) }
  scope :by_date_range, ->(from, to) { where(gift_at: from..to) }
  scope :by_gift_person, ->(gift_person_id) { where(gift_people_id: gift_person_id) }
  scope :with_amount, -> { where.not(amount: nil) }
  scope :current_month, -> { where(gift_at: Date.current.beginning_of_month..Date.current.end_of_month) }
  scope :current_year, -> { where(gift_at: Date.current.beginning_of_year..Date.current.end_of_year) }
  scope :commentable, -> { where(commentable: true) }
  scope :comment_disabled, -> { where(commentable: false) }

  scope :received_gifts, -> { where(gift_direction: :received) }
  scope :given_gifts, -> { where(gift_direction: :given) }
  scope :return_gifts, -> { where(is_return_gift: true) }
  scope :original_gifts, -> { where(is_return_gift: false) }
  scope :needs_return, -> { where(needs_return: true) }

  # インスタンスメソッド
  def display_amount
    return "未設定" unless amount.present?

    # ActiveSupport::NumberHelperを使用してフォーマット
    "¥#{ActiveSupport::NumberHelper.number_to_delimited(amount)}"
  end

  def display_gift_date
    gift_at.present? ? I18n.l(gift_at, format: :short) : "未設定"
  end

  def display_item_name
    item_name.presence || "未設定"
  end

  # 画像関連のヘルパーメソッド
  def main_image
    images.attached? ? images.first : nil
  end

  def has_images?
    valid_image_attachments.any?
  end

  def images_count
    valid_image_attachments.count
  end

  # 実体のある画像添付のみを返すユーティリティ
  # - blobが存在し、MIMEがimage/*、サイズ>0 を満たすもの
  # - 遅延パージや不完全な添付を除外
  def valid_image_attachments
    return [] unless images.attached?

    images.attachments.select do |attachment|
      begin
        blob = attachment.blob
        blob.present? &&
          blob.content_type.to_s.start_with?("image/") &&
          blob.byte_size.to_i > 0
      rescue => e
        Rails.logger.warn "無効な画像添付を除外: #{e.class}: #{e.message} (attachment_id=#{attachment.id})"
        false
      end
    end
  end

 # OGPに適した画像かどうかの判定
 def image_suitable_for_ogp?(attachment)
  # ActiveStorage::Attachmentオブジェクトかチェック
  return false unless attachment.is_a?(ActiveStorage::Attachment)

  # blobが存在するかチェック
  return false unless attachment.blob.present?

  begin
    blob = attachment.blob

    # 画像ファイルかチェック
    return false unless blob.content_type&.start_with?("image/")

    # メタデータが存在するかチェック
    metadata = blob.metadata
    return false unless metadata["width"] && metadata["height"]

    # アスペクト比チェック（1.91:1 = 1200x630に近い）
    aspect_ratio = metadata["width"].to_f / metadata["height"].to_f
    suitable_ratio = (1.7..2.1).include?(aspect_ratio)

    # サイズチェック（最小サイズ）
    suitable_size = metadata["width"] >= 600 && metadata["height"] >= 315

    result = suitable_ratio && suitable_size

    result
  rescue => e
    Rails.logger.error "OGP画像適性チェックエラー: #{e.message}"
    Rails.logger.error "Attachment: #{attachment.inspect}"
    false
  end
end

  private

  def gift_at_is_valid_date
    return unless gift_at.present?

    # 日付型の妥当性チェック
    unless gift_at.is_a?(Date) || gift_at.is_a?(Time)
      begin
        Date.parse(gift_at.to_s)
      rescue ArgumentError
        errors.add(:gift_at, "は有効な日付を入力してください")
      end
    end
  end

  def gift_at_is_reasonable_date
    return unless gift_at.present? && !errors.has_key?(:gift_at)

    # 日付を正規化
    date = gift_at.is_a?(Date) ? gift_at : Date.parse(gift_at.to_s)

    # 過去100年以内の妥当性チェック
    if date < 100.years.ago
      errors.add(:gift_at, "は100年以内の日付を入力してください")
    end

    # 未来30年以内の妥当性チェック（ギフトの予定日も考慮）
    if date > 30.year.from_now
      errors.add(:gift_at, "は30年以内の日付を入力してください")
    end
  end

  def event_exists_and_valid
    return unless event_id.present?

    # 選択されたイベントが存在するかチェック
    unless Event.exists?(event_id)
      errors.add(:event_id, "選択されたイベントは存在しません")
      return
    end

    # イベントが有効な状態かチェック
    event_record = Event.find_by(id: event_id)
    if event_record&.name.blank?
      errors.add(:event_id, "選択されたイベントは無効です")
    end
  rescue StandardError => e
    Rails.logger.error "Event validation error: #{e.message}"
    errors.add(:event_id, "イベントの確認中にエラーが発生しました")
  end

  # 画像アップロードのバリデーション
  def images_validation
    return unless images.attached?

    # 枚数制限チェック（5枚まで）
    if images.count > 5
      errors.add(:images, "は5枚まで添付できます")
      return
    end

    images.each_with_index do |image, index|
      # ファイル形式チェック
      unless image.content_type.in?(%w[image/jpeg image/jpg image/png image/webp])
        add_unique_image_error("#{index + 1}枚目: JPEG、PNG、WEBP形式のファイルのみアップロードできます")
      end

      # ファイルサイズチェック（5MBまで）
      if image.blob.byte_size > 5.megabytes
        add_unique_image_error("#{index + 1}枚目: ファイルサイズは5MB以下にしてください")
      end
    end
  rescue StandardError => e
    Rails.logger.error "Images validation error: #{e.message}"
    errors.add(:images, "画像の検証中にエラーが発生しました")
  end

  def add_unique_image_error(message)
    errors.add(:images, message) unless errors[:images].include?(message)
  end

  def sync_return_gift_flag
    self.is_return_gift = parent_gift_record_id.present?
  end

  def set_return_deadline
    if needs_return? && !is_return_gift? && return_deadline.blank?
      # 一般的に内祝いは1ヶ月以内
      self.return_deadline = Date.current + 1.month
    end
  end

  # Ransack ホワイトリスト 管理者画面で使用
  def self.ransackable_attributes(auth_object = nil)
    %w[
      item_name memo gift_at created_at updated_at
      user_id gift_people_id event_id gift_item_category_id
      is_public gift_direction
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[
      gift_person event user gift_item_category
    ]
  end
end
