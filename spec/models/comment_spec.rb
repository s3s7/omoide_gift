require 'rails_helper'

RSpec.describe Comment, type: :model do
  let(:user) { create(:user) }
  let(:gift_record) { create(:gift_record, user: user) }
  let(:comment) { create(:comment, user: user, gift_record: gift_record) }

  describe 'セキュリティテスト' do
    context 'XSS攻撃対策' do
      let(:malicious_comment) { create(:comment, :with_special_chars, user: user, gift_record: gift_record) }

      it 'スクリプトタグを含むコメントが保存できる（ビューでエスケープ処理）' do
        expect(malicious_comment).to be_valid
        expect(malicious_comment.body).to include('<script>')
      end
    end
  end

  describe '権限管理' do
    let(:other_user) { create(:user) }
    let(:other_comment) { create(:comment, user: other_user, gift_record: gift_record) }

    describe '#can_edit_or_delete?' do
      it 'コメント投稿者は編集・削除権限を持つ' do
        expect(comment.can_edit_or_delete?(user)).to be true
      end

      it '他のユーザーは編集・削除権限を持たない' do
        expect(other_comment.can_edit_or_delete?(user)).to be false
      end

      it 'nilユーザーは編集・削除権限を持たない' do
        expect(comment.can_edit_or_delete?(nil)).to be false
      end
    end
  end

  describe 'データ整合性' do
    it 'userが削除されるとコメントも削除される' do
      comment_id = comment.id
      user.destroy
      expect(Comment.find_by(id: comment_id)).to be_nil
    end

    it 'gift_recordが削除されるとコメントも削除される' do
      comment_id = comment.id
      gift_record.destroy
      expect(Comment.find_by(id: comment_id)).to be_nil
    end
  end

  describe '基本機能' do
    let(:short_comment) { create(:comment, :short_comment, user: user, gift_record: gift_record) }
    let(:long_comment) { create(:comment, body: "あ" * 60, user: user, gift_record: gift_record) }

    it '短いコメントが正常に保存される' do
      expect(short_comment).to be_valid
      expect(short_comment.body).to eq("短いコメント")
    end

    describe '#excerpt' do
      it '長いコメントを切り詰める' do
        result = long_comment.excerpt
        expect(result.length).to eq(53) # 50文字 + "..."
        expect(result).to end_with("...")
      end

      it '短いコメントはそのまま返す' do
        expect(short_comment.excerpt).to eq(short_comment.body)
      end
    end

    describe '#display_created_at' do
      context '今日のコメント' do
        before { allow(comment).to receive(:created_at).and_return(Time.current) }

        it '時刻のみを表示する' do
          expect(comment.display_created_at).to match(/\d{2}:\d{2}/)
        end
      end

      context '過去のコメント' do
        before { allow(comment).to receive(:created_at).and_return(1.day.ago) }

        it '日付と時刻を表示する' do
          expect(comment.display_created_at).to match(/\d{2}\/\d{2} \d{2}:\d{2}/)
        end
      end
    end
  end
end
