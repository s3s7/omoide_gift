class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
        :recoverable, :rememberable, :validatable,
        :omniauthable, omniauth_providers: %i[line]

  has_many :gift_records, dependent: :destroy
  has_many :gift_people, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :reminds, dependent: :destroy

  # バリデーション
  validates :name, presence: true, length: { maximum: 20 }

  # セキュリティを考慮したエラーメッセージの置き換え
  after_validation :customize_validation_errors

  # LINEログインユーザーの場合はemailを必須にしない
  def email_required?
    provider.blank?
  end
  def email_changed?
    provider.blank? && super
  end

  # ユーザー統計情報メソッド
  def total_gift_records
    gift_records.count
  end

  def total_gift_amount
    gift_records.sum(:amount) || 0
  end

  def total_gift_people
    gift_people.where.not(name: [ nil, "" ]).count
  end

  def recent_gift_records(limit = 5)
    gift_records.includes(:gift_person, :event).order(gift_at: :desc).limit(limit)
  end

  def monthly_gift_summary(date = Date.current)
    gift_records
      .where(gift_at: date.beginning_of_month..date.end_of_month)
      .group(:gift_people_id)
      .joins(:gift_person)
      .count
  end

  def current_year_stats
    current_year_records = gift_records.where(
      gift_at: Date.current.beginning_of_year..Date.current.end_of_year
    )
    {
      count: current_year_records.count,
      amount: current_year_records.sum(:amount) || 0,
      people_count: current_year_records.distinct.count(:gift_people_id)
    }
  end

  def display_name
    name.present? ? name : email.split("@").first
  end

  def display_email
    email.present? ? email : "メールアドレス登録なし"
  end

  # LINE連携状態を判定
  def line_connected?
    provider == "line" && uid.present?
  end

  # LINE連携状態の表示用テキスト
  def line_connection_status
    line_connected? ? "連携済み" : "未連携"
  end

  # LINE連携状態の表示用クラス（CSS用）
  def line_connection_status_class
    line_connected? ? "text-green-600" : "text-gray-500"
  end

  # fake emailかどうかを判定
  def fake_email?
    email.present? && email.end_with?("@example.com")
  end

  def public_gift_records_count
    gift_records.where(is_public: true).count
  end

  def private_gift_records_count
    gift_records.where(is_public: false).count
  end

  # Lineログイン用
  def social_profile(provider)
    social_profiles.select { |sp| sp.provider == provider.to_s }.first
  end

  # Lineログイン用
  def set_values(omniauth)
    return if provider.to_s != omniauth["provider"].to_s || uid != omniauth["uid"]
    credentials = omniauth["credentials"]
    info = omniauth["info"]

    access_token = credentials["refresh_token"]
    access_secret = credentials["secret"]
    credentials = credentials.to_json
    name = info["name"]
  end

  # Lineログイン用
  def set_values_by_raw_info(raw_info)
    self.raw_info = raw_info.to_json
    self.save!
  end

  private

  # バリデーションエラーメッセージのカスタマイズ
  def customize_validation_errors
    # emailエラーのカスタマイズ（セキュリティ考慮）
    if errors[:email].any?
      errors.delete(:email)
      errors.add(:base, "登録できませんでした。入力内容をご確認ください")
    end

    # パスワード確認エラーの日本語化
    if errors[:password_confirmation].any?
      errors.delete(:password_confirmation)
      errors.add(:password_confirmation, "とパスワードの入力が一致しません")
    end
  end
end
