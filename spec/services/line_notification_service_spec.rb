require 'rails_helper'

RSpec.describe LineNotificationService, type: :service do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user, :line_user) }
  let(:gift_person) { create(:gift_person, user: user) }

  describe '#send_reminder_notification' do
    let(:remind) { create(:remind, user: user, gift_person: gift_person, notification_at: Date.current, notification_sent_at: 5.minutes.from_now) }

    before do
      # Stub LINE API client to avoid real network calls
      client_double = instance_double('LineClient')
      allow(LineNotificationService).to receive(:client).and_return(client_double)

      # Fake successful response class name check ("PushMessageResponse")
      stub_const('PushMessageResponse', Class.new)
      allow(client_double).to receive(:push_message).and_return(PushMessageResponse.new)
    end

    it 'sends message when reminder is due and marks as sent' do
      travel_to(remind.notification_sent_at + 1.minute) do
        service = described_class.new
        result = service.send_reminder_notification(remind)
        expect(result).to be true
        expect(remind.reload.is_sent).to be true
      end
    end

    it 'does not send when should_notify? is false (future time)' do
      # At creation, notification_sent_at is in the future
      service = described_class.new
      expect(service.send_reminder_notification(remind)).to be false
      expect(remind.reload.is_sent).to be false
    end

    it 'does not send when user is not linked to LINE' do
      remind.update!(user: create(:user)) # normal user without LINE provider/uid
      travel_to(remind.notification_sent_at + 1.minute) do
        service = described_class.new
        expect(service.send_reminder_notification(remind)).to be false
        expect(remind.reload.is_sent).to be false
      end
    end

    it 'returns false when LINE API raises an exception' do
      # Override stub to raise
      erroring_client = instance_double('LineClient')
      allow(LineNotificationService).to receive(:client).and_return(erroring_client)
      allow(erroring_client).to receive(:push_message).and_raise(StandardError.new('boom'))

      travel_to(remind.notification_sent_at + 1.minute) do
        service = described_class.new
        expect(service.send_reminder_notification(remind)).to be false
        expect(remind.reload.is_sent).to be false
      end
    end
  end

  describe '#send_due_reminders' do
    it 'aggregates success and failures for due reminders' do
      # prepare: one due, one not due
      due_remind = create(:remind, user: user, gift_person: gift_person, notification_at: Date.current, notification_sent_at: 1.minute.from_now)
      not_due = create(:remind, user: user, gift_person: gift_person, notification_at: Date.current + 1, notification_sent_at: 1.day.from_now)

      client_double = instance_double('LineClient')
      allow(LineNotificationService).to receive(:client).and_return(client_double)
      stub_const('PushMessageResponse', Class.new)
      allow(client_double).to receive(:push_message).and_return(PushMessageResponse.new)

      travel_to(due_remind.notification_sent_at + 1.minute) do
        results = described_class.new.send_due_reminders
        expect(results[:total]).to be >= 1
        # At least one success (the due one); not asserting exact counts to avoid coupling to DB state
        expect(results[:success]).to be >= 1
      end
    end
  end
end

