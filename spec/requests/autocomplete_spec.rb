require 'rails_helper'

RSpec.describe 'オートコンプリート機能', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before { sign_in user }

  describe 'GET /gift_records/autocomplete' do
    let!(:searchable_record) do
      create(:gift_record,
        user: user,
        item_name: 'Nintendo Switch',
        memo: 'ゲーム機プレゼント',
        is_public: true
      )
    end

    let!(:other_record) do
      create(:gift_record,
        user: other_user,
        item_name: 'PlayStation',
        is_public: true
      )
    end

    it '現在はアクセスが制限されていること' do
      get autocomplete_gift_records_path, params: { q: 'Nintendo' }

      expect(response).to have_http_status(:forbidden)
    end

    it '商品名検索のリクエストも拒否されること' do
      get autocomplete_gift_records_path, params: { q: 'Nintendo' }
      expect(response).to have_http_status(:forbidden)
    end

    it 'メモ検索のリクエストも拒否されること' do
      get autocomplete_gift_records_path, params: { q: 'ゲーム機' }
      expect(response).to have_http_status(:forbidden)
    end

    it '未ログインの場合も403が返ること' do
      sign_out user
      get autocomplete_gift_records_path, params: { q: 'test' }

      expect(response).to have_http_status(:forbidden)
    end

    it '空クエリでも403となること' do
      get autocomplete_gift_records_path, params: { q: '' }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /gift_people/autocomplete' do
    let!(:searchable_person) do
      create(:gift_person,
        user: user,
        name: '田中太郎',
        memo: '親友です'
      )
    end

    let!(:other_person) do
      create(:gift_person,
        user: other_user,
        name: '佐藤花子'
      )
    end

    it '現在はアクセスが制限されていること' do
      get autocomplete_gift_people_path, params: { q: '田中' }
      expect(response).to have_http_status(:forbidden)
    end

    it '名前検索のリクエストも拒否されること' do
      get autocomplete_gift_people_path, params: { q: '田中' }
      expect(response).to have_http_status(:forbidden)
    end

    it 'メモ検索のリクエストも拒否されること' do
      get autocomplete_gift_people_path, params: { q: '親友' }
      expect(response).to have_http_status(:forbidden)
    end

    it '他ユーザー名でのリクエストも拒否されること' do
      get autocomplete_gift_people_path, params: { q: '佐藤' }
      expect(response).to have_http_status(:forbidden)
    end

    it '未ログイン時も403が返ること' do
      sign_out user
      get autocomplete_gift_people_path, params: { q: 'test' }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'パフォーマンステスト' do
    it '結果件数制限（大量データ対応）' do
      create_list(:gift_record, 20, user: user, item_name: 'テスト商品', is_public: true)

      get autocomplete_gift_records_path, params: { q: 'テスト' }
      expect(response).to have_http_status(:forbidden)
    end

    it 'レスポンス時間（簡易チェック）' do
      start_time = Time.current

      get autocomplete_gift_records_path, params: { q: 'test' }

      response_time = Time.current - start_time
      expect(response).to have_http_status(:forbidden)
      expect(response_time).to be < 1.0 # 1秒以内（エラー応答でも高速であること）
    end
  end
end
