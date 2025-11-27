# frozen_string_literal: true

require "rails_helper"

RSpec.describe CategoryModerator do
  describe "validations" do
    subject { build(:category_moderator) }

    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:category_id).with_message("is already a moderator of this category") }
  end

  describe "associations" do
    it { is_expected.to belong_to(:category) }
    it { is_expected.to belong_to(:user) }
  end
end
