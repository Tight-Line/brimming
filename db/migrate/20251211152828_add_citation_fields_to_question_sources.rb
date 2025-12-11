class AddCitationFieldsToQuestionSources < ActiveRecord::Migration[8.1]
  def change
    add_column :question_sources, :citation_number, :integer
    add_column :question_sources, :source_title, :string
  end
end
