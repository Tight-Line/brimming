class AddSimilarQuestionsLimitToSpaces < ActiveRecord::Migration[8.1]
  def change
    add_column :spaces, :similar_questions_limit, :integer
  end
end
