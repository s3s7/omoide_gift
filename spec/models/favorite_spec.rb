require 'rails_helper'

RSpec.describe Favorite, type: :model do
  describe 'associations' do
    it 'userに属すること' do
      expect(Favorite.reflect_on_association(:user).macro).to eq(:belongs_to)
    end

    it 'gift_recordに属すること' do
      expect(Favorite.reflect_on_association(:gift_record).macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    let(:user) { create(:user) }
    let(:gift_record) { create(:gift_record, user: user) }

    context 'ユニーク制約' do
      before { create(:favorite, user: user, gift_record: gift_record) }

      it '同じユーザーが同じギフト記録を重複してお気に入りにできないこと' do
        duplicate_favorite = build(:favorite, user: user, gift_record: gift_record)
        expect(duplicate_favorite).not_to be_valid
        expect(duplicate_favorite.errors[:user_id]).to include('このギフト記録は既にお気に入りに追加されています')
      end
    end

    context 'アクセス権限' do
      let(:other_user) { create(:user) }
      let(:public_gift_record) { create(:gift_record, user: other_user, is_public: true) }
      let(:private_gift_record) { create(:gift_record, user: other_user, is_public: false) }

      it '公開されたギフト記録をお気に入りにできること' do
        favorite = build(:favorite, user: user, gift_record: public_gift_record)
        expect(favorite).to be_valid
      end

      it '自分のギフト記録をお気に入りにできること' do
        own_private_record = create(:gift_record, user: user, is_public: false)
        favorite = build(:favorite, user: user, gift_record: own_private_record)
        expect(favorite).to be_valid
      end

      it '非公開のギフト記録をお気に入りにできないこと' do
        favorite = build(:favorite, user: user, gift_record: private_gift_record)
        expect(favorite).not_to be_valid
        expect(favorite.errors[:gift_record]).to include('非公開のギフト記録はお気に入りに追加できません')
      end
    end
  end

  describe 'クラスメソッド' do
    let(:user) { create(:user) }
    let(:gift_record) { create(:gift_record, user: user) }

    describe '.favorited_by_user?' do
      context 'お気に入りに登録済みの場合' do
        before { create(:favorite, user: user, gift_record: gift_record) }

        it 'trueを返すこと' do
          expect(Favorite.favorited_by_user?(user, gift_record)).to be true
        end
      end

      context 'お気に入りに未登録の場合' do
        it 'falseを返すこと' do
          expect(Favorite.favorited_by_user?(user, gift_record)).to be false
        end
      end
    end

    describe '.toggle_favorite' do
      context 'お気に入りに未登録の場合' do
        it 'お気に入りが追加されること' do
          result = Favorite.toggle_favorite(user, gift_record)
          
          expect(result[:success]).to be true
          expect(result[:action]).to eq(:added)
          expect(result[:favorited]).to be true
          expect(Favorite.favorited_by_user?(user, gift_record)).to be true
        end
      end

      context 'お気に入りに登録済みの場合' do
        before { create(:favorite, user: user, gift_record: gift_record) }

        it 'お気に入りが削除されること' do
          result = Favorite.toggle_favorite(user, gift_record)
          
          expect(result[:success]).to be true
          expect(result[:action]).to eq(:removed)
          expect(result[:favorited]).to be false
          expect(Favorite.favorited_by_user?(user, gift_record)).to be false
        end
      end

      context '無効なパラメータ' do
        it 'userがnilの場合失敗すること' do
          result = Favorite.toggle_favorite(nil, gift_record)
          expect(result[:success]).to be false
          expect(result[:error]).to include('ユーザーが無効')
        end

        it 'gift_recordがnilの場合失敗すること' do
          result = Favorite.toggle_favorite(user, nil)
          expect(result[:success]).to be false
          expect(result[:error]).to include('ギフト記録が無効')
        end
      end
    end

    describe '.favorites_count_for_gift_record' do
      it '指定されたギフト記録のお気に入り数を返すこと' do
        user1 = create(:user)
        user2 = create(:user)
        create(:favorite, user: user1, gift_record: gift_record)
        create(:favorite, user: user2, gift_record: gift_record)

        expect(Favorite.favorites_count_for_gift_record(gift_record)).to eq(2)
      end
    end
  end
end
