require "stringio"

class GiftRecord < ApplicationRecord
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
  enum gift_direction: { given: 0, received: 1 }
  enum return_status: {
    not_required: 0,    # お返し不要
    planned: 1,         # お返し予定
    completed: 2        # お返し完了
  }

  # コールバック（データ整合性の自動保証）
  before_validation :sync_return_gift_flag
  before_validation :set_return_deadline

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
  validates :memo, length: { maximum: 100 }

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
    when images.attached? && images.any?
      :use_first_image_resized
    when item_name.present?
      :generate_dynamic_text_image
    else
      :use_default_image
    end
  end

  # OGP画像URLの取得（S3保存を含む）
  def ogp_image_url(request)
    helpers = Rails.application.routes.url_helpers
    host = request.host_with_port
    # Always prefer HTTPS in production to satisfy social scrapers
    protocol = Rails.env.production? ? "https" : (request.ssl? ? "https" : "http")
    case ogp_strategy
    when :use_suitable_uploaded_image
      # アップロード済みでOGPに適した画像を使用
      helpers.rails_blob_url(suitable_ogp_images.first, host:, protocol:)
    when :use_first_image_resized
      # 最初の画像をOGPサイズにリサイズ
      variant = ogp_resized_image
      return default_ogp_fallback_url(request) unless variant
      helpers.rails_representation_url(variant.processed, host:, protocol:)
    when :generate_dynamic_text_image
      # 動的にテキスト画像を生成しS3に保存
      ensure_generated_ogp!
      if ogp_image.attached?
        helpers.rails_blob_url(ogp_image, host:, protocol:)
      else
        default_ogp_fallback_url(request)
      end
    when :use_default_image
      # デフォルト画像を使用
      default_ogp_fallback_url(request)
    end
  end

  # OGP用リサイズ画像
  def ogp_resized_image
    return nil unless images.attached? && images.any?

    images.first.variant(
      resize_to_fill: [ 1200, 630 ],
      format: :png,
      background: "white",
      gravity: "center"
    )
  end

  # OGPに適した画像の抽出
  def suitable_ogp_images
    @suitable_ogp_images ||= images.select { |img| image_suitable_for_ogp?(img) }
  end

  # 生成OGPの作成と添付（S3へ）
  def ensure_generated_ogp!
    return if ogp_image.attached?

    text = item_name.presence || "ギフト記録"
    image = OgpCreator.build(text)
    io = StringIO.new(image.to_blob)
    ogp_image.attach(
      io: io,
      filename: "ogp_#{id}.png",
      content_type: "image/png"
    )
  rescue => e
    Rails.logger.error "OGP生成/添付エラー: #{e.message}"
  end

  def default_ogp_fallback_url(request)
    # app/assets/images/ogp.png を指すURL
    path = ActionController::Base.helpers.image_path("ogp.png")
    "#{request.base_url}#{path}"
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

    # 未来1年以内の妥当性チェック（ギフトの予定日も考慮）
    if date > 1.year.from_now
      errors.add(:gift_at, "は1年以内の日付を入力してください")
    end
  end

  def event_exists_and_valid
    return unless event_id.present?

    # 選択されたイベントが存在するかチェック
    unless Event.exists?(event_id)
      errors.add(:event_id, "選択されたイベントは存在しません")
      return
    end

    # イベントが有効な状態かチェック（将来の拡張用）
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
        errors.add(:images, "#{index + 1}枚目: JPEG、PNG、WEBP形式のファイルのみアップロードできます")
      end

      # ファイルサイズチェック（3MBまで）
      if image.blob.byte_size > 3.megabytes
        errors.add(:images, "#{index + 1}枚目: ファイルサイズは3MB以下にしてください")
      end
    end
  rescue StandardError => e
    Rails.logger.error "Images validation error: #{e.message}"
    errors.add(:images, "画像の検証中にエラーが発生しました")
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

  public

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
    images.attached? && images.any?
  end

  def images_count
    images.attached? ? images.count : 0
  end

  def comments_allowed?
    commentable?
  end

  # OGPに適した画像かどうかの判定
  def image_suitable_for_ogp?(image)
    return false unless image.attached?

    begin
      metadata = image.metadata
      width = metadata["width"]
      height = metadata["height"]

      # If analysis is disabled or metadata missing, fallback to MiniMagick to inspect dimensions
      if width.blank? || height.blank?
        mini = MiniMagick::Image.read(image.download)
        width = mini.width
        height = mini.height
      end
      return false unless width && height

      # アスペクト比チェック（1.91:1 = 1200x630に近い）
      aspect_ratio = width.to_f / height.to_f
      suitable_ratio = (1.7..2.1).include?(aspect_ratio)

      # サイズチェック（最小サイズ）
      suitable_size = width >= 600 && height >= 315

      suitable_ratio && suitable_size
    rescue => e
      Rails.logger.error "OGP画像適性チェックエラー: #{e.message}"
      false
    end
  end
end
