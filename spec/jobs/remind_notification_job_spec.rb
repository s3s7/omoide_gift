require 'rails_helper'

RSpec.describe RemindNotificationJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user, :line_user) }
  let(:gift_person) { create(:gift_person, user: user) }

  it '通知すべきリマインドならLineNotificationServiceを呼び出す' do
    remind = create(:remind,
                    user: user,
                    gift_person: gift_person)

    service = instance_double(LineNotificationService)
    allow(LineNotificationService).to receive(:new).and_return(service)
    expect(service).to receive(:send_reminder_notification).with(remind)

    travel_to(remind.notification_sent_at + 1.minute) do
      described_class.perform_now(remind.id)
    end
  end

  it 'リマインドが見つからない場合は何もしない' do
    expect(LineNotificationService).not_to receive(:new)
    described_class.perform_now(-1)
  end

  it 'should_notify?がfalseなら何もしない' do
    remind = create(:remind,
                    user: user,
                    gift_person: gift_person)

    expect(LineNotificationService).not_to receive(:new)
    described_class.perform_now(remind.id)
  end
end
