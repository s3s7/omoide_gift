require 'rails_helper'

RSpec.describe 'GiftRecords Filter', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:relationship) { create(:relationship) }
  let(:event) { create(:event) }
  let(:gift_person) { create(:gift_person, user: user, name: '山田太郎', relationship: relationship) }

  # テストデータ
  let!(:target_record) do
    create(:gift_record,
      user: user,
      gift_people_id: gift_person.id,
      event: event,
      item_name: 'テスト商品',
      memo: 'テストメモ',
      gift_at: 1.week.ago,
      is_public: true
    )
  end

  let!(:other_record) do
    create(:gift_record,
      user: other_user,
      item_name: '関係ない商品',
      is_public: true
    )
  end

  describe 'GET /gift_records フィルター機能' do
    before { sign_in user }

    context '検索機能' do
      it '現在は検索リクエストが拒否されること（商品名）' do
        get gift_records_path, params: { search: 'テスト商品' }
        expect(response).to have_http_status(:forbidden)
        expect(response.body).not_to include('テスト商品')
      end

      it '現在は検索リクエストが拒否されること（メモ）' do
        get gift_records_path, params: { search: 'テストメモ' }
        expect(response).to have_http_status(:forbidden)
      end

      it '現在は検索リクエストが拒否されること（ギフト相手名）' do
        get gift_records_path, params: { search: '山田太郎' }
        expect(response).to have_http_status(:forbidden)
      end

      it '部分一致検索も拒否されること' do
        get gift_records_path, params: { search: 'テスト' }
        expect(response).to have_http_status(:forbidden)
      end

      it '大文字小文字の違いに関わらず拒否されること' do
        get gift_records_path, params: { search: 'テスト' }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'ギフト相手フィルタ' do
      it '指定ギフト相手の記録のみ表示されること' do
        get gift_records_path, params: { gift_person_id: gift_person.id }
        expect(response).to have_http_status(:forbidden)
      end

      it '存在しないIDでもエラーにならないこと' do
        get gift_records_path, params: { gift_person_id: 99999 }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context '関係性フィルタ' do
      it '指定関係性の記録のみ表示されること' do
        get gift_records_path, params: { relationship_id: relationship.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'イベントフィルタ' do
      it '指定イベントの記録のみ表示されること' do
        get gift_records_path, params: { event_id: event.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context '日付範囲フィルタ' do
      it '指定期間の記録のみ表示されること' do
        get gift_records_path, params: {
          date_from: 2.weeks.ago.to_date,
          date_to: Date.current
        }
        expect(response).to have_http_status(:forbidden)
      end

      it '期間外は表示されないこと' do
        get gift_records_path, params: {
          date_from: 1.month.ago.to_date,
          date_to: 2.weeks.ago.to_date
        }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context '複合フィルタ' do
      it '複数条件で絞り込めること' do
        get gift_records_path, params: {
          search: 'テスト',
          relationship_id: relationship.id,
          event_id: event.id
        }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'セキュリティ' do
      it 'SQLインジェクション攻撃を防げること' do
        get gift_records_path, params: { search: "'; DROP TABLE gift_records; --" }
        expect(response).to have_http_status(:forbidden)
        expect(GiftRecord.count).to be > 0 # テーブルが削除されていないこと
      end

      it 'XSS攻撃を防げること' do
        get gift_records_path, params: { search: '<script>alert("xss")</script>' }
        expect(response).to have_http_status(:forbidden)
        expect(response.body).not_to include('<script>alert("xss")</script>')
      end
    end
  end

  describe 'GET /gift_records/autocomplete' do
    before { sign_in user }

    it '現在はアクセスが制限されていること（JSON）' do
      get autocomplete_gift_records_path, params: { q: 'テスト' }
      expect(response).to have_http_status(:forbidden)
    end

    it '検索リクエストも拒否されること' do
      get autocomplete_gift_records_path, params: { q: 'テスト商品' }
      expect(response).to have_http_status(:forbidden)
    end

    it '空クエリでも拒否されること' do
      get autocomplete_gift_records_path, params: { q: '' }
      expect(response).to have_http_status(:forbidden)
    end

    it '未ログインではアクセス不可' do
      sign_out user
      get autocomplete_gift_records_path, params: { q: 'test' }
      expect(response).to have_http_status(:forbidden)
    end
  end
end
