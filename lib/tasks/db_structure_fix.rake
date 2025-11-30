# frozen_string_literal: true

# Post-process structure.sql to ensure idempotent schema/extension creation.
# pg_dump outputs CREATE SCHEMA without IF NOT EXISTS, which causes errors
# when running db:migrate on an existing database.
# pg_dump also sometimes omits CREATE EXTENSION statements entirely.

namespace :db do
  namespace :structure do
    desc "Fix structure.sql to use IF NOT EXISTS for schemas and extensions"
    task fix: :environment do
      structure_file = Rails.root.join("db", "structure.sql")
      next unless File.exist?(structure_file)

      content = File.read(structure_file)
      modified = false

      # Fix CREATE SCHEMA statements (but not ones that already have IF NOT EXISTS)
      if content.match?(/^CREATE SCHEMA (?!IF NOT EXISTS)(\w+);/m)
        content.gsub!(/^CREATE SCHEMA (?!IF NOT EXISTS)(\w+);/m, 'CREATE SCHEMA IF NOT EXISTS \1;')
        modified = true
      end

      # Fix CREATE EXTENSION statements (but not ones that already have IF NOT EXISTS)
      if content.match?(/^CREATE EXTENSION (?!IF NOT EXISTS)/m)
        content.gsub!(/^CREATE EXTENSION (?!IF NOT EXISTS)(\w+)/m, 'CREATE EXTENSION IF NOT EXISTS \1')
        modified = true
      end

      # Ensure required extensions are present
      # pg_dump sometimes omits CREATE EXTENSION when dumping
      extensions_to_ensure = []

      # Check if vector extension is needed (used for embeddings)
      if content.match?(/\bpublic\.vector\b/) && !content.include?("CREATE EXTENSION IF NOT EXISTS vector")
        extensions_to_ensure << {
          name: "vector",
          comment: "vector data type and ivfflat and hnsw access methods"
        }
      end

      # Check if pg_trgm extension is needed (used for trigram indexes)
      if content.match?(/\bpublic\.gin_trgm_ops\b/) && !content.include?("CREATE EXTENSION IF NOT EXISTS pg_trgm")
        extensions_to_ensure << {
          name: "pg_trgm",
          comment: "text similarity measurement and index searching based on trigrams"
        }
      end

      if extensions_to_ensure.any?
        extension_sql = extensions_to_ensure.map do |ext|
          <<~SQL

            --
            -- Name: #{ext[:name]}; Type: EXTENSION; Schema: -; Owner: -
            --

            CREATE EXTENSION IF NOT EXISTS #{ext[:name]} WITH SCHEMA public;


            --
            -- Name: EXTENSION #{ext[:name]}; Type: COMMENT; Schema: -; Owner: -
            --

            COMMENT ON EXTENSION #{ext[:name]} IS '#{ext[:comment]}';

          SQL
        end.join("\n")

        # Insert before SET default_tablespace
        if content.include?("SET default_tablespace = '';")
          content.sub!("SET default_tablespace = '';", "#{extension_sql}\nSET default_tablespace = '';")
          modified = true
        end
      end

      if modified
        File.write(structure_file, content)
        puts "Fixed structure.sql: Added IF NOT EXISTS to schema/extension statements"
      end
    end
  end
end

# Hook into db:migrate to automatically fix structure.sql after each migration
Rake::Task["db:migrate"].enhance do
  Rake::Task["db:structure:fix"].invoke if File.exist?(Rails.root.join("db", "structure.sql"))
end

# Also hook into db:schema:dump for good measure
if Rake::Task.task_defined?("db:schema:dump")
  Rake::Task["db:schema:dump"].enhance do
    Rake::Task["db:structure:fix"].invoke if File.exist?(Rails.root.join("db", "structure.sql"))
  end
end
