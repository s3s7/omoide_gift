require "rails_helper"

RSpec.describe "オートコンプリート機能", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before { sign_in user }

  describe "GET /gift_records/autocomplete" do
    let!(:searchable_record) do
      create(:gift_record,
        user: user,
        item_name: "Nintendo Switch",
        memo: "ゲーム機プレゼント",
        is_public: true)
    end

    let!(:other_record) do
      create(:gift_record,
        user: other_user,
        item_name: "PlayStation",
        memo: "別ユーザーの記録",
        is_public: true)
    end

    it "商品名で一致するギフト記録を返す（200）" do
      get autocomplete_gift_records_path(format: :json), params: { q: "Nintendo" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      ids = json.fetch("results", []).map { |item| item.fetch("id") }

      expect(ids).to include(searchable_record.id)
      expect(ids).not_to include(other_record.id)
    end

    it "メモ検索でも一致するギフト記録を返す（200）" do
      get autocomplete_gift_records_path(format: :json), params: { q: "ゲーム機" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      ids = json.fetch("results", []).map { |item| item.fetch("id") }

      expect(ids).to include(searchable_record.id)
    end

    it "未ログインでも利用可能（200）" do
      sign_out user
      get autocomplete_gift_records_path(format: :json), params: { q: "test" }

      expect(response).to have_http_status(:ok)
    end

    it "空クエリでは空配列を返す（200）" do
      get autocomplete_gift_records_path(format: :json), params: { q: "" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.fetch("results", [])).to be_empty
    end

    it "最大件数に制限される（200）" do
      create_list(:gift_record, 20, user: user, item_name: "テスト商品", is_public: true)

      get autocomplete_gift_records_path(format: :json), params: { q: "テスト" }
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json.fetch("results", []).size).to be <= GiftRecordsController::AUTOCOMPLETE_RESULT_LIMIT
    end
  end

  describe "GET /gift_people/autocomplete" do
    let!(:searchable_person) do
      create(:gift_person,
        user: user,
        name: "田中太郎",
        memo: "親友です")
    end

    let!(:other_person) do
      create(:gift_person,
        user: other_user,
        name: "佐藤花子",
        memo: "別ユーザー")
    end

    it "名前で一致するギフト相手を返す（200）" do
      get autocomplete_gift_people_path(format: :json), params: { q: "田中" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      names = json.fetch("results", []).map { |item| item.fetch("name") }

      expect(names).to include("田中太郎")
      expect(names).not_to include("佐藤花子")
    end

    it "メモで一致するギフト相手を返す（200）" do
      get autocomplete_gift_people_path(format: :json), params: { q: "親友" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      names = json.fetch("results", []).map { |item| item.fetch("name") }

      expect(names).to include("田中太郎")
    end

    it "未ログインは認証エラー（401）" do
      sign_out user
      get autocomplete_gift_people_path(format: :json), params: { q: "test" }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
