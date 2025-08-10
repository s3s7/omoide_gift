require 'rails_helper'

RSpec.describe 'フィルタースコープ', type: :model do
  let(:user) { create(:user) }
  
  describe 'GiftRecord.by_date_range' do
    let!(:target_record) { create(:gift_record, user: user, gift_at: 1.week.ago) }
    let!(:outside_record) { create(:gift_record, user: user, gift_at: 1.month.ago) }

    it '期間内記録を取得' do
      results = GiftRecord.by_date_range(2.weeks.ago, Date.current)
      
      expect(results).to include(target_record)
      expect(results).not_to include(outside_record)
    end
  end

  describe 'GiftRecord.by_gift_person' do
    let(:person1) { create(:gift_person, user: user) }
    let(:person2) { create(:gift_person, user: user) }
    let!(:record1) { create(:gift_record, user: user, gift_people_id: person1.id) }
    let!(:record2) { create(:gift_record, user: user, gift_people_id: person2.id) }

    it '指定相手の記録のみ取得' do
      results = GiftRecord.by_gift_person(person1.id)
      
      expect(results).to include(record1)
      expect(results).not_to include(record2)
    end
  end

  describe 'Event.frequently_used' do
    let(:popular_event) { create(:event) }
    let(:rare_event) { create(:event) }
    
    before do
      create_list(:gift_record, 3, user: user, event: popular_event)
      create_list(:gift_record, 1, user: user, event: rare_event)
    end

    it '使用頻度順で取得' do
      results = Event.frequently_used.limit(2)
      
      expect(results.first).to eq(popular_event)
      expect(results.second).to eq(rare_event)
    end
  end

  describe 'Relationship.active' do
    let!(:valid_rel) { create(:relationship, name: '友人') }
    let!(:empty_rel) { create(:relationship, name: '') }

    it '有効な関係性のみ取得' do
      results = Relationship.active
      
      expect(results).to include(valid_rel)
      expect(results).not_to include(empty_rel)
    end
  end
end