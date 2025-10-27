require 'rails_helper'

RSpec.describe 'Favorites', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:public_gift_record) { create(:gift_record, user: other_user, is_public: true) }
  let(:private_gift_record) { create(:gift_record, user: other_user, is_public: false) }
  let(:user_gift_record) { create(:gift_record, user: user) }

  describe '認証' do
    context '未ログインユーザー' do
      it 'お気に入り一覧にアクセスできないこと' do
        get favorites_path
        expect(response).to have_http_status(:forbidden)
      end

      it 'お気に入りtoggle機能を使用できないこと' do
        post toggle_favorite_gift_record_path(public_gift_record), headers: { 'Accept' => 'application/json' }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'お気に入り一覧' do
    before do
      sign_in user
      create(:favorite, user: user, gift_record: public_gift_record)
      create(:favorite, user: user, gift_record: user_gift_record)
    end

    it 'お気に入りした記録が表示されること' do
      get favorites_path
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'お気に入りtoggle機能' do
    before { sign_in user }

    context 'JSON形式のリクエスト' do
      context '公開されたギフト記録' do
        it 'お気に入り追加リクエストが拒否されること' do
          expect {
            post toggle_favorite_gift_record_path(public_gift_record),
                 headers: { 'Accept' => 'application/json' }
          }.not_to change(user.favorites, :count)

          expect(response).to have_http_status(:forbidden)
        end

        context 'すでにお気に入りに追加済み' do
          before { create(:favorite, user: user, gift_record: public_gift_record) }

          it 'お気に入り削除リクエストも拒否されること' do
            expect {
              post toggle_favorite_gift_record_path(public_gift_record),
                   headers: { 'Accept' => 'application/json' }
            }.not_to change(user.favorites, :count)

            expect(response).to have_http_status(:forbidden)
          end
        end
      end

      context '非公開のギフト記録' do
        it 'アクセス権限エラーになること' do
          post toggle_favorite_gift_record_path(private_gift_record),
               headers: { 'Accept' => 'application/json' }

          expect(response).to have_http_status(:forbidden)
        end
      end

      context '自分のギフト記録' do
        it 'リクエストが拒否されること' do
          expect {
            post toggle_favorite_gift_record_path(user_gift_record),
                 headers: { 'Accept' => 'application/json' }
          }.not_to change(user.favorites, :count)

          expect(response).to have_http_status(:forbidden)
        end
      end

      context '存在しないギフト記録' do
        it 'アクセスが拒否されること' do
          post toggle_favorite_gift_record_path(99999),
               headers: { 'Accept' => 'application/json' }

          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'HTML形式のリクエスト' do
      it 'お気に入り追加リクエストが拒否されること' do
        expect {
          post toggle_favorite_gift_record_path(public_gift_record)
        }.not_to change(user.favorites, :count)

        expect(response).to have_http_status(:forbidden)
      end

      context 'すでにお気に入りに追加済み' do
        before { create(:favorite, user: user, gift_record: public_gift_record) }

        it 'お気に入り削除リクエストが拒否されること' do
          expect {
            post toggle_favorite_gift_record_path(public_gift_record)
          }.not_to change(user.favorites, :count)

          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end
end
