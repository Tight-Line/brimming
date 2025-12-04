# frozen_string_literal: true

class AddSponsoredByToQuestionsAndAnswers < ActiveRecord::Migration[8.1]
  def change
    add_reference :questions, :sponsored_by, foreign_key: { to_table: :users }
    add_reference :answers, :sponsored_by, foreign_key: { to_table: :users }
  end
end
