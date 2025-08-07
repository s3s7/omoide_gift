require 'rails_helper'

RSpec.describe GiftRecordsController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:event) { create(:event) }
  let(:gift_person) { create(:gift_person, user: user) }

  describe 'GET #index' do
    let!(:public_record) { create(:gift_record, user: user, event: event, gift_person: gift_person, is_public: true) }
    let!(:private_record) { create(:private_gift_record, user: other_user, event: event, gift_person: create(:gift_person, user: other_user), is_public: false) }

    context '未ログイン状態' do
      it '公開記録のみが表示される' do
        # デバッグ情報
        puts "public_record: #{public_record.inspect}"
        puts "private_record: #{private_record.inspect}"
        
        get :index
        
        # デバッグ情報
        puts "response.status: #{response.status}"
        puts "response.body length: #{response.body.length}"
        puts "response.body: #{response.body[0..200]}..." if response.body.present?
        
        expect(response).to have_http_status(:success)
        expect(response.body).to include(public_record.item_name)
        expect(response.body).not_to include(private_record.item_name)
      end
    end

    context 'ログイン状態' do
      before { sign_in user }

      it '公開記録のみが表示される（修正後のロジック）' do
        get :index
        expect(response).to have_http_status(:success)
        expect(response.body).to include(gift_record_path(public_record))
        expect(response.body).not_to include(gift_record_path(private_record))
      end
    end
  end

  describe 'GET #show' do
    let!(:public_record) { create(:gift_record, user: other_user, event: event, gift_person: create(:gift_person, user: other_user), is_public: true) }
    let!(:private_record) { create(:private_gift_record, user: user, event: event, gift_person: gift_person, is_public: false) }

    context '未ログイン状態' do
      it '公開記録は閲覧可能' do
        get :show, params: { id: public_record.id }
        expect(response).to have_http_status(:success)
        expect(response.body).to include(public_record.item_name)
      end

      it '非公開記録は閲覧不可' do
        get :show, params: { id: private_record.id }
        expect(response).to redirect_to(gift_records_path)
      end
    end

    context 'ログイン状態' do
      before { sign_in user }

      it '自分の非公開記録は閲覧可能' do
        get :show, params: { id: private_record.id }
        expect(response).to have_http_status(:success)
        expect(response.body).to include(private_record.item_name)
      end
    end
  end

  describe 'GET #new' do
    context '未ログイン状態' do
      it 'ログイン画面にリダイレクト' do
        get :new
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'ログイン状態' do
      before { sign_in user }

      it '新規作成画面が表示される' do
        get :new
        expect(response).to have_http_status(:success)
        expect(response.body).to include('新しいギフト記録')
      end
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        item_name: 'テストプレゼント',
        amount: 1000,
        gift_at: Date.current,
        memo: 'テストメモ',
        is_public: true,
        gift_people_id: gift_person.id,
        event_id: event.id
      }
    end

    context '未ログイン状態' do
      it 'ログイン画面にリダイレクト' do
        post :create, params: { gift_record: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'ログイン状態' do
      before { sign_in user }

      context '有効なパラメータ' do
        it 'ギフト記録が作成される' do
          expect {
            post :create, params: { gift_record: valid_attributes }
          }.to change(GiftRecord, :count).by(1)
        end

        it '一覧画面にリダイレクト' do
          post :create, params: { gift_record: valid_attributes }
          expect(response).to redirect_to(gift_records_path)
        end
      end

      context '無効なパラメータ' do
        it 'ギフト記録が作成されない' do
          expect {
            post :create, params: { gift_record: { item_name: '' } }
          }.not_to change(GiftRecord, :count)
        end

        it '新規作成画面が再表示される' do
          post :create, params: { gift_record: { item_name: '' } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'GET #edit' do
    let!(:gift_record) { create(:gift_record, user: user, event: event, gift_person: gift_person) }
    let!(:other_user_record) { create(:gift_record, user: other_user, event: event, gift_person: create(:gift_person, user: other_user)) }

    context '未ログイン状態' do
      it 'ログイン画面にリダイレクト' do
        get :edit, params: { id: gift_record.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'ログイン状態' do
      before { sign_in user }

      it '自分の記録は編集可能' do
        get :edit, params: { id: gift_record.id }
        expect(response).to have_http_status(:success)
        expect(response.body).to include(gift_record.item_name)
      end

      it '他人の記録は編集不可' do
        get :edit, params: { id: other_user_record.id }
        expect(response).to redirect_to(gift_records_path)
      end
    end
  end

  describe 'PATCH #update' do
    let!(:gift_record) { create(:gift_record, user: user, event: event, gift_person: gift_person) }
    let(:update_attributes) { { item_name: '更新されたプレゼント' } }

    context '未ログイン状態' do
      it 'ログイン画面にリダイレクト' do
        patch :update, params: { id: gift_record.id, gift_record: update_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'ログイン状態' do
      before { sign_in user }

      context '有効なパラメータ' do
        it 'ギフト記録が更新される' do
          patch :update, params: { id: gift_record.id, gift_record: update_attributes }
          gift_record.reload
          expect(gift_record.item_name).to eq('更新されたプレゼント')
        end

        it '詳細画面にリダイレクト' do
          patch :update, params: { id: gift_record.id, gift_record: update_attributes }
          expect(response).to redirect_to(gift_record)
        end
      end

      context '無効なパラメータ' do
        it '編集画面が再表示される' do
          patch :update, params: { id: gift_record.id, gift_record: { item_name: '' } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:gift_record) { create(:gift_record, user: user, event: event, gift_person: gift_person) }
    let!(:other_user_record) { create(:gift_record, user: other_user, event: event, gift_person: create(:gift_person, user: other_user)) }

    context '未ログイン状態' do
      it 'ログイン画面にリダイレクト' do
        delete :destroy, params: { id: gift_record.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'ログイン状態' do
      before { sign_in user }

      it '自分の記録は削除可能' do
        expect {
          delete :destroy, params: { id: gift_record.id }
        }.to change(GiftRecord, :count).by(-1)
      end

      it '削除後は一覧画面にリダイレクト' do
        delete :destroy, params: { id: gift_record.id }
        expect(response).to redirect_to(gift_records_path)
      end

      it '他人の記録は削除不可' do
        expect {
          delete :destroy, params: { id: other_user_record.id }
        }.not_to change(GiftRecord, :count)
      end
    end
  end
end
