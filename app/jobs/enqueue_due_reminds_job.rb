class EnqueueDueRemindsJob < ApplicationJob
  queue_as :default

  # 毎分の定期実行で、送信対象の記念日リマインダーをキューに投入する
  def perform
    due_reminds = Remind.due_today.includes(:user, gift_person: :relationship)
    Rails.logger.info "EnqueueDueRemindsJob: found #{due_reminds.count} reminders due"

    due_reminds.find_each do |remind|
      next unless remind.should_notify?
      RemindNotificationJob.perform_later(remind.id)
    end
  rescue StandardError => e
    Rails.logger.error "EnqueueDueRemindsJob error: #{e.class}: #{e.message}"
  end
end

