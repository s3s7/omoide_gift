require 'rails_helper'

RSpec.describe GiftRecord, type: :model do
  let(:user) { create(:user) }
  let(:event) { create(:event) }
  let(:gift_person) { create(:gift_person, user: user) }

  describe 'バリデーション' do
    subject { build(:gift_record, user: user, event: event, gift_person: gift_person) }

    it '有効なファクトリーデータでは成功する' do
      expect(subject).to be_valid
    end

    describe '必須フィールド' do
      it 'item_nameが必須である' do
        subject.item_name = nil
        expect(subject).to be_invalid
        expect(subject.errors[:item_name]).to include('を入力してください')
      end

      it 'gift_atが必須である' do
        subject.gift_at = nil
        expect(subject).to be_invalid
        expect(subject.errors[:gift_at]).to include('を選択してください')
      end

      it 'event_idが必須である' do
        subject.event_id = nil
        expect(subject).to be_invalid
        expect(subject.errors[:event_id]).to include('を選択してください')
      end

      it 'gift_people_idが必須である' do
        subject.gift_people_id = nil
        expect(subject).to be_invalid
        expect(subject.errors[:gift_people_id]).to include('を選択してください')
      end
    end

    describe '文字数制限' do
      it 'item_nameは30文字以下である' do
        subject.item_name = 'a' * 31
        expect(subject).to be_invalid
      end

      it 'memoは300文字以下である' do
        subject.memo = 'a' * 301
        expect(subject).to be_invalid
      end
    end

    describe '数値バリデーション' do
      it 'amountが正の数である' do
        subject.amount = -100
        expect(subject).to be_invalid
      end

      it 'amountがnilでも有効である' do
        subject.amount = nil
        expect(subject).to be_valid
      end
    end
  end

  describe '関連性' do
    let(:gift_record) { create(:gift_record) }

    it 'userに属している' do
      expect(gift_record.user).to be_present
    end

    it 'eventに属している' do
      expect(gift_record.event).to be_present
    end

    it 'gift_personに属している' do
      expect(gift_record.gift_person).to be_present
    end
  end

  describe 'インスタンスメソッド' do
    let(:gift_record) { create(:gift_record, amount: 1500) }

    describe '#display_amount' do
      it 'amountが設定されている場合、フォーマットされた金額を返す' do
        expect(gift_record.display_amount).to eq('¥1,500')
      end

      it 'amountがnilの場合、"未設定"を返す' do
        gift_record.amount = nil
        expect(gift_record.display_amount).to eq('未設定')
      end
    end

    describe '#display_gift_date' do
      it 'gift_atが設定されている場合、フォーマットされた日付を返す' do
        gift_record.gift_at = Date.new(2024, 12, 25)
        expect(gift_record.display_gift_date).to eq('12/25')
      end
    end

    describe '#display_item_name' do
      it 'item_nameが設定されている場合、その値を返す' do
        expect(gift_record.display_item_name).to eq(gift_record.item_name)
      end

      it 'item_nameが空の場合、"未設定"を返す' do
        gift_record.item_name = ''
        expect(gift_record.display_item_name).to eq('未設定')
      end
    end
  end

  describe 'スコープ' do
    let!(:recent_record) { create(:gift_record, created_at: 1.day.ago) }
    let!(:old_record) { create(:gift_record, created_at: 1.week.ago) }

    describe '.recent' do
      it '作成日の降順で並んでいる' do
        records = GiftRecord.recent.where(id: [ recent_record.id, old_record.id ]).to_a
        expect(records).to eq([ recent_record, old_record ])
      end
    end

    describe '.with_amount' do
      let!(:record_with_amount) { create(:gift_record, amount: 1000) }
      let!(:record_without_amount) { create(:gift_record, amount: nil) }

      it 'amountが設定されているレコードのみを返す' do
        records = GiftRecord.with_amount
        expect(records).to include(record_with_amount)
        expect(records).not_to include(record_without_amount)
      end
    end
  end

  describe 'カスタムバリデーション' do
    subject { build(:gift_record, user: user, event: event, gift_person: gift_person) }

    describe 'gift_at_is_reasonable_date' do
      it '100年以上前の日付は無効' do
        subject.gift_at = 101.years.ago
        expect(subject).to be_invalid
        expect(subject.errors[:gift_at]).to include('は100年以内の日付を入力してください')
      end
    end
  end
end
