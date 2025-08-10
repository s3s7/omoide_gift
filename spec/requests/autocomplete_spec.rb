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

    it 'JSON形式で結果を返す' do
      get autocomplete_gift_records_path, params: { query: 'Nintendo' }
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/json')
    end

    it '商品名での検索結果を返す' do
      get autocomplete_gift_records_path, params: { query: 'Nintendo' }
      
      json = JSON.parse(response.body)
      expect(json['results']).to be_present
      expect(json['results'].first['text']).to include('Nintendo Switch')
    end

    it 'メモでの検索も機能' do
      get autocomplete_gift_records_path, params: { query: 'ゲーム機' }
      
      json = JSON.parse(response.body)
      expect(json['results'].first['text']).to include('Nintendo Switch')
    end

    it '認証が必要' do
      sign_out user
      get autocomplete_gift_records_path, params: { query: 'test' }
      
      expect(response).to redirect_to(new_user_session_path)
    end

    it '空クエリでエラーなし' do
      get autocomplete_gift_records_path, params: { query: '' }
      
      expect(response).to have_http_status(:success)
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

    it 'JSON形式で結果を返す' do
      get autocomplete_gift_people_path, params: { query: '田中' }
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/json')
    end

    it '名前での検索結果を返す' do
      get autocomplete_gift_people_path, params: { query: '田中' }
      
      json = JSON.parse(response.body)
      expect(json['results']).to be_present
      expect(json['results'].first['text']).to include('田中太郎')
    end

    it 'メモでの検索も機能' do
      get autocomplete_gift_people_path, params: { query: '親友' }
      
      json = JSON.parse(response.body)
      expect(json['results'].first['text']).to include('田中太郎')
    end

    it '他ユーザーのデータは検索対象外' do
      get autocomplete_gift_people_path, params: { query: '佐藤' }
      
      json = JSON.parse(response.body)
      expect(json['results']).to be_empty
    end

    it '認証が必要' do
      sign_out user
      get autocomplete_gift_people_path, params: { query: 'test' }
      
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'パフォーマンステスト' do
    it '結果件数制限（大量データ対応）' do
      create_list(:gift_record, 20, user: user, item_name: 'テスト商品', is_public: true)
      
      get autocomplete_gift_records_path, params: { query: 'テスト' }
      
      json = JSON.parse(response.body)
      expect(json['results'].length).to be <= 10 # 結果制限確認
    end

    it 'レスポンス時間（簡易チェック）' do
      start_time = Time.current
      
      get autocomplete_gift_records_path, params: { query: 'test' }
      
      response_time = Time.current - start_time
      expect(response_time).to be < 1.0 # 1秒以内
    end
  end
end