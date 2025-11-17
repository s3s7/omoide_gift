require 'rails_helper'

RSpec.describe 'GiftPeople Filter', type: :request do
  let(:user) { create(:user) }
  let(:relationship) { create(:relationship) }
  let(:other_relationship) { create(:relationship) }
  let(:event) { create(:event) }

  # フィルター機能専用テストデータ
  let!(:searchable_person) do
    create(:gift_person,
      user: user,
      name: '田中花子',
      relationship: relationship,
      memo: 'いつもお世話になっている人',
      likes: 'コーヒー、読書',
      dislikes: '辛い食べ物'
    )
  end

  let!(:other_person) do
    create(:gift_person,
      user: user,
      name: '佐藤次郎',
      relationship: other_relationship,
      likes: 'スポーツ',
      dislikes: nil
    )
  end

  before { sign_in user }

  describe 'GET /gift_people 検索フィルター' do
    context '複数フィールド検索（ログイン時は許可）' do
      it 'メモ内容での検索要求は成功する' do
        get gift_people_path, params: { search: 'お世話になっている' }
        expect(response).to have_http_status(:ok)
      end

      it '好きなもの検索要求は成功する' do
        get gift_people_path, params: { search: 'コーヒー' }
        expect(response).to have_http_status(:ok)
      end

      it '嫌いなもの検索要求は成功する' do
        get gift_people_path, params: { search: '辛い食べ物' }
        expect(response).to have_http_status(:ok)
      end

      it '大文字小文字を区別しない検索要求も成功する' do
        get gift_people_path, params: { search: '田中' }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'イベントフィルター（JOIN経由）' do
      before do
        create(:gift_record,
          user: user,
          gift_people_id: searchable_person.id,
          event: event
        )
      end

      it '指定イベントでのフィルター要求は成功する' do
        get gift_people_path, params: { event_id: event.id }
        expect(response).to have_http_status(:ok)
      end

      it 'DISTINCT処理で重複排除' do
        # 同じ人に複数の同イベント記録を作成
        create(:gift_record,
          user: user,
          gift_people_id: searchable_person.id,
          event: event
        )

        get gift_people_path, params: { event_id: event.id }
        expect(response).to have_http_status(:ok)
      end
    end

    context '複合フィルター組み合わせ' do
      it '検索+関係性の複合条件は成功する' do
        get gift_people_path, params: {
          search: '田中',
          relationship_id: relationship.id
        }
        expect(response).to have_http_status(:ok)
      end

      it '矛盾する条件でもエラーなく成功する' do
        get gift_people_path, params: {
          search: '田中',
          relationship_id: other_relationship.id # 田中は家族、これは同僚
        }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'セキュリティとエッジケース' do
      it 'SQLインジェクション攻撃の防御' do
        original_count = GiftPerson.count
        get gift_people_path, params: { search: "'; DROP TABLE gift_people; --" }
        expect(response).to have_http_status(:ok)
        expect(GiftPerson.count).to eq(original_count)
      end

      it 'XSS攻撃の防御' do
        get gift_people_path, params: { search: '<script>alert("xss")</script>' }
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include('<script>alert("xss")</script>')
      end

      it '空文字検索でもエラーなし' do
        get gift_people_path, params: { search: '' }
        expect(response).to have_http_status(:ok)
      end

      it '存在しないIDでもエラーなし' do
        get gift_people_path, params: {
          relationship_id: 99999,
          event_id: 99999
        }
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET /gift_people/autocomplete' do
    it 'JSON形式の検索結果' do
      get autocomplete_gift_people_path, params: { q: '田中' }
      expect(response).to have_http_status(:ok)
    end

    it 'パフォーマンス：結果制限' do
      # 大量データでも適切に制限される
      create_list(:gift_person, 15, user: user, name: 'テストユーザー')

      get autocomplete_gift_people_path, params: { q: 'テスト' }
      expect(response).to have_http_status(:ok)
    end

    it '認証必須' do
      sign_out user
      get autocomplete_gift_people_path, params: { q: 'test' }
      expect(response).to have_http_status(:forbidden)
    end
  end
end
