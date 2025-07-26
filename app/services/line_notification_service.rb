class LineNotificationService
  include Rails.application.routes.url_helpers

  def initialize
    @client = Line::Bot::Client.new do |config|
      config.channel_id = Rails.application.credentials.line[:channel_id]
      config.channel_secret = Rails.application.credentials.line[:channel_secret]
      config.channel_token = Rails.application.credentials.line[:channel_token]
    end
  end

  # 今日が記念日のリマインダーを一括送信
  def send_due_reminders
    due_reminds = Remind.due_today.includes(:user, gift_person: :relationship)
    Rails.logger.info "Found #{due_reminds.count} due reminders for today"

    results = { success: 0, failed: 0, total: due_reminds.count }

    due_reminds.find_each do |remind|
      Rails.logger.info "Processing remind ID: #{remind.id}, User: #{remind.user.name}, notification_sent_at: #{remind.notification_sent_at}, should_notify?: #{remind.should_notify?}"

      if send_reminder_notification(remind)
        results[:success] += 1
        Rails.logger.info "Successfully sent notification for remind ID: #{remind.id}"
      else
        results[:failed] += 1
        Rails.logger.error "Failed to send notification for remind ID: #{remind.id}"
      end
    end

    Rails.logger.info "Notification results: #{results}"
    results
  end

  # 個別のリマインダー通知を送信
  def send_reminder_notification(remind)
    unless remind.should_notify?
      Rails.logger.info "Remind ID: #{remind.id} should not notify. is_sent: #{remind.is_sent?}, notification_sent_at: #{remind.notification_sent_at}, current_time: #{Time.current}"
      return false
    end

    line_user_id = get_line_user_id(remind.user)
    unless line_user_id
      Rails.logger.error "No LINE user ID found for user ID: #{remind.user_id}, provider: #{remind.user.provider}, uid: #{remind.user.uid}"
      return false
    end

    message = build_reminder_message(remind)
    Rails.logger.info "Sending LINE message to user ID: #{remind.user_id}, LINE ID: #{line_user_id}"

    begin
      response = @client.push_message(line_user_id, message)

      if response.is_a?(Net::HTTPSuccess)
        remind.mark_as_sent!
        Rails.logger.info "LINE message sent successfully for remind ID: #{remind.id}"
        true
      else
        Rails.logger.error "LINE API response error for remind ID: #{remind.id}, response: #{response.inspect}"
        false
      end
    rescue StandardError => e
      Rails.logger.error "Exception sending LINE message for remind ID: #{remind.id}: #{e.message}"
      false
    end
  end

  private

  # ユーザーのLINE User IDを取得
  def get_line_user_id(user)
    return nil unless user.provider == "line" && user.uid.present?
    user.uid
  end

  # リマインダーメッセージを構築
  def build_reminder_message(remind)
    person_name = remind.gift_person.name
    relationship = remind.gift_person.relationship&.name || "大切な人"
    anniversary_date = remind.notification_at.strftime("%Y年%m月%d日")
    notification_date = remind.notification_sent_at.in_time_zone.to_date

    # 記念日当日かどうかで メッセージを分ける
    if notification_date == remind.notification_at
      message_text = "🎉 記念日のお知らせ 🎉\n\n"
      message_text += "#{person_name}さん（#{relationship}）の記念日が今日です！\n"
      message_text += "📅 #{anniversary_date}\n\n"
      message_text += "素敵なギフトの準備はできていますか？\n"
    else
      days_until = (remind.notification_at - notification_date).to_i
      message_text = "🔔 記念日のリマインド 🔔\n\n"
      message_text += "#{person_name}さん（#{relationship}）の記念日が#{days_until}日後です！\n"
      message_text += "📅 #{anniversary_date}\n\n"
      message_text += "ギフトの準備を始めませんか？\n"
    end

    message_text += "ギフト記録アプリで過去のプレゼントも確認できます。"

    {
      type: "text",
      text: message_text
    }
  end
end
