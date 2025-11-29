# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationPolicy do
  let(:user) { create(:user) }
  let(:record) { double("record") }

  subject { described_class.new(user, record) }

  describe "default permissions" do
    it "denies index by default" do
      expect(subject.index?).to be false
    end

    it "denies show by default" do
      expect(subject.show?).to be false
    end

    it "denies create by default" do
      expect(subject.create?).to be false
    end

    it "denies update by default" do
      expect(subject.update?).to be false
    end

    it "denies destroy by default" do
      expect(subject.destroy?).to be false
    end
  end

  describe "aliased methods" do
    it "new? delegates to create?" do
      expect(subject.new?).to eq(subject.create?)
    end

    it "edit? delegates to update?" do
      expect(subject.edit?).to eq(subject.update?)
    end
  end

  describe "Scope" do
    it "raises error when resolve is not implemented" do
      scope = described_class::Scope.new(user, User)
      expect { scope.resolve }.to raise_error(NoMethodError, /You must define #resolve/)
    end
  end
end
