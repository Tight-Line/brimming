class AddReaderProviderToArticles < ActiveRecord::Migration[8.1]
  def change
    add_reference :articles, :reader_provider, null: true, foreign_key: true
  end
end
