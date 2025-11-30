# frozen_string_literal: true

class EnablePgTrgmExtension < ActiveRecord::Migration[8.1]
  def up
    enable_extension "pg_trgm"

    # GIN trigram index for fast prefix/similarity search on question titles
    execute <<-SQL
      CREATE INDEX index_questions_on_title_trgm
      ON questions
      USING gin (title gin_trgm_ops);
    SQL
  end

  def down
    execute "DROP INDEX IF EXISTS index_questions_on_title_trgm"
    disable_extension "pg_trgm"
  end
end
