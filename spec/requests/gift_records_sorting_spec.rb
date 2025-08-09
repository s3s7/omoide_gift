require 'rails_helper'

RSpec.describe 'GiftRecords Sorting', type: :request do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }

  describe 'ギフト記録一覧のソート機能' do
    let!(:old_record) do
      create(:gift_record, 
        user: user1, 
        item_name: '古い記録',
        is_public: true,
        created_at: 3.days.ago
      )
    end
    
    let!(:new_record) do
      create(:gift_record, 
        user: user2, 
        item_name: '新しい記録',
        is_public: true,
        created_at: 1.day.ago
      )
    end
    
    let!(:middle_record) do
      create(:gift_record, 
        user: user3, 
        item_name: '中間の記録',
        is_public: true,
        created_at: 2.days.ago
      )
    end

    context 'デフォルト（投稿日降順）' do
      it '投稿日降順で表示されること' do
        get gift_records_path
        expect(response).to have_http_status(:ok)
        
        # レスポンスから記録の出現順序をチェック（新しい > 中間 > 古い）
        body = response.body
        new_index = body.index('新しい記録')
        middle_index = body.index('中間の記録')
        old_index = body.index('古い記録')
        
        expect(new_index).to be < middle_index
        expect(middle_index).to be < old_index
      end
    end

    context '投稿日順ソート' do
      it '昇順でソートされること' do
        get gift_records_path, params: { sort_by: 'created_at', sort_order: 'asc' }
        expect(response).to have_http_status(:ok)
        
        # レスポンスから記録の出現順序をチェック（古い < 中間 < 新しい）
        body = response.body
        old_index = body.index('古い記録')
        middle_index = body.index('中間の記録')
        new_index = body.index('新しい記録')
        
        expect(old_index).to be < middle_index
        expect(middle_index).to be < new_index
      end

      it '降順でソートされること' do
        get gift_records_path, params: { sort_by: 'created_at', sort_order: 'desc' }
        expect(response).to have_http_status(:ok)
        
        # レスポンスから記録の出現順序をチェック（新しい > 中間 > 古い）
        body = response.body
        new_index = body.index('新しい記録')
        middle_index = body.index('中間の記録')
        old_index = body.index('古い記録')
        
        expect(new_index).to be < middle_index
        expect(middle_index).to be < old_index
      end
    end

    context 'お気に入り数順ソート' do
      before do
        # old_recordに3つのお気に入り
        create_list(:favorite, 3, gift_record: old_record)
        # middle_recordに1つのお気に入り
        create_list(:favorite, 1, gift_record: middle_record)
        # new_recordに2つのお気に入り
        create_list(:favorite, 2, gift_record: new_record)
      end

      it '降順でソートされること（お気に入り数: 古い3件 > 新しい2件 > 中間1件）' do
        get gift_records_path, params: { sort_by: 'favorites', sort_order: 'desc' }
        expect(response).to have_http_status(:ok)
        
        body = response.body
        old_index = body.index('古い記録')     # 3件
        new_index = body.index('新しい記録')   # 2件  
        middle_index = body.index('中間の記録') # 1件
        
        expect(old_index).to be < new_index
        expect(new_index).to be < middle_index
      end

      it '昇順でソートされること（お気に入り数: 中間1件 < 新しい2件 < 古い3件）' do
        get gift_records_path, params: { sort_by: 'favorites', sort_order: 'asc' }
        expect(response).to have_http_status(:ok)
        
        body = response.body
        middle_index = body.index('中間の記録') # 1件
        new_index = body.index('新しい記録')   # 2件
        old_index = body.index('古い記録')     # 3件
        
        expect(middle_index).to be < new_index
        expect(new_index).to be < old_index
      end

      context 'お気に入りが0件の記録が含まれる場合' do
        let!(:no_favorite_record) do
          create(:gift_record, 
            user: user1, 
            item_name: 'お気に入りなし',
            is_public: true
          )
        end

        it 'お気に入り0件の記録が最後に表示されること（降順）' do
          get gift_records_path, params: { sort_by: 'favorites', sort_order: 'desc' }
          expect(response).to have_http_status(:ok)
          
          body = response.body
          old_index = body.index('古い記録')         # 3件
          no_favorite_index = body.index('お気に入りなし') # 0件
          
          expect(old_index).to be < no_favorite_index
        end

        it 'お気に入り0件の記録が最初に表示されること（昇順）' do
          get gift_records_path, params: { sort_by: 'favorites', sort_order: 'asc' }
          expect(response).to have_http_status(:ok)
          
          body = response.body
          no_favorite_index = body.index('お気に入りなし') # 0件
          middle_index = body.index('中間の記録')      # 1件
          
          expect(no_favorite_index).to be < middle_index
        end
      end
    end

    context '無効なソートパラメータ' do
      it '無効なsort_byでもエラーにならないこと' do
        get gift_records_path, params: { sort_by: 'invalid' }
        expect(response).to have_http_status(:ok)
      end

      it '無効なsort_orderでもデフォルト（desc）が適用されること' do
        get gift_records_path, params: { sort_by: 'created_at', sort_order: 'invalid' }
        expect(response).to have_http_status(:ok)
        
        # デフォルト（desc）で表示される
        body = response.body
        new_index = body.index('新しい記録')
        old_index = body.index('古い記録')
        
        expect(new_index).to be < old_index
      end
    end

    context '空のデータセット' do
      before do
        GiftRecord.destroy_all
        Favorite.destroy_all
      end

      it '記録が存在しない場合でもエラーにならないこと' do
        get gift_records_path, params: { sort_by: 'favorites' }
        expect(response).to have_http_status(:ok)
      end
    end
  end
end