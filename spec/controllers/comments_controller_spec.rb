require 'rails_helper'

RSpec.describe CommentsController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:gift_record) { create(:gift_record, user: user) }
  let(:comment) { create(:comment, user: user, gift_record: gift_record) }

  describe 'セキュリティテスト' do
    context '認証なし' do
      it 'コメント作成を拒否する' do
        post :create, params: { gift_record_id: gift_record.id, comment: { body: 'test' } }
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'コメント編集を拒否する' do
        patch :update, params: { gift_record_id: gift_record.id, id: comment.id, comment: { body: 'updated' } }
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'コメント削除を拒否する' do
        delete :destroy, params: { gift_record_id: gift_record.id, id: comment.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context '他人のギフト記録' do
      let(:other_gift_record) { create(:gift_record, user: other_user) }

      before { sign_in user }

      it '他人のギフト記録にコメントできない' do
        post :create, params: { gift_record_id: other_gift_record.id, comment: { body: 'test' } }
        expect(response).to redirect_to(gift_records_path)
        expect(flash[:alert]).to include('ギフト記録が見つかりません')
      end
    end

    context '他人のコメント編集・削除' do
      let(:other_comment) { create(:comment, user: other_user, gift_record: gift_record) }

      before { sign_in user }

      it '他人のコメント編集を拒否する' do
        patch :update, params: { gift_record_id: gift_record.id, id: other_comment.id, comment: { body: 'hacked' } }
        expect(response).to redirect_to(gift_record)
        expect(flash[:alert]).to include('他のユーザーのコメントは編集・削除できません')
      end

      it '他人のコメント削除を拒否する' do
        delete :destroy, params: { gift_record_id: gift_record.id, id: other_comment.id }
        expect(response).to redirect_to(gift_record)
        expect(flash[:alert]).to include('他のユーザーのコメントは編集・削除できません')
      end
    end
  end

  describe 'JSONレスポンス' do
    before { sign_in user }

    context 'コメント作成' do
      it '成功時はJSONを返す' do
        post :create, params: {
          gift_record_id: gift_record.id,
          comment: { body: 'テストコメント' }
        }, format: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['comment']['body']).to eq('テストコメント')
      end

      it '失敗時はエラーJSONを返す' do
        post :create, params: {
          gift_record_id: gift_record.id,
          comment: { body: '' }
        }, format: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['errors']).to be_present
      end
    end

    context 'コメント更新' do
      it '成功時はJSONを返す' do
        patch :update, params: {
          gift_record_id: gift_record.id,
          id: comment.id,
          comment: { body: '更新されたコメント' }
        }, format: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['comment']['body']).to eq('更新されたコメント')
      end
    end

    context 'コメント削除' do
      it '成功時はJSONを返す' do
        delete :destroy, params: {
          gift_record_id: gift_record.id,
          id: comment.id
        }, format: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
      end
    end
  end

  describe 'HTMLリダイレクト' do
    before { sign_in user }

    it 'コメント作成成功時はgift_record詳細にリダイレクト' do
      post :create, params: {
        gift_record_id: gift_record.id,
        comment: { body: 'テストコメント' }
      }

      expect(response).to redirect_to(gift_record)
      expect(flash[:notice]).to eq('コメントを投稿しました。')
    end

    it 'コメント削除成功時はgift_record詳細にリダイレクト' do
      delete :destroy, params: { gift_record_id: gift_record.id, id: comment.id }

      expect(response).to redirect_to(gift_record)
      expect(flash[:notice]).to eq('コメントを削除しました。')
    end
  end
end
