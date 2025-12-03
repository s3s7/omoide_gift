require 'rails_helper'

RSpec.describe 'ギフト記録のソート', type: :request do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }

  describe 'ギフト記録一覧のソート機能' do
    let!(:old_record) do
      create(:gift_record,
        user: user1,
        item_name: '古い記録',
        is_public: true,
        created_at: 3.days.ago
      )
    end

    let!(:new_record) do
      create(:gift_record,
        user: user2,
        item_name: '新しい記録',
        is_public: true,
        created_at: 1.day.ago
      )
    end

    let!(:middle_record) do
      create(:gift_record,
        user: user3,
        item_name: '中間の記録',
        is_public: true,
        created_at: 2.days.ago
      )
    end

    context 'アクセス制御' do
      it '未ログインでも一覧を閲覧できること' do
        get gift_records_path
        expect(response).to have_http_status(:ok)
      end
    end

    context 'デフォルト（投稿日降順）' do
      it '公開フィードを閲覧できること' do
        get gift_records_path
        expect(response).to have_http_status(:ok)
      end
    end

    context '投稿日順ソート' do
      it '昇順パラメータでも閲覧できること' do
        get gift_records_path, params: { sort_by: 'created_at', sort_order: 'asc' }
        expect(response).to have_http_status(:ok)
      end

      it '降順パラメータでも閲覧できること' do
        get gift_records_path, params: { sort_by: 'created_at', sort_order: 'desc' }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'お気に入り数順ソート' do
      before do
        create_list(:favorite, 3, gift_record: old_record)
        create_list(:favorite, 1, gift_record: middle_record)
        create_list(:favorite, 2, gift_record: new_record)
      end

      it '降順ソート要求で閲覧できること' do
        get gift_records_path, params: { sort_by: 'favorites', sort_order: 'desc' }
        expect(response).to have_http_status(:ok)
      end

      it '昇順ソート要求で閲覧できること' do
        get gift_records_path, params: { sort_by: 'favorites', sort_order: 'asc' }
        expect(response).to have_http_status(:ok)
      end

      context 'お気に入り0件の記録が含まれる場合' do
        let!(:no_favorite_record) do
          create(:gift_record,
            user: user1,
            item_name: 'お気に入りなし',
            is_public: true
          )
        end

        it '降順要求でも閲覧できること' do
          get gift_records_path, params: { sort_by: 'favorites', sort_order: 'desc' }
          expect(response).to have_http_status(:ok)
        end

        it '昇順要求でも閲覧できること' do
          get gift_records_path, params: { sort_by: 'favorites', sort_order: 'asc' }
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context '無効なソートパラメータ' do
      it '無効なsort_byでもエラーにならないこと' do
        get gift_records_path, params: { sort_by: 'invalid' }
        expect(response).to have_http_status(:ok)
      end

      it '無効なsort_orderでもエラーにならないこと' do
        get gift_records_path, params: { sort_by: 'created_at', sort_order: 'invalid' }
        expect(response).to have_http_status(:ok)
      end
    end

    context '空のデータセット' do
      before do
        GiftRecord.destroy_all
        Favorite.destroy_all
      end

      it '記録が存在しなくてもエラーにならないこと' do
        get gift_records_path, params: { sort_by: 'favorites' }
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
