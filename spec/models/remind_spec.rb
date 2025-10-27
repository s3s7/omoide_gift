require 'rails_helper'

RSpec.describe Remind, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user, :line_user) }
  let(:gift_person) { create(:gift_person, user: user) }

  describe '#should_notify?' do
    it '未送信で時刻が過ぎ本日分ならtrueを返す' do
      remind = nil
      travel_to(Time.zone.parse('2025-01-10 08:30:00')) do
        remind = create(:remind,
                        user: user,
                        gift_person: gift_person,
                        notification_at: Date.parse('2025-01-10'),
                        notification_sent_at: Time.zone.parse('2025-01-10 09:00:00'),
                        is_sent: false)
      end

      travel_to(Time.zone.parse('2025-01-10 09:10:00')) do
        expect(remind.reload.should_notify?).to be true
      end
    end

    it '前日に送信予定でも日付範囲内ならtrueを返す' do
      remind = nil
      travel_to(Time.zone.parse('2025-01-10 12:00:00')) do
        remind = create(:remind,
                        user: user,
                        gift_person: gift_person,
                        notification_at: Date.parse('2025-01-11'),
                        notification_sent_at: Time.zone.parse('2025-01-10 23:30:00'),
                        is_sent: false)
      end

      travel_to(Time.zone.parse('2025-01-11 08:00:00')) do
        expect(remind.reload.should_notify?).to be true
      end
    end

    it '未来の送信予定ならfalseを返す' do
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

    it '既に送信済みならfalseを返す' do
      remind = nil
      travel_to(Time.zone.parse('2025-01-10 08:30:00')) do
        remind = create(:remind,
                        user: user,
                        gift_person: gift_person,
                        notification_at: Date.parse('2025-01-10'),
                        notification_sent_at: Time.zone.parse('2025-01-10 09:00:00'),
                        is_sent: true)
      end

      travel_to(Time.zone.parse('2025-01-10 10:00:00')) do
        expect(remind.reload.should_notify?).to be false
      end
    end

    it 'notification_sent_atが無い場合はfalseを返す' do
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
    it '.due_todayは過去時刻で未送信のリマインドを含む' do
      past_person = create(:gift_person, user: user)
      future_person = create(:gift_person, user: user)
      sent_person = create(:gift_person, user: user)

      past_due = travel_to(Time.zone.parse('2025-01-10 07:00:00')) do
        create(:remind,
               user: user,
               gift_person: past_person,
               notification_at: Date.parse('2025-01-10'),
               notification_sent_at: Time.zone.parse('2025-01-10 08:00:00'),
               is_sent: false)
      end
      future = travel_to(Time.zone.parse('2025-01-10 12:00:00')) do
        create(:remind,
               user: user,
               gift_person: future_person,
               notification_at: Date.parse('2025-01-10'),
               notification_sent_at: Time.zone.parse('2025-01-10 18:00:00'),
               is_sent: false)
      end
      sent = travel_to(Time.zone.parse('2025-01-10 08:30:00')) do
        create(:remind,
               user: user,
               gift_person: sent_person,
               notification_at: Date.parse('2025-01-10'),
               notification_sent_at: Time.zone.parse('2025-01-10 09:00:00'),
               is_sent: true)
      end

      travel_to(Time.zone.parse('2025-01-10 12:00:00')) do
        expect(Remind.due_today).to include(past_due)
        expect(Remind.due_today).not_to include(future)
        expect(Remind.due_today).not_to include(sent)
      end
    end

    it '.upcomingは未送信で今後N日以内(初期値7日)のリマインドを返す' do
      today_person = create(:gift_person, user: user)
      window_person = create(:gift_person, user: user)
      out_person = create(:gift_person, user: user)
      sent_person = create(:gift_person, user: user)

      in_window_today = travel_to(Time.zone.parse('2025-01-10 12:00:00')) do
        create(:remind,
               user: user,
               gift_person: today_person,
               notification_at: Date.parse('2025-01-10'),
               notification_sent_at: Time.zone.parse('2025-01-10 13:00:00'),
               is_sent: false)
      end
      in_window_7 = travel_to(Time.zone.parse('2025-01-14 09:00:00')) do
        create(:remind,
               user: user,
               gift_person: window_person,
               notification_at: Date.parse('2025-01-15'),
               notification_sent_at: Time.zone.parse('2025-01-15 09:00:00'),
               is_sent: false)
      end
      out_of_window = travel_to(Time.zone.parse('2025-01-24 09:00:00')) do
        create(:remind,
               user: user,
               gift_person: out_person,
               notification_at: Date.parse('2025-01-25'),
               notification_sent_at: Time.zone.parse('2025-01-25 09:00:00'),
               is_sent: false)
      end
      sent = travel_to(Time.zone.parse('2025-01-10 08:30:00')) do
        create(:remind,
               user: user,
               gift_person: sent_person,
               notification_at: Date.parse('2025-01-11'),
               notification_sent_at: Time.zone.parse('2025-01-11 09:00:00'),
               is_sent: true)
      end

      travel_to(Time.zone.parse('2025-01-10 12:00:00')) do
        upcoming = Remind.upcoming
        expect(upcoming).to include(in_window_today)
        expect(upcoming).to include(in_window_7)
        expect(upcoming).not_to include(out_of_window)
        expect(upcoming).not_to include(sent)
      end
    end
  end
end
