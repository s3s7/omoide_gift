class GiftPerson < ApplicationRecord
  belongs_to :user
  belongs_to :relationship
  has_many :gift_records, foreign_key: "gift_people_id", dependent: :destroy
  has_many :reminds, dependent: :destroy
  has_one_attached :avatar

  validates :name, presence: true, length: { minimum: 1 }
  validates :name, format: { with: /\A\S+.*\S*\z/, message: "空白のみは無効です" }
  validates :address, length: { maximum: 100 }, allow_blank: true
  validate :avatar_validation

  # 指定された日付時点での年齢を計算
  def age_at(reference_date = Date.current)
    return nil unless birthday.present?

    reference_date = reference_date.to_date
    birthday_date = birthday.to_date

    # 誕生日が参照日より未来の場合は0歳とする
    return 0 if birthday_date > reference_date

    # 基本的な年齢計算
    age = reference_date.year - birthday_date.year

    # その年の誕生日がまだ来ていない場合は1歳減らす
    if reference_date.month < birthday_date.month ||
      (reference_date.month == birthday_date.month && reference_date.day < birthday_date.day)
      age -= 1
    end

    age
  end

  # 指定された日付時点での年齢を日本語形式で表示
  def display_age_at(reference_date = Date.current)
    age = age_at(reference_date)
    return nil unless age

    case age
    when 0
      "0歳"
    else
      "#{age}歳"
    end
  end

  # ギフト相手のプロフィール画像関連メソッド
  def avatar_url
    return unless avatar.attached? && persisted?
    begin
      avatar
    rescue ActiveRecord::RecordNotFound, NoMethodError => e
      Rails.logger.warn "Gift person avatar URL generation failed: #{e.message}"
      nil
    end
  end

  def has_avatar?
    avatar.attached?
  end

  def display_avatar(size = :medium)
    return unless avatar.attached? && persisted?

    # Active Storageのvariantは保存済みレコードのみで動作するため、
    # レコードが新しい場合や適切にアタッチされていない場合はnilを返す
    begin
      case size
      when :small
        avatar.variant(resize_to_fill: [ 40, 40 ])
      when :medium
        avatar.variant(resize_to_fill: [ 80, 80 ])
      when :large
        avatar.variant(resize_to_fill: [ 160, 160 ])
      else
        avatar
      end
    rescue ActiveRecord::RecordNotFound, NoMethodError => e
      Rails.logger.warn "Gift person avatar variant generation failed: #{e.message}"
      nil
    end
  end

  private

  # ギフト相手のプロフィール画像のバリデーション
  def avatar_validation
    return unless avatar.attached?

    # ファイル形式チェック
    unless avatar.content_type.in?(%w[image/jpeg image/jpg image/png image/webp])
      errors.add(:avatar, "はJPEG、PNG、WEBP形式のファイルのみアップロードできます")
    end

    # ファイルサイズチェック（5MBまで）
    if avatar.blob.byte_size > 5.megabytes
      errors.add(:avatar, "のファイルサイズは5MB以下にしてください")
    end
  rescue StandardError => e
    Rails.logger.error "Gift person avatar validation error: #{e.message}"
    errors.add(:avatar, "の検証中にエラーが発生しました")
  end
end
