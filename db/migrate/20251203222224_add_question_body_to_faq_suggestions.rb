class AddQuestionBodyToFaqSuggestions < ActiveRecord::Migration[8.1]
  def change
    add_column :faq_suggestions, :question_body, :text
  end
end
