# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160830095505) do

  create_table "news", force: :cascade do |t|
    t.string   "source",      limit: 255,        null: false
    t.integer  "sync",        limit: 4
    t.string   "author",      limit: 255
    t.string   "title",       limit: 255
    t.string   "url",         limit: 255
    t.datetime "publish_at"
    t.text     "html",        limit: 4294967295
    t.integer  "is_pic_news", limit: 4
    t.string   "pic_url",     limit: 255
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  create_table "spiders", force: :cascade do |t|
    t.string   "source",     limit: 255, null: false
    t.string   "title",      limit: 255, null: false
    t.string   "url",        limit: 255, null: false
    t.string   "rule",       limit: 255
    t.integer  "status",     limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "tasks", force: :cascade do |t|
    t.string   "source",             limit: 255
    t.datetime "last_item_datetime"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "username",        limit: 255
    t.string   "password_digest", limit: 255
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

end
