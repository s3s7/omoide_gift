require 'rails_helper'

RSpec.describe 'Authentication', type: :request do
  before { host! 'www.example.com' }

  describe 'ログイン機能' do
    let!(:user) { create(:user) }

    context '正しい認証情報でのログイン' do
      it 'アクセスが拒否されること' do
        post user_session_path, params: {
          user: {
            email: user.email,
            password: user.password
          }
        }, headers: { 'ACCEPT' => 'text/html' }
        expect(response).to have_http_status(:forbidden)
        expect(session['warden.user.user.key']).to be_nil
      end
    end

    context '間違った認証情報でのログイン' do
      it 'アクセスが拒否されること' do
        post user_session_path, params: {
          user: {
            email: user.email,
            password: 'wrong_password'
          }
        }, headers: { 'ACCEPT' => 'text/html' }
        expect(response).to have_http_status(:forbidden)
        expect(session['warden.user.user.key']).to be_nil
      end
    end

    context '存在しないメールアドレス' do
      it 'アクセスが拒否されること' do
        post user_session_path, params: {
          user: {
            email: 'nonexistent@example.com',
            password: 'password123'
          }
        }, headers: { 'ACCEPT' => 'text/html' }
        expect(response).to have_http_status(:forbidden)
        expect(session['warden.user.user.key']).to be_nil
      end
    end
  end

  describe 'ログアウト機能' do
    let!(:user) { create(:user) }

    context 'ログイン済みユーザー' do
      before do
        sign_in user
      end

      it 'アクセスが拒否され、ログイン状態が解除されること' do
        delete destroy_user_session_path, headers: { 'ACCEPT' => 'text/html' }
        expect(response).to have_http_status(:forbidden)
        expect(session['warden.user.user.key']).to be_nil
      end
    end

    context '未ログインユーザー' do
      it 'アクセスが拒否されること' do
        delete destroy_user_session_path, headers: { 'ACCEPT' => 'text/html' }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
