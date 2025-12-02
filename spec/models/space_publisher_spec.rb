# frozen_string_literal: true

require "rails_helper"

RSpec.describe SpacePublisher do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:space) }
  end

  describe "validations" do
    subject { build(:space_publisher) }

    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:space_id).with_message("is already a publisher for this space") }
  end

  describe "uniqueness" do
    it "prevents duplicate publisher assignments" do
      user = create(:user)
      space = create(:space)
      create(:space_publisher, user: user, space: space)

      duplicate = build(:space_publisher, user: user, space: space)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include("is already a publisher for this space")
    end

    it "allows same user to be publisher in different spaces" do
      user = create(:user)
      space1 = create(:space, name: "Space 1")
      space2 = create(:space, name: "Space 2")

      create(:space_publisher, user: user, space: space1)
      publisher2 = build(:space_publisher, user: user, space: space2)

      expect(publisher2).to be_valid
    end
  end
end
