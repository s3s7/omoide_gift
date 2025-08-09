require 'rails_helper'

RSpec.describe OmniauthCallbacksController, type: :controller do
  before do
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe 'LINE認証' do
    let(:omniauth_hash) do
      {
        'provider' => 'line',
        'uid' => '12345',
        'info' => {
          'name' => 'テストユーザー',
          'email' => 'test@example.com'
        },
        'credentials' => {
          'token' => 'token',
          'refresh_token' => 'refresh_token',
          'secret' => 'secret'
        }
      }
    end

    before do
      request.env['omniauth.auth'] = omniauth_hash
    end

    context '新規ユーザー' do
      it 'ユーザーが作成されてログインされること' do
        expect {
          get :line
        }.to change(User, :count).by(1)

        user = User.last
        expect(user.provider).to eq('line')
        expect(user.uid).to eq('12345')
        expect(user.name).to eq('テストユーザー')
        expect(user.email).to eq('test@example.com')
        expect(response).to redirect_to(mypage_path)
        expect(flash[:notice]).to eq('ログインしました')
      end
    end

    context 'メールアドレスが提供されない場合' do
      before do
        omniauth_hash['info']['email'] = nil
        request.env['omniauth.auth'] = omniauth_hash
      end

      it 'fake emailが設定されること' do
        get :line
        user = User.last
        expect(user.email).to eq('12345-line@example.com')
      end
    end

    context '既存ユーザー' do
      let!(:existing_user) do
        create(:user, provider: 'line', uid: '12345', name: '既存ユーザー')
      end

      it 'ログインされること' do
        expect {
          get :line
        }.not_to change(User, :count)

        expect(response).to redirect_to(mypage_path)
        expect(flash[:notice]).to eq('ログインしました')
      end
    end
  end
end
