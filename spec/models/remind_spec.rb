require 'rails_helper'

RSpec.describe Remind, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user, :line_user) }
  let(:gift_person) { create(:gift_person, user: user) }

  describe '#should_notify?' do
    it 'returns true when not sent, time passed, and date is today' do
      travel_to(Time.zone.parse('2025-01-10 09:10:00')) do
        remind = create(:remind,
                        user: user,
                        gift_person: gift_person,
                        notification_at: Date.parse('2025-01-10'),
                        notification_sent_at: Time.zone.parse('2025-01-10 09:00:00'),
                        is_sent: false)
        expect(remind.should_notify?).to be true
      end
    end

    it 'returns true when scheduled yesterday and still within date window' do
      travel_to(Time.zone.parse('2025-01-11 08:00:00')) do
        remind = create(:remind,
                        user: user,
                        gift_person: gift_person,
                        notification_at: Date.parse('2025-01-11'),
                        notification_sent_at: Time.zone.parse('2025-01-10 23:30:00'),
                        is_sent: false)
        expect(remind.should_notify?).to be true
      end
    end

    it 'returns false when scheduled in the future' do
      travel_to(Time.zone.parse('2025-01-10 08:00:00')) do
        remind = create(:remind,
                        user: user,
                        gift_person: gift_person,
                        notification_at: Date.parse('2025-01-10'),
                        notification_sent_at: Time.zone.parse('2025-01-10 09:00:00'),
                        is_sent: false)
        expect(remind.should_notify?).to be false
      end
    end

    it 'returns false when already sent' do
      travel_to(Time.zone.parse('2025-01-10 10:00:00')) do
        remind = create(:remind,
                        user: user,
                        gift_person: gift_person,
                        notification_at: Date.parse('2025-01-10'),
                        notification_sent_at: Time.zone.parse('2025-01-10 09:00:00'),
                        is_sent: true)
        expect(remind.should_notify?).to be false
      end
    end

    it 'returns false when notification_sent_at is missing' do
      remind = build(:remind,
                     user: user,
                     gift_person: gift_person,
                     notification_at: Date.current,
                     notification_sent_at: nil,
                     is_sent: false)
      expect(remind.should_notify?).to be false
    end
  end

  describe 'scopes' do
    before { travel_to(Time.zone.parse('2025-01-10 12:00:00')) }
    after { travel_back }

    it '.due_today includes past scheduled and not sent reminders' do
      past_due = create(:remind,
                        user: user,
                        gift_person: gift_person,
                        notification_at: Date.parse('2025-01-10'),
                        notification_sent_at: Time.zone.parse('2025-01-10 08:00:00'),
                        is_sent: false)
      future = create(:remind,
                      user: user,
                      gift_person: gift_person,
                      notification_at: Date.parse('2025-01-10'),
                      notification_sent_at: Time.zone.parse('2025-01-10 18:00:00'),
                      is_sent: false)
      sent = create(:remind,
                    user: user,
                    gift_person: gift_person,
                    notification_at: Date.parse('2025-01-10'),
                    notification_sent_at: Time.zone.parse('2025-01-10 09:00:00'),
                    is_sent: true)

      expect(Remind.due_today).to include(past_due)
      expect(Remind.due_today).not_to include(future)
      expect(Remind.due_today).not_to include(sent)
    end

    it '.upcoming returns reminders within the next N days (default 7), not sent' do
      in_window_today = create(:remind,
                               user: user,
                               gift_person: gift_person,
                               notification_at: Date.parse('2025-01-10'),
                               notification_sent_at: Time.zone.parse('2025-01-10 13:00:00'),
                               is_sent: false)
      in_window_7 = create(:remind,
                           user: user,
                           gift_person: gift_person,
                           notification_at: Date.parse('2025-01-15'),
                           notification_sent_at: Time.zone.parse('2025-01-15 09:00:00'),
                           is_sent: false)
      out_of_window = create(:remind,
                             user: user,
                             gift_person: gift_person,
                             notification_at: Date.parse('2025-01-25'),
                             notification_sent_at: Time.zone.parse('2025-01-25 09:00:00'),
                             is_sent: false)
      sent = create(:remind,
                    user: user,
                    gift_person: gift_person,
                    notification_at: Date.parse('2025-01-11'),
                    notification_sent_at: Time.zone.parse('2025-01-11 09:00:00'),
                    is_sent: true)

      upcoming = Remind.upcoming
      expect(upcoming).to include(in_window_today)
      expect(upcoming).to include(in_window_7)
      expect(upcoming).not_to include(out_of_window)
      expect(upcoming).not_to include(sent)
    end
  end
end

