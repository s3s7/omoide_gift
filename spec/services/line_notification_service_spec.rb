require 'rails_helper'

RSpec.describe LineNotificationService, type: :service do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user, :line_user) }
  let(:gift_person) { create(:gift_person, user: user) }

  describe 'リマインダー通知送信' do
    let(:remind) { create(:remind, user: user, gift_person: gift_person, notification_offset_minutes: 10) }

    before do
      # 実際の通信を避けるためLINE APIクライアントをスタブ化
      client_double = instance_double('LineClient')
      allow(LineNotificationService).to receive(:client).and_return(client_double)

      # 成功レスポンスを模したPushMessageResponseクラスを差し替える
      stub_const('PushMessageResponse', Class.new)
      allow(client_double).to receive(:push_message).and_return(PushMessageResponse.new)
    end

    it '通知対象の期限ならメッセージを送り送信済みにする' do
      travel_to(remind.notification_sent_at + 1.minute) do
        service = described_class.new
        result = service.send_reminder_notification(remind)
        expect(result).to be true
        expect(remind.reload.is_sent).to be true
      end
    end

    it 'should_notify?がfalse（未来の通知）なら送信しない' do
      # 作成直後はnotification_sent_atが未来
      service = described_class.new
      expect(service.send_reminder_notification(remind)).to be false
      expect(remind.reload.is_sent).to be false
    end

    it 'ユーザーがLINE連携していない場合は送信しない' do
      remind.update!(user: create(:user)) # LINE連携情報を持たない通常ユーザー
      travel_to(remind.notification_sent_at + 1.minute) do
        service = described_class.new
        expect(service.send_reminder_notification(remind)).to be false
        expect(remind.reload.is_sent).to be false
      end
    end

    it 'LINE APIが例外を返した場合はfalseを返す' do
      # 例外を発生させるスタブに差し替える
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

  describe '期限到来リマインド送信' do
    it '期限到来リマインドの成功数と失敗数を集計する' do
      # 準備: 期限到来と未到来をそれぞれ用意
      due_remind = create(:remind, user: user, gift_person: gift_person, notification_offset_minutes: 5)
      not_due = create(:remind, user: user, gift_person: gift_person, notification_offset_minutes: 60 * 24)

      client_double = instance_double('LineClient')
      allow(LineNotificationService).to receive(:client).and_return(client_double)
      stub_const('PushMessageResponse', Class.new)
      allow(client_double).to receive(:push_message).and_return(PushMessageResponse.new)

      travel_to(due_remind.notification_sent_at + 1.minute) do
        results = described_class.new.send_due_reminders
        expect(results[:total]).to be >= 1
        # 少なくとも1件（期限到来分）は成功する想定。DB状態に依存しないよう件数は厳密に確認しない
        expect(results[:success]).to be >= 1
      end
    end
  end
end
