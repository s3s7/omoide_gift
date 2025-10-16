require 'rails_helper'

RSpec.describe EnqueueDueRemindsJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  let(:user) { create(:user, :line_user) }
  let(:gift_person) { create(:gift_person, user: user) }

  it 'enqueues RemindNotificationJob only for due reminders that should notify' do
    due = create(
      :remind,
      user: user,
      gift_person: gift_person,
      notification_at: Date.current,
      notification_sent_at: 1.minute.ago,
      is_sent: false
    )
    not_due_future = create(
      :remind,
      user: user,
      gift_person: gift_person,
      notification_at: Date.current,
      notification_sent_at: 1.hour.from_now,
      is_sent: false
    )
    already_sent = create(
      :remind,
      user: user,
      gift_person: gift_person,
      notification_at: Date.current,
      notification_sent_at: 5.minutes.ago,
      is_sent: true
    )

    expect {
      described_class.perform_now
    }.to have_enqueued_job(RemindNotificationJob).with(due.id).exactly(:once)

    # Ensure nothing else enqueued
    enqueued_ids = ActiveJob::Base.queue_adapter.enqueued_jobs.map { |j| j[:args].first }
    expect(enqueued_ids).to include(due.id)
    expect(enqueued_ids).not_to include(not_due_future.id)
    expect(enqueued_ids).not_to include(already_sent.id)
  end
end

