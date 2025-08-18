class GiftRecord < ApplicationRecord
  # リレーション
  belongs_to :user
  belongs_to :event
  belongs_to :gift_person, foreign_key: "gift_people_id"
  has_many :favorites, dependent: :destroy
  belongs_to :gift_item_category, optional: true
  
  # Active Storage - 複数画像対応
  has_many_attached :images

  # 必須フィールドのバリデーション（統一されたエラーメッセージ）
  validates :item_name, presence: { message: "を入力してください" }, length: { maximum: 30 }
  validates :gift_at, presence: { message: "を選択してください" }
  validates :event_id, presence: { message: "を選択してください" }
  validates :gift_people_id, presence: { message: "を選択してください" }

  # オプションフィールドのバリデーション
  validates :amount, numericality: { greater_than: 0, allow_nil: true }
  validates :memo, length: { maximum: 100 }

  # カスタムバリデーション
  validate :gift_at_is_valid_date
  validate :gift_at_is_reasonable_date
  validate :images_validation

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

      # ファイルサイズチェック（10MBまで）
      if image.blob.byte_size > 10.megabytes
        errors.add(:images, "#{index + 1}枚目: ファイルサイズは10MB以下にしてください")
      end
    end
  rescue StandardError => e
    Rails.logger.error "Images validation error: #{e.message}"
    errors.add(:images, "画像の検証中にエラーが発生しました")
  end

  public

  # スコープ（クエリの再利用性と可読性向上）
  scope :recent, -> { order(created_at: :desc) }
  scope :by_date_range, ->(from, to) { where(gift_at: from..to) }
  scope :by_gift_person, ->(gift_person_id) { where(gift_people_id: gift_person_id) }
  scope :with_amount, -> { where.not(amount: nil) }
  scope :current_month, -> { where(gift_at: Date.current.beginning_of_month..Date.current.end_of_month) }
  scope :current_year, -> { where(gift_at: Date.current.beginning_of_year..Date.current.end_of_year) }

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
end
