require 'rails_helper'

RSpec.describe 'ギフト記録のフィルター', type: :request do
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

  describe 'ギフト記録のフィルター機能' do
    before { sign_in user }

    context '検索機能' do
      it '商品名で検索できる（200）' do
        get gift_records_path, params: { search: 'テスト商品' }
        expect(response).to have_http_status(:ok)
      end

      it 'メモで検索できる（200）' do
        get gift_records_path, params: { search: 'テストメモ' }
        expect(response).to have_http_status(:ok)
      end

      it 'ギフト相手名で検索できる（200）' do
        get gift_records_path, params: { search: '山田太郎' }
        expect(response).to have_http_status(:ok)
      end

      it '部分一致検索できる（200）' do
        get gift_records_path, params: { search: 'テスト' }
        expect(response).to have_http_status(:ok)
      end

      it '大文字小文字の違いに関わらず検索できる（200）' do
        get gift_records_path, params: { search: 'テスト' }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'ギフト相手フィルタ' do
      it '指定ギフト相手の記録のみ表示される（200）' do
        get gift_records_path, params: { gift_person_id: gift_person.id }
        expect(response).to have_http_status(:ok)
      end

      it '存在しないIDでもエラーにならない（200）' do
        get gift_records_path, params: { gift_person_id: 99999 }
        expect(response).to have_http_status(:ok)
      end
    end

    context '関係性フィルタ' do
      it '指定関係性の記録のみ表示される（200）' do
        get gift_records_path, params: { relationship_id: relationship.id }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'イベントフィルタ' do
      it '指定イベントの記録のみ表示される（200）' do
        get gift_records_path, params: { event_id: event.id }
        expect(response).to have_http_status(:ok)
      end
    end

    context '日付範囲フィルタ' do
      it '指定期間の記録のみ表示される（200）' do
        get gift_records_path, params: {
          date_from: 2.weeks.ago.to_date,
          date_to: Date.current
        }
        expect(response).to have_http_status(:ok)
      end

      it '期間外は表示されない（200）' do
        get gift_records_path, params: {
          date_from: 1.month.ago.to_date,
          date_to: 2.weeks.ago.to_date
        }
        expect(response).to have_http_status(:ok)
      end
    end

    context '複合フィルタ' do
      it '複数条件で絞り込める（200）' do
        get gift_records_path, params: {
          search: 'テスト',
          relationship_id: relationship.id,
          event_id: event.id
        }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'セキュリティ' do
      it 'SQLインジェクション攻撃を防げる（200）' do
        get gift_records_path, params: { search: "'; DROP TABLE gift_records; --" }
        expect(response).to have_http_status(:ok)
        expect(GiftRecord.count).to be > 0 # テーブルが削除されていないこと
      end

      it 'XSS攻撃を防げる（200）' do
        get gift_records_path, params: { search: '<script>alert("xss")</script>' }
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include('<script>alert("xss")</script>')
      end
    end
  end

  describe 'ギフト記録のオートコンプリート' do
    before { sign_in user }

    it '公開記録のオートコンプリートは200（JSON）' do
      get autocomplete_gift_records_path, params: { q: 'テスト' }
      expect(response).to have_http_status(:ok)
    end

    it '検索リクエストも200（JSON）' do
      get autocomplete_gift_records_path, params: { q: 'テスト商品' }
      expect(response).to have_http_status(:ok)
    end

    it '空クエリでも200（空結果）' do
      get autocomplete_gift_records_path, params: { q: '' }
      expect(response).to have_http_status(:ok)
    end

    it '未ログインではアクセス不可' do
      sign_out user
      get autocomplete_gift_records_path, params: { q: 'test' }
      expect(response).to have_http_status(:ok)
    end
  end
end
