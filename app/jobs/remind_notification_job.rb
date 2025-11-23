class RemindNotificationJob < ApplicationJob
  queue_as :default

  # 単一の記念日リマインダーを送信
  def perform(remind_id)
    remind = Remind.includes(:user, gift_person: :relationship).find_by(id: remind_id)
    return unless remind
    return unless remind.should_notify?

    LineNotificationService.new.send_reminder_notification(remind)
  rescue StandardError => e
    Rails.logger.error "RemindNotificationJob error: remind_id=#{remind_id} #{e.class}: #{e.message}"
  end
end
