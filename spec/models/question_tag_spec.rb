# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuestionTag do
  describe "validations" do
    describe "uniqueness" do
      it "validates uniqueness of question_id scoped to tag_id" do
        space = create(:space)
        question = create(:question, space: space)
        tag = create(:tag, space: space)
        create(:question_tag, question: question, tag: tag)

        duplicate = build(:question_tag, question: question, tag: tag)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:question_id]).to include("already has this tag")
      end
    end

    it "validates tag belongs to same space as question" do
      space1 = create(:space)
      space2 = create(:space)
      question = create(:question, space: space1)
      tag = create(:tag, space: space2)

      question_tag = build(:question_tag, question: question, tag: tag)
      expect(question_tag).not_to be_valid
      expect(question_tag.errors[:tag]).to include("must belong to the same space as the question")
    end

    it "allows tag from the same space" do
      space = create(:space)
      question = create(:question, space: space)
      tag = create(:tag, space: space)

      question_tag = build(:question_tag, question: question, tag: tag)
      expect(question_tag).to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:question) }
    it { is_expected.to belong_to(:tag).counter_cache(:questions_count) }
  end
end
