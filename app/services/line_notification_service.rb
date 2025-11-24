require "line-bot-api"

class LineNotificationService
  include Rails.application.routes.url_helpers

  def self.client
    @client ||= Line::Bot::V2::MessagingApi::ApiClient.new(
      channel_access_token: ENV["LINE_CHANNEL_ACCESS_TOKEN"]
    )
  end

  def initialize
    @client = self.class.client
  end

  # 今日が記念日のリマインダーを一括送信
  def send_due_reminders
    due_reminds = Remind.due_today.includes(:user, gift_person: :relationship)

    results = { success: 0, failed: 0, total: due_reminds.count }

    due_reminds.find_each do |remind|
      if send_reminder_notification(remind)
        results[:success] += 1
      else
        results[:failed] += 1
        Rails.logger.error "Failed to send notification for remind ID: #{remind.id}"
      end
    end
    results
  end

  # 個別のリマインダー通知を送信
  def send_reminder_notification(remind)
    unless remind.should_notify?
      return false
    end

    line_user_id = get_line_user_id(remind.user)
    unless line_user_id
      Rails.logger.error "No LINE user ID found for user ID: #{remind.user_id}, provider: #{remind.user.provider}, uid: #{remind.user.uid}"
      return false
    end

    message = build_reminder_message(remind)

    begin
      push_request = Line::Bot::V2::MessagingApi::PushMessageRequest.new(
        to: line_user_id,
        messages: [ message ]
      )

      response = @client.push_message(push_message_request: push_request)

      if response.is_a?(Net::HTTPSuccess) || response.class.name.include?("PushMessageResponse")
        remind.mark_as_sent!
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

    Line::Bot::V2::MessagingApi::TextMessage.new(
      text: message_text
    )
  end
end
