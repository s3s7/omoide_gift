require "rails_helper"

RSpec.describe GiftRecordForm, type: :form do
  let(:user) { create(:user) }
  let(:event) { create(:event) }
  let(:relationship) { create(:relationship) }
  let(:existing_gift_person) { create(:gift_person, user: user, relationship: relationship) }

  describe "#save" do
    it "creates a gift record with an existing gift person" do
      form = described_class.new(
        user: user,
        gift_record_params: permitted_gift_record_params,
        gift_person_params: nil,
        gift_direction_default: :given
      )

      expect(form.save).to be(true)
      expect(form.gift_record).to be_persisted
      expect(form.gift_record.user).to eq(user)
      expect(form.gift_record.gift_person).to eq(existing_gift_person)
    end

    it "creates a new gift person when requested" do
      form = described_class.new(
        user: user,
        gift_record_params: permitted_gift_record_params(gift_people_id: "new"),
        gift_person_params: permitted_gift_person_params,
        gift_direction_default: :given
      )

      result = nil
      expect {
        result = form.save
      }.to change(GiftPerson, :count).by(1)

      expect(result).to be(true)
      expect(form.gift_record).to be_persisted
      expect(form.gift_record.gift_person).to eq(form.gift_person)
      expect(form.gift_record.gift_person.user).to eq(user)
    end

    it "exposes validation errors when the new gift person is invalid" do
      form = described_class.new(
        user: user,
        gift_record_params: permitted_gift_record_params(gift_people_id: "new"),
        gift_person_params: permitted_gift_person_params(name: ""),
        gift_direction_default: :given
      )

      expect(form.save).to be(false)
      expect(form.gift_person.errors[:name]).to be_present
      expect(form.gift_record).not_to be_persisted
    end

    it "rolls back the newly created gift person when the gift record is invalid" do
      form = described_class.new(
        user: user,
        gift_record_params: permitted_gift_record_params(gift_people_id: "new", event_id: nil),
        gift_person_params: permitted_gift_person_params,
        gift_direction_default: :given
      )

      result = nil
      expect {
        result = form.save
      }.not_to change(GiftPerson, :count)

      expect(result).to be(false)
      expect(form.gift_record.errors[:event_id]).to be_present
    end

    it "honors a forced gift direction" do
      form = described_class.new(
        user: user,
        gift_record_params: permitted_gift_record_params,
        gift_person_params: nil,
        gift_direction_default: :given,
        forced_gift_direction: :received
      )

      expect(form.save).to be(true)
      expect(form.gift_record).to be_received
    end
  end

  def permitted_gift_record_params(overrides = {})
    params = {
      item_name: "テストギフト",
      gift_at: Date.current,
      event_id: event.id,
      memo: "メモ",
      gift_people_id: existing_gift_person.id
    }.merge(overrides)

    ActionController::Parameters.new(params).permit!
  end

  def permitted_gift_person_params(overrides = {})
    params = {
      name: "新しい相手",
      relationship_id: relationship.id
    }.merge(overrides)

    ActionController::Parameters.new(params).permit!
  end
end
