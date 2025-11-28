# frozen_string_literal: true

# Patch schema.rb after it's dumped to ensure create_schema uses if_not_exists: true
# This prevents "schema already exists" errors when running db:schema:load

Rake::Task["db:schema:dump"].enhance do
  schema_file = Rails.root.join("db/schema.rb")
  content = File.read(schema_file)

  # Replace create_schema "brimming" with create_schema "brimming", if_not_exists: true
  updated_content = content.gsub(
    /create_schema "brimming"(?!.*if_not_exists)/,
    'create_schema "brimming", if_not_exists: true'
  )

  if content != updated_content
    File.write(schema_file, updated_content)
    puts "Patched schema.rb to use if_not_exists: true for brimming schema"
  end
end
