require 'rails_helper'

RSpec.describe 'Authentication', type: :request do
  describe 'ログイン機能' do
    let!(:user) { create(:user) }

    context '正しい認証情報でのログイン' do
      it 'ログインが成功すること' do
        post user_session_path, params: {
          user: {
            email: user.email,
            password: user.password
          }
        }
        expect(response).to redirect_to(root_path)
        expect(session['warden.user.user.key']).to be_present
      end
    end

    context '間違った認証情報でのログイン' do
      it 'ログインが失敗すること' do
        post user_session_path, params: {
          user: {
            email: user.email,
            password: 'wrong_password'
          }
        }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('ログイン')
      end
    end

    context '存在しないメールアドレス' do
      it 'ログインが失敗すること' do
        post user_session_path, params: {
          user: {
            email: 'nonexistent@example.com',
            password: 'password123'
          }
        }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('ログイン')
      end
    end
  end

  describe 'ログアウト機能' do
    let!(:user) { create(:user) }

    context 'ログイン済みユーザー' do
      before do
        sign_in user
      end

      it 'ログアウトが成功すること' do
        delete destroy_user_session_path
        expect(response).to redirect_to(root_path)
        expect(session['warden.user.user.key']).to be_nil
      end
    end

    context '未ログインユーザー' do
      it 'ルートにリダイレクトされること' do
        delete destroy_user_session_path
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
