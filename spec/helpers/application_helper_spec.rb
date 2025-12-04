# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper do
  describe "#format_tokens" do
    it "returns exact number for values under 1024" do
      expect(helper.format_tokens(500)).to eq("500")
    end

    it "returns K notation for exact multiples of 1024" do
      expect(helper.format_tokens(1024)).to eq("1K")
      expect(helper.format_tokens(2048)).to eq("2K")
      expect(helper.format_tokens(8192)).to eq("8K")
    end

    it "returns formatted number for non-multiples >= 1024" do
      expect(helper.format_tokens(1500)).to eq("1,500")
      expect(helper.format_tokens(10000)).to eq("10,000")
    end
  end

  describe "#status_badge_class" do
    it "returns warning for pending status" do
      expect(helper.status_badge_class("pending")).to eq("warning")
    end

    it "returns success for approved status" do
      expect(helper.status_badge_class("approved")).to eq("success")
    end

    it "returns secondary for rejected status" do
      expect(helper.status_badge_class("rejected")).to eq("secondary")
    end

    it "returns primary for created status" do
      expect(helper.status_badge_class("created")).to eq("primary")
    end

    it "returns secondary for unknown status" do
      expect(helper.status_badge_class("unknown")).to eq("secondary")
    end

    it "handles symbol input" do
      expect(helper.status_badge_class(:pending)).to eq("warning")
    end
  end
end
