class AddQaWizardPromptToSpaces < ActiveRecord::Migration[8.1]
  def change
    add_column :spaces, :qa_wizard_prompt, :text
  end
end
