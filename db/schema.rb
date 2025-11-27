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

ActiveRecord::Schema[8.1].define(version: 2025_11_27_175340) do
  create_schema "brimming"

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "brimming.answers", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.boolean "is_correct", default: false, null: false
    t.bigint "question_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "vote_score", default: 0, null: false
    t.index ["question_id", "is_correct"], name: "index_answers_on_question_id_and_is_correct"
    t.index ["question_id", "vote_score"], name: "index_answers_on_question_id_and_vote_score"
    t.index ["question_id"], name: "index_answers_on_question_id"
    t.index ["user_id"], name: "index_answers_on_user_id"
    t.index ["vote_score"], name: "index_answers_on_vote_score"
  end

  create_table "brimming.categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "brimming.category_moderators", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["category_id", "user_id"], name: "index_category_moderators_on_category_id_and_user_id", unique: true
    t.index ["category_id"], name: "index_category_moderators_on_category_id"
    t.index ["user_id"], name: "index_category_moderators_on_user_id"
  end

  create_table "brimming.questions", force: :cascade do |t|
    t.text "body", null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["category_id", "created_at"], name: "index_questions_on_category_id_and_created_at"
    t.index ["category_id"], name: "index_questions_on_category_id"
    t.index ["created_at"], name: "index_questions_on_created_at"
    t.index ["user_id"], name: "index_questions_on_user_id"
  end

  create_table "brimming.users", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
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
  add_foreign_key "brimming.category_moderators", "brimming.categories"
  add_foreign_key "brimming.category_moderators", "brimming.users"
  add_foreign_key "brimming.questions", "brimming.categories"
  add_foreign_key "brimming.questions", "brimming.users"
  add_foreign_key "brimming.votes", "brimming.answers"
  add_foreign_key "brimming.votes", "brimming.users"

end
