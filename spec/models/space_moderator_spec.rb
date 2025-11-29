# frozen_string_literal: true

require "rails_helper"

RSpec.describe SpaceModerator do
  describe "validations" do
    subject { build(:space_moderator) }

    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:space_id).with_message("is already a moderator of this space") }
  end

  describe "associations" do
    it { is_expected.to belong_to(:space) }
    it { is_expected.to belong_to(:user) }
  end
end
