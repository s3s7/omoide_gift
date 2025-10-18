require 'rails_helper'

RSpec.describe RemindNotificationJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user, :line_user) }
  let(:gift_person) { create(:gift_person, user: user) }

  it 'calls LineNotificationService when remind should notify' do
    remind = create(:remind,
                    user: user,
                    gift_person: gift_person,
                    notification_at: Date.current,
                    notification_sent_at: 1.minute.ago,
                    is_sent: false)

    service = instance_double(LineNotificationService)
    allow(LineNotificationService).to receive(:new).and_return(service)
    expect(service).to receive(:send_reminder_notification).with(remind)

    described_class.perform_now(remind.id)
  end

  it 'does nothing when remind is not found' do
    expect(LineNotificationService).not_to receive(:new)
    described_class.perform_now(-1)
  end

  it 'does nothing when should_notify? is false' do
    remind = create(:remind,
                    user: user,
                    gift_person: gift_person,
                    notification_at: Date.current,
                    notification_sent_at: 1.hour.from_now,
                    is_sent: false)

    expect(LineNotificationService).not_to receive(:new)
    described_class.perform_now(remind.id)
  end
end
