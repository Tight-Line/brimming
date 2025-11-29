# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_11_29_220653) do
  create_schema "brimming", if_not_exists: true

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "brimming.answers", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.datetime "edited_at"
    t.boolean "is_correct", default: false, null: false
    t.bigint "last_editor_id"
    t.bigint "question_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "vote_score", default: 0, null: false
    t.index ["last_editor_id"], name: "index_answers_on_last_editor_id"
    t.index ["question_id", "is_correct"], name: "index_answers_on_question_id_and_is_correct"
    t.index ["question_id", "vote_score"], name: "index_answers_on_question_id_and_vote_score"
    t.index ["question_id"], name: "index_answers_on_question_id"
    t.index ["user_id"], name: "index_answers_on_user_id"
    t.index ["vote_score"], name: "index_answers_on_vote_score"
  end

  create_table "brimming.comment_votes", force: :cascade do |t|
    t.bigint "comment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["comment_id"], name: "index_comment_votes_on_comment_id"
    t.index ["user_id", "comment_id"], name: "index_comment_votes_on_user_id_and_comment_id", unique: true
    t.index ["user_id"], name: "index_comment_votes_on_user_id"
  end

  create_table "brimming.comments", force: :cascade do |t|
    t.text "body", null: false
    t.bigint "commentable_id", null: false
    t.string "commentable_type", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.datetime "edited_at"
    t.bigint "last_editor_id"
    t.bigint "parent_comment_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "vote_score", default: 0, null: false
    t.index ["commentable_type", "commentable_id", "created_at"], name: "index_comments_on_commentable_and_created_at"
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
    t.index ["last_editor_id"], name: "index_comments_on_last_editor_id"
    t.index ["parent_comment_id"], name: "index_comments_on_parent_comment_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "brimming.ldap_group_mapping_spaces", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "ldap_group_mapping_id", null: false
    t.bigint "space_id", null: false
    t.datetime "updated_at", null: false
    t.index ["ldap_group_mapping_id", "space_id"], name: "idx_ldap_group_mapping_spaces_unique", unique: true
    t.index ["ldap_group_mapping_id"], name: "index_ldap_group_mapping_spaces_on_ldap_group_mapping_id"
    t.index ["space_id"], name: "index_ldap_group_mapping_spaces_on_space_id"
  end

  create_table "brimming.ldap_group_mappings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "group_pattern", null: false
    t.bigint "ldap_server_id", null: false
    t.string "pattern_type", default: "exact", null: false
    t.datetime "updated_at", null: false
    t.index ["ldap_server_id", "group_pattern"], name: "index_ldap_group_mappings_on_ldap_server_id_and_group_pattern", unique: true
    t.index ["ldap_server_id"], name: "index_ldap_group_mappings_on_ldap_server_id"
  end

  create_table "brimming.ldap_servers", force: :cascade do |t|
    t.string "bind_dn"
    t.string "bind_password"
    t.datetime "created_at", null: false
    t.string "email_attribute", default: "mail", null: false
    t.boolean "enabled", default: true, null: false
    t.string "encryption", default: "plain", null: false
    t.string "group_search_base"
    t.string "group_search_filter", default: "(member=%{dn})"
    t.string "host", null: false
    t.string "name", null: false
    t.string "name_attribute", default: "cn"
    t.integer "port", default: 389, null: false
    t.string "uid_attribute", default: "uid", null: false
    t.datetime "updated_at", null: false
    t.string "user_search_base", null: false
    t.string "user_search_filter", default: "(uid=%{username})"
    t.index ["enabled"], name: "index_ldap_servers_on_enabled"
    t.index ["name"], name: "index_ldap_servers_on_name", unique: true
  end

  create_table "brimming.question_votes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "question_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "value", null: false
    t.index ["question_id"], name: "index_question_votes_on_question_id"
    t.index ["user_id", "question_id"], name: "index_question_votes_on_user_id_and_question_id", unique: true
    t.index ["user_id"], name: "index_question_votes_on_user_id"
  end

  create_table "brimming.questions", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.datetime "edited_at"
    t.bigint "last_editor_id"
    t.string "slug"
    t.bigint "space_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "views_count", default: 0, null: false
    t.integer "vote_score", default: 0, null: false
    t.index ["created_at"], name: "index_questions_on_created_at"
    t.index ["last_editor_id"], name: "index_questions_on_last_editor_id"
    t.index ["slug"], name: "index_questions_on_slug", unique: true
    t.index ["space_id", "created_at"], name: "index_questions_on_space_id_and_created_at"
    t.index ["space_id"], name: "index_questions_on_space_id"
    t.index ["user_id"], name: "index_questions_on_user_id"
    t.index ["views_count"], name: "index_questions_on_views_count"
    t.index ["vote_score"], name: "index_questions_on_vote_score"
  end

  create_table "brimming.space_moderators", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "space_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["space_id", "user_id"], name: "index_space_moderators_on_space_id_and_user_id", unique: true
    t.index ["space_id"], name: "index_space_moderators_on_space_id"
    t.index ["user_id"], name: "index_space_moderators_on_user_id"
  end

  create_table "brimming.space_opt_outs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "ldap_group_mapping_id", null: false
    t.bigint "space_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["ldap_group_mapping_id"], name: "index_space_opt_outs_on_ldap_group_mapping_id"
    t.index ["space_id"], name: "index_space_opt_outs_on_space_id"
    t.index ["user_id", "space_id", "ldap_group_mapping_id"], name: "idx_space_opt_outs_unique", unique: true
    t.index ["user_id"], name: "index_space_opt_outs_on_user_id"
  end

  create_table "brimming.space_subscriptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "space_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["space_id"], name: "index_space_subscriptions_on_space_id"
    t.index ["user_id", "space_id"], name: "index_space_subscriptions_on_user_id_and_space_id", unique: true
    t.index ["user_id"], name: "index_space_subscriptions_on_user_id"
  end

  create_table "brimming.spaces", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_spaces_on_name", unique: true
    t.index ["slug"], name: "index_spaces_on_slug", unique: true
  end

  create_table "brimming.users", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "full_name"
    t.string "ldap_dn"
    t.string "provider"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.string "uid"
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "brimming.votes", force: :cascade do |t|
    t.bigint "answer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "value", null: false
    t.index ["answer_id"], name: "index_votes_on_answer_id"
    t.index ["user_id", "answer_id"], name: "index_votes_on_user_id_and_answer_id", unique: true
    t.index ["user_id"], name: "index_votes_on_user_id"
  end

  add_foreign_key "brimming.answers", "brimming.questions"
  add_foreign_key "brimming.answers", "brimming.users"
  add_foreign_key "brimming.answers", "brimming.users", column: "last_editor_id"
  add_foreign_key "brimming.comment_votes", "brimming.comments"
  add_foreign_key "brimming.comment_votes", "brimming.users"
  add_foreign_key "brimming.comments", "brimming.comments", column: "parent_comment_id"
  add_foreign_key "brimming.comments", "brimming.users"
  add_foreign_key "brimming.comments", "brimming.users", column: "last_editor_id"
  add_foreign_key "brimming.ldap_group_mapping_spaces", "brimming.ldap_group_mappings"
  add_foreign_key "brimming.ldap_group_mapping_spaces", "brimming.spaces"
  add_foreign_key "brimming.ldap_group_mappings", "brimming.ldap_servers"
  add_foreign_key "brimming.question_votes", "brimming.questions"
  add_foreign_key "brimming.question_votes", "brimming.users"
  add_foreign_key "brimming.questions", "brimming.spaces"
  add_foreign_key "brimming.questions", "brimming.users"
  add_foreign_key "brimming.questions", "brimming.users", column: "last_editor_id"
  add_foreign_key "brimming.space_moderators", "brimming.spaces"
  add_foreign_key "brimming.space_moderators", "brimming.users"
  add_foreign_key "brimming.space_opt_outs", "brimming.ldap_group_mappings"
  add_foreign_key "brimming.space_opt_outs", "brimming.spaces"
  add_foreign_key "brimming.space_opt_outs", "brimming.users"
  add_foreign_key "brimming.space_subscriptions", "brimming.spaces"
  add_foreign_key "brimming.space_subscriptions", "brimming.users"
  add_foreign_key "brimming.votes", "brimming.answers"
  add_foreign_key "brimming.votes", "brimming.users"

end
