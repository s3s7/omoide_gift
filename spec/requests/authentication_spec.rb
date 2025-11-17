require 'rails_helper'

RSpec.describe 'Authentication', type: :request do
  let!(:user) { create(:user) }

  # HTMLリクエスト用（allow_browser を確実に通すモダンUA + Sec-CH）

  before { host! 'www.example.com' }

  describe 'Deviseヘルパーでのログイン' do
      context "ログインしている場合" do
      it "200が返る" do
        sign_in user
        get mypage_path
        puts response.body
        expect(response).to have_http_status(:ok)
      end
    end

    it 'sign_out でセッションがクリアされること' do
      sign_in user
      sign_out user
      get root_path
      expect(session['warden.user.user.key']).to be_nil
    end
  end
end
