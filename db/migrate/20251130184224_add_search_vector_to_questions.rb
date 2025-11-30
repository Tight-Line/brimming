# frozen_string_literal: true

class AddSearchVectorToQuestions < ActiveRecord::Migration[8.1]
  def up
    # Add tsvector column for full-text search
    add_column :questions, :search_vector, :tsvector

    # Create GIN index for fast full-text search
    add_index :questions, :search_vector, using: :gin, name: "index_questions_on_search_vector"

    # Create a function to build the search vector from question + answers
    execute <<-SQL
      CREATE OR REPLACE FUNCTION questions_search_vector_update() RETURNS trigger AS $$
      DECLARE
        answer_text TEXT;
      BEGIN
        -- Aggregate all answer bodies for this question
        SELECT COALESCE(string_agg(body, ' '), '')
        INTO answer_text
        FROM answers
        WHERE question_id = NEW.id AND deleted_at IS NULL;

        -- Build the search vector with weights:
        -- A = title (highest weight)
        -- B = question body
        -- C = answer content
        NEW.search_vector :=
          setweight(to_tsvector('english', COALESCE(NEW.title, '')), 'A') ||
          setweight(to_tsvector('english', COALESCE(NEW.body, '')), 'B') ||
          setweight(to_tsvector('english', answer_text), 'C');

        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    # Create trigger to auto-update search vector on question changes
    execute <<-SQL
      CREATE TRIGGER questions_search_vector_trigger
      BEFORE INSERT OR UPDATE OF title, body ON questions
      FOR EACH ROW
      EXECUTE FUNCTION questions_search_vector_update();
    SQL

    # Populate search vectors for existing questions
    execute <<-SQL
      UPDATE questions SET search_vector =
        setweight(to_tsvector('english', COALESCE(title, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(body, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE((
          SELECT string_agg(body, ' ')
          FROM answers
          WHERE question_id = questions.id AND deleted_at IS NULL
        ), '')), 'C');
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS questions_search_vector_trigger ON questions"
    execute "DROP FUNCTION IF EXISTS questions_search_vector_update()"
    remove_index :questions, name: "index_questions_on_search_vector"
    remove_column :questions, :search_vector
  end
end
