# frozen_string_literal: true

require "rails_helper"

RSpec.describe CategorySubscription do
  describe "validations" do
    subject { build(:category_subscription) }

    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:category_id).with_message("is already subscribed to this category") }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:category) }
  end
end
