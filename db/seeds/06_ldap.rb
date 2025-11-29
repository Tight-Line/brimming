# frozen_string_literal: true

# =============================================================================
# LDAP Server Configuration (Development)
# =============================================================================
puts "Creating LDAP server configuration..."

# Only create if LdapServer model exists (Phase 8)
if defined?(LdapServer)
  ldap_server = LdapServer.find_or_create_by!(name: "Development LDAP") do |server|
    server.host = "openldap"
    server.port = 389
    server.encryption = "plain"
    server.bind_dn = "cn=admin,dc=brimming,dc=local"
    server.bind_password = "admin_secret"
    server.user_search_base = "ou=users,dc=brimming,dc=local"
    server.user_search_filter = "(uid=%{username})"
    server.group_search_base = "ou=groups,dc=brimming,dc=local"
    server.group_search_filter = "(member=%{dn})"
    server.uid_attribute = "uid"
    server.email_attribute = "mail"
    server.name_attribute = "cn"
    server.enabled = true
  end

  puts "  Created LDAP server: #{ldap_server.name}"

  # Create group mappings if LdapGroupMapping model exists
  if defined?(LdapGroupMapping)
    # Map engineering group to Ruby on Rails and Python spaces
    engineering_spaces = Space.where(slug: %w[ruby-on-rails python])
    if engineering_spaces.any?
      eng_mapping = LdapGroupMapping.find_or_create_by!(
        ldap_server: ldap_server,
        group_pattern: "cn=engineering,ou=groups,dc=brimming,dc=local"
      ) do |m|
        m.pattern_type = "exact"
      end
      engineering_spaces.each do |space|
        eng_mapping.spaces << space unless eng_mapping.spaces.include?(space)
      end
      puts "  Created mapping: engineering -> #{engineering_spaces.pluck(:name).join(', ')}"
    end

    # Map devops group to DevOps and Security spaces
    devops_spaces = Space.where(slug: %w[devops security])
    if devops_spaces.any?
      devops_mapping = LdapGroupMapping.find_or_create_by!(
        ldap_server: ldap_server,
        group_pattern: "cn=devops,ou=groups,dc=brimming,dc=local"
      ) do |m|
        m.pattern_type = "exact"
      end
      devops_spaces.each do |space|
        devops_mapping.spaces << space unless devops_mapping.spaces.include?(space)
      end
      puts "  Created mapping: devops -> #{devops_spaces.pluck(:name).join(', ')}"
    end

    # Map design group to JavaScript and Mobile Development spaces
    design_spaces = Space.where(slug: %w[javascript mobile-development])
    if design_spaces.any?
      design_mapping = LdapGroupMapping.find_or_create_by!(
        ldap_server: ldap_server,
        group_pattern: "cn=design,ou=groups,dc=brimming,dc=local"
      ) do |m|
        m.pattern_type = "exact"
      end
      design_spaces.each do |space|
        design_mapping.spaces << space unless design_mapping.spaces.include?(space)
      end
      puts "  Created mapping: design -> #{design_spaces.pluck(:name).join(', ')}"
    end
  end

  puts ""
  puts "LDAP test users (all use password: password123):"
  puts "  jsmith  - John Smith (engineering, managers)"
  puts "  mjones  - Mary Jones (engineering, design)"
  puts "  bwilson - Bob Wilson (engineering, devops)"
  puts "  agarcia - Ana Garcia (design, managers)"
  puts "  dlee    - David Lee (devops)"
else
  puts "  Skipping LDAP setup (LdapServer model not defined)"
end

# =============================================================================
# Summary
# =============================================================================

puts ""
puts "Seeding complete!"
puts "================="
puts "Users: #{User.count}"
puts "  - Admins: #{User.admin.count}"
puts "  - Regular users: #{User.user.count}"
puts "Spaces: #{Space.count}"
puts "  - With questions: #{Space.joins(:questions).distinct.count}"
puts "  - Empty (no questions): #{Space.left_joins(:questions).where(questions: { id: nil }).count}"
puts "Space Moderators: #{SpaceModerator.count}"
puts "Questions: #{Question.count}"
puts "  - With answers: #{Question.joins(:answers).distinct.count}"
puts "  - Unanswered: #{Question.left_joins(:answers).where(answers: { id: nil }).count}"
puts "  - Edited: #{Question.where.not(edited_at: nil).count}"
puts "Answers: #{Answer.count}"
puts "  - Solved: #{Answer.where(is_correct: true).count}"
puts "  - Edited: #{Answer.where.not(edited_at: nil).count}"
puts "Votes: #{Vote.count}"
puts "Comments: #{Comment.count}"
puts "  - On questions: #{Comment.where(commentable_type: 'Question').count}"
puts "  - On answers: #{Comment.where(commentable_type: 'Answer').count}"
puts "  - Top-level: #{Comment.where(parent_comment_id: nil).count}"
puts "  - Replies: #{Comment.where.not(parent_comment_id: nil).count}"
puts "  - Edited: #{Comment.where.not(edited_at: nil).count}"
puts "Comment Votes: #{CommentVote.count}"
puts ""
puts "Login credentials (development only):"
puts "  Email: admin@example.com"
puts "  Password: #{DEFAULT_PASSWORD}"
puts "  (All seed users use the same password)"
if defined?(LdapServer) && LdapServer.any?
  puts ""
  puts "LDAP Servers: #{LdapServer.count}"
  puts "LDAP Group Mappings: #{LdapGroupMapping.count}" if defined?(LdapGroupMapping)
  puts ""
  puts "LDAP login (use username, not email):"
  puts "  Server: Development LDAP"
  puts "  Users: jsmith, mjones, bwilson, agarcia, dlee"
  puts "  Password: password123"
  puts ""
  puts "LDAP Admin UI: http://localhost:38080"
  puts "  Login DN: cn=admin,dc=brimming,dc=local"
  puts "  Password: admin_secret"
end
