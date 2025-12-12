class AddRagChunkLimitToSpaces < ActiveRecord::Migration[8.1]
  def change
    add_column :spaces, :rag_chunk_limit, :integer
  end
end
