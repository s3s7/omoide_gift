require 'rails_helper'

RSpec.describe GiftPerson, type: :model do
  describe 'アソシエーション' do
    it 'userに属すること' do
      expect(GiftPerson.reflect_on_association(:user).macro).to eq(:belongs_to)
    end

    it 'relationshipに属すること' do
      expect(GiftPerson.reflect_on_association(:relationship).macro).to eq(:belongs_to)
    end

    it 'gift_recordsを持つこと' do
      expect(GiftPerson.reflect_on_association(:gift_records).macro).to eq(:has_many)
    end

    it 'remindsを持つこと' do
      expect(GiftPerson.reflect_on_association(:reminds).macro).to eq(:has_many)
    end
  end

  describe 'バリデーション' do
    let(:gift_person) { build(:gift_person) }

    context '名前' do
      it '名前があると有効であること' do
        expect(gift_person).to be_valid
      end

      it '名前が空だと無効であること' do
        gift_person.name = ''
        expect(gift_person).not_to be_valid
        expect(gift_person.errors[:name]).to include('を入力してください')
      end

      it '名前が空白のみだと無効であること' do
        gift_person.name = '   '
        expect(gift_person).not_to be_valid
        expect(gift_person.errors[:name]).to include('空白のみは無効です')
      end
    end
  end

  describe '年齢計算' do
    let(:user) { create(:user) }
    let(:relationship) { create(:relationship) }
    let(:gift_person) do
      create(:gift_person,
        user: user,
        relationship: relationship,
        name: 'テストユーザー',
        birthday: Date.new(1990, 6, 15)
      )
    end

    describe '#age_at' do
      context '誕生日が設定されている場合' do
        it '正しい年齢を計算すること' do
          reference_date = Date.new(2024, 6, 16)
          expect(gift_person.age_at(reference_date)).to eq(34)
        end

        it '誕生日前は1歳若く計算されること' do
          reference_date = Date.new(2024, 6, 14)
          expect(gift_person.age_at(reference_date)).to eq(33)
        end

        it '誕生日当日は正しく計算されること' do
          reference_date = Date.new(2024, 6, 15)
          expect(gift_person.age_at(reference_date)).to eq(34)
        end

        it '誕生日が未来の場合は0歳を返すこと' do
          future_birthday = Date.current + 1.year
          gift_person.update(birthday: future_birthday)
          expect(gift_person.age_at(Date.current)).to eq(0)
        end
      end

      context '誕生日が設定されていない場合' do
        before { gift_person.update(birthday: nil) }

        it 'nilを返すこと' do
          expect(gift_person.age_at(Date.current)).to be_nil
        end
      end
    end

    describe '#display_age_at' do
      it '年齢を日本語形式で表示すること' do
        reference_date = Date.new(2024, 6, 16)
        expect(gift_person.display_age_at(reference_date)).to eq('34歳')
      end

      it '0歳の場合は「0歳」を表示すること' do
        future_birthday = Date.current + 1.year
        gift_person.update(birthday: future_birthday)
        expect(gift_person.display_age_at(Date.current)).to eq('0歳')
      end

      it '誕生日がnilの場合はnilを返すこと' do
        gift_person.update(birthday: nil)
        expect(gift_person.display_age_at(Date.current)).to be_nil
      end
    end
  end
end
