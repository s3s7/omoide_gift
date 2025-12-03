require 'rails_helper'

RSpec.describe EnqueueDueRemindsJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  let(:user) { create(:user, :line_user) }
  let(:gift_person) { create(:gift_person, user: user) }

  it '通知対象の期限到来リマインドだけRemindNotificationJobをキューに積む' do
    due = create(
      :remind,
      user: user,
      gift_person: gift_person,
      notification_offset_minutes: 10,
      is_sent: false
    )
    future_user = create(:user, :line_user)
    future_person = create(:gift_person, user: future_user)
    not_due_future = create(
      :remind,
      user: future_user,
      gift_person: future_person,
      notification_offset_minutes: 120,
      is_sent: false
    )
    sent_user = create(:user, :line_user)
    sent_person = create(:gift_person, user: sent_user)
    already_sent = create(
      :remind,
      user: sent_user,
      gift_person: sent_person,
      notification_offset_minutes: 10,
      is_sent: true
    )

    travel_to(due.notification_sent_at + 1.minute) do
      expect {
        described_class.perform_now
      }.to have_enqueued_job(RemindNotificationJob).with(due.id).exactly(:once)

      enqueued_ids = ActiveJob::Base.queue_adapter.enqueued_jobs.map { |j| j[:args].first }
      expect(enqueued_ids).to include(due.id)
      expect(enqueued_ids).not_to include(not_due_future.id)
      expect(enqueued_ids).not_to include(already_sent.id)
    end
  end
end
