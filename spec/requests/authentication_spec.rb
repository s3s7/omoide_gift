require 'rails_helper'

RSpec.describe 'Authentication', type: :request do
  describe 'ログイン機能' do
    let!(:user) { create(:user) }

    context '正しい認証情報でのログイン' do
      it '現在はアクセスが拒否されること' do
        post user_session_path, params: {
          user: {
            email: user.email,
            password: user.password
          }
        }
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
        }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context '存在しないメールアドレス' do
      it 'アクセスが拒否されること' do
        post user_session_path, params: {
          user: {
            email: 'nonexistent@example.com',
            password: 'password123'
          }
        }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'ログアウト機能' do
    let!(:user) { create(:user) }

    context 'ログイン済みユーザー' do
      before do
        sign_in user
      end

      it 'ログアウト要求も拒否されること' do
        delete destroy_user_session_path
        expect(response).to have_http_status(:forbidden)
        expect(session['warden.user.user.key']).to be_nil
      end
    end

    context '未ログインユーザー' do
      it 'アクセスが拒否されること' do
        delete destroy_user_session_path
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
