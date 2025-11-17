require 'rails_helper'

RSpec.describe 'GiftPeople', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:relationship) { create(:relationship) }
  let(:gift_person) { create(:gift_person, user: user, relationship: relationship) }
  let(:other_user_gift_person) { create(:gift_person, user: other_user, relationship: relationship) }

  describe '認証' do
    context '未ログインユーザー' do
      it 'ギフト相手一覧にアクセスできないこと' do
        get gift_people_path
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'ギフト相手一覧' do
    before do
      sign_in user
      gift_person
      other_user_gift_person
    end

    it '自分のギフト相手のみ表示されること' do
      get gift_people_path
      expect(response).to have_http_status(:ok)
    end

    context 'ソート機能' do
      let!(:person_a) { create(:gift_person, user: user, name: 'A太郎', relationship: relationship) }
      let!(:person_b) { create(:gift_person, user: user, name: 'B花子', relationship: relationship) }
      let!(:person_c) { create(:gift_person, user: user, name: 'C次郎', relationship: relationship) }

      context 'デフォルト（名前順）' do
        it '名前順で表示されること' do
          get gift_people_path
          expect(response).to have_http_status(:ok)
        end
      end

      context 'ギフト記録数順ソート' do
        before do
          # gift_peopleのIDを正確に指定してgift_recordを作成
          create_list(:gift_record, 3, user: user, gift_people_id: person_a.id) # A太郎: 3件
          create_list(:gift_record, 1, user: user, gift_people_id: person_b.id) # B花子: 1件
          create_list(:gift_record, 2, user: user, gift_people_id: person_c.id) # C次郎: 2件
        end

        it '降順でソートされること' do
          get gift_people_path, params: { sort_by: 'gift_records_count', sort_order: 'desc' }
          expect(response).to have_http_status(:ok)
        end

        it '昇順でソートされること' do
          get gift_people_path, params: { sort_by: 'gift_records_count', sort_order: 'asc' }
          expect(response).to have_http_status(:ok)
        end
      end

      context '無効なソートパラメータ' do
        it '無効なsort_byでもエラーにならないこと' do
          get gift_people_path, params: { sort_by: 'invalid' }
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe 'ギフト相手作成' do
    before { sign_in user }

    context '正しいパラメータ' do
      let(:valid_params) do
        {
          gift_person: {
            name: '山田太郎',
            relationship_id: relationship.id,
            birthday: Date.current - 30.years,
            likes: 'コーヒー',
            memo: 'いい人'
          }
        }
      end

      it 'ギフト相手が作成されること' do
        expect {
          post gift_people_path, params: valid_params
        }.to change(user.gift_people, :count).by(1)
        expect(response).to have_http_status(:found)
      end
    end

    context '名前が空の場合' do
      let(:invalid_params) do
        {
          gift_person: {
            name: '',
            relationship_id: relationship.id
          }
        }
      end

      it 'ギフト相手が作成されないこと' do
        expect {
          post gift_people_path, params: invalid_params
        }.not_to change(GiftPerson, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'ギフト相手詳細' do
    before { sign_in user }

    context '自分のギフト相手' do
      it '詳細が表示されること' do
        get gift_person_path(gift_person)
        expect(response).to have_http_status(:ok)
      end
    end

    context '他人のギフト相手' do
      it 'アクセスが拒否されること' do
        get gift_person_path(other_user_gift_person)
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(gift_people_path)
      end
    end
  end

  describe 'ギフト相手更新' do
    before { sign_in user }

    context '正しいパラメータ' do
      let(:update_params) do
        {
          gift_person: {
            name: '更新された名前',
            relationship_id: relationship.id
          }
        }
      end

      it 'ギフト相手が更新されること' do
        patch gift_person_path(gift_person), params: update_params
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(gift_person_path(gift_person))
      end
    end

    context '他人のギフト相手を更新しようとした場合' do
      it 'アクセスが拒否されること' do
        patch gift_person_path(other_user_gift_person), params: {
          gift_person: { name: '不正更新' }
        }
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(gift_people_path)
      end
    end
  end

  describe 'ギフト相手削除' do
    before { sign_in user }

    context '自分のギフト相手' do
      it '削除されること' do
        gift_person # create
        expect {
          delete gift_person_path(gift_person)
        }.to change(user.gift_people, :count).by(-1)
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(gift_people_path)
      end
    end

    context '他人のギフト相手' do
      it 'アクセスが拒否されること' do
        delete gift_person_path(other_user_gift_person)
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(gift_people_path)
      end
    end
  end
end
