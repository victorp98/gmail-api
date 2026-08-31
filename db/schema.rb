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

ActiveRecord::Schema[8.1].define(version: 2026_08_31_000000) do
  create_table "mailboxes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.integer "history_sequence", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_mailboxes_on_email", unique: true
  end

  create_table "messages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "external_id", null: false
    t.integer "history_id", null: false
    t.json "labels", default: [], null: false
    t.integer "mailbox_id", null: false
    t.text "raw", null: false
    t.datetime "received_at", null: false
    t.string "thread_id", null: false
    t.datetime "updated_at", null: false
    t.index ["mailbox_id", "external_id"], name: "index_messages_on_mailbox_id_and_external_id", unique: true
    t.index ["mailbox_id", "history_id"], name: "index_messages_on_mailbox_id_and_history_id"
    t.index ["mailbox_id"], name: "index_messages_on_mailbox_id"
  end

  add_foreign_key "messages", "mailboxes"
end
