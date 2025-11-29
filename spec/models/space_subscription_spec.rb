# frozen_string_literal: true

require "rails_helper"

RSpec.describe SpaceSubscription do
  describe "validations" do
    subject { build(:space_subscription) }

    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:space_id).with_message("is already subscribed to this space") }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:space) }
  end
end
