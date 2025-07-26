class Remind < ApplicationRecord
  belongs_to :user
  belongs_to :gift_person

  # バリデーション
  validates :notification_at, presence: true
  validates :notification_at, uniqueness: { scope: [ :user_id, :gift_person_id ],
                                          message: "この相手の記念日は既に登録されています" }
  validate :notification_sent_at_must_be_present
  validate :notification_sent_at_not_in_past, if: :notification_sent_at?
  validate :notification_sent_at_before_or_on_anniversary, if: :notification_sent_at?
  validate :notification_timing_is_valid

  # デフォルト値
  after_initialize :set_defaults

  # スコープ
  scope :unsent, -> { where(is_sent: false) }
  scope :sent, -> { where(is_sent: true) }
  scope :due_today, -> { where(notification_sent_at: ..Time.current, is_sent: false) }
  scope :upcoming, ->(days = 7) { where(notification_sent_at: Time.current.beginning_of_day..(Time.current + days.days).end_of_day, is_sent: false) }

  # 通知日数の選択肢
  def self.notification_days_before_options
    [
      [ "記念日当日", 0 ],
      [ "1日前", 1 ],
      [ "2日前", 2 ],
      [ "3日前", 3 ],
      [ "1週間前", 7 ],
      [ "2週間前", 14 ],
      [ "1ヶ月前", 30 ]
    ]
  end

  # 通知時刻の選択肢
  def self.notification_time_options
    times = []
    (6..23).each do |hour|
      [ 0, 30 ].each do |minute|
        time_str = sprintf("%02d:%02d", hour, minute)
        display_str = sprintf("%d時%s", hour, minute == 0 ? "00分" : "30分")
        times << [ display_str, time_str ]  # labelとvalueを正しい順序に修正
      end
    end
    times
  end

  # 通知が必要かチェック
  def should_notify?
    return false if is_sent?
    return false unless notification_sent_at.present?

    # 通知予定日時が現在時刻以前で、かつ今日中の通知であることをチェック
    Time.current >= notification_sent_at &&
    notification_sent_at.in_time_zone.to_date >= Date.current - 1.day &&
    notification_sent_at.in_time_zone.to_date <= Date.current
  end

  # 通知済みにマーク（notification_sent_atは変更しない）
  def mark_as_sent!
    update!(is_sent: true)
  end

  # 記念日までの日数
  def days_until_notification
    return 0 if notification_at <= Date.current
    (notification_at - Date.current).to_i
  end

  # 通知までの日数
  def days_until_notify
    return 0 unless notification_sent_at.present?
    return 0 if notification_sent_at.in_time_zone.to_date <= Date.current
    (notification_sent_at.in_time_zone.to_date - Date.current).to_i
  end


  # 記念日からの通知日数を取得
  def notification_days_before
    return 0 unless notification_at.present? && notification_sent_at.present?
    (notification_at - notification_sent_at.in_time_zone.to_date).to_i
  end

  # 通知時刻を取得（HH:MM形式）
  def notification_time
    return nil unless notification_sent_at.present?
    notification_sent_at.in_time_zone.strftime("%H:%M")
  end

  # 通知日時を設定（日数と時刻から計算）
  def set_notification_sent_at(days_before, time_str)
    unless notification_at.present?
      errors.add(:notification_at, "記念日を設定してください")
      return false
    end

    unless days_before.present?
      errors.add(:base, "通知日数を選択してください")
      return false
    end

    unless time_str.present?
      errors.add(:base, "通知時刻を選択してください")
      return false
    end

    # 時刻をパース
    hour, minute = time_str.split(":").map(&:to_i)
    unless hour.between?(0, 23) && minute.between?(0, 59)
      errors.add(:base, "通知時刻の形式が無効です")
      return false
    end

    # 通知日を計算（記念日からdays_before日前）
    notification_date = notification_at - days_before.to_i.days

    # 通知日時を設定（タイムゾーンを考慮）
    datetime_str = "#{notification_date} #{hour}:#{minute}"
    self.notification_sent_at = Time.zone.parse(datetime_str)

    true
  rescue StandardError => e
    Rails.logger.error "Error in set_notification_sent_at: #{e.message}"
    errors.add(:base, "通知日時の設定でエラーが発生しました: #{e.message}")
    false
  end

  # 記念日の説明文を生成
  def notification_message
    return "" unless notification_sent_at.present?

    if notification_sent_at.in_time_zone.to_date == notification_at
      "#{gift_person.name}さんの記念日が今日です！\n" \
      "#{notification_at.strftime("%Y年%m月%d日")}\n" \
      "素敵なギフトを贈る準備はできていますか？"
    else
      days_until = (notification_at - notification_sent_at.in_time_zone.to_date).to_i
      "#{gift_person.name}さんの記念日が#{days_until}日後です！\n" \
      "#{notification_at.strftime("%Y年%m月%d日")}\n" \
      "ギフトの準備を始めませんか？"
    end
  end

  private

  def set_defaults
    self.is_sent = false if is_sent.nil?
  end

  # 通知予定日時が過去でないことをチェック
  def notification_sent_at_not_in_past
    return unless notification_sent_at.present?
    return unless notification_sent_at_changed? # 通知時刻が変更された場合のみバリデーション実行

    if notification_sent_at < Time.current
      errors.add(:notification_sent_at, "は現在時刻より後の日時を設定してください")
    end
  end

  # 通知予定日時が記念日以前であることをチェック
  def notification_sent_at_before_or_on_anniversary
    return unless notification_sent_at.present? && notification_at.present?

    if notification_sent_at.in_time_zone.to_date > notification_at
      errors.add(:notification_sent_at, "は記念日以前の日時を設定してください")
    end
  end

  # 通知日時が設定されているかチェック
  def notification_sent_at_must_be_present
    unless notification_sent_at.present?
      errors.add(:notification_sent_at, "通知日時を設定してください")
    end
  end

  # 通知タイミング設定の妥当性をチェック
  def notification_timing_is_valid
    return unless notification_at.present?
    return unless notification_sent_at.present?

    # 通知日数が定義範囲内かチェック
    days_before = notification_days_before
    valid_days = self.class.notification_days_before_options.map(&:last)  # 修正：valueを取得

    unless valid_days.include?(days_before)
      errors.add(:base, "通知日数の設定が無効です")
    end

    # 通知時刻が定義範囲内かチェック（6:00-23:30の範囲）
    time_str = notification_time
    return unless time_str.present?

    hour, minute = time_str.split(":").map(&:to_i)

    unless hour.between?(6, 23) && [ 0, 30 ].include?(minute)
      errors.add(:base, "通知時刻は6:00-23:30の範囲で30分刻みで設定してください")
    end
  rescue StandardError
    errors.add(:base, "通知タイミングの設定に問題があります")
  end
end
