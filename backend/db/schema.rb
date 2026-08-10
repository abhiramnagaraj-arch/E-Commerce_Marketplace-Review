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

ActiveRecord::Schema[8.1].define(version: 2026_08_10_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "cart_items", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.integer "quantity"
    t.datetime "updated_at", null: false
    t.index ["cart_id", "product_id"], name: "index_cart_items_on_cart_and_product", unique: true
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["product_id"], name: "index_cart_items_on_product_id"
    t.check_constraint "quantity > 0", name: "cart_items_quantity_positive"
  end

  create_table "carts", force: :cascade do |t|
    t.bigint "buyer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["buyer_id"], name: "index_carts_on_buyer_id", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "order_items", force: :cascade do |t|
    t.text "cancel_reason"
    t.datetime "canceled_at"
    t.datetime "created_at", null: false
    t.decimal "discount_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "final_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.bigint "order_id", null: false
    t.decimal "price", precision: 10, scale: 2
    t.bigint "product_id", null: false
    t.string "product_title", null: false
    t.integer "quantity", default: 1
    t.datetime "rejected_at"
    t.text "rejection_reason"
    t.bigint "seller_order_id", null: false
    t.string "status", default: "confirmed", null: false
    t.decimal "subtotal", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
    t.index ["seller_order_id"], name: "index_order_items_on_seller_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "buyer_id", null: false
    t.text "cancel_reason"
    t.datetime "canceled_at"
    t.datetime "created_at", null: false
    t.text "customer_address"
    t.string "customer_email"
    t.string "customer_name"
    t.decimal "discount_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "final_amount", precision: 10, scale: 2, default: "0.0"
    t.string "promotion_code"
    t.bigint "promotion_id"
    t.string "promotion_kind"
    t.string "promotion_name"
    t.string "status", default: "confirmed"
    t.decimal "total_amount", precision: 10, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
    t.index ["buyer_id", "promotion_id"], name: "one_coupon_use_per_buyer", unique: true, where: "((promotion_id IS NOT NULL) AND ((promotion_kind)::text = 'coupon'::text))"
    t.index ["buyer_id"], name: "index_orders_on_buyer_id"
    t.index ["promotion_id"], name: "index_orders_on_promotion_id"
  end

  create_table "products", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "brand"
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2
    t.bigint "seller_id", null: false
    t.jsonb "specifications", default: {}, null: false
    t.integer "stock", default: 0
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["seller_id"], name: "index_products_on_seller_id"
    t.check_constraint "stock >= 0", name: "products_stock_not_negative"
  end

  create_table "promotion_tiers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "discount_percent", null: false
    t.decimal "minimum_value", precision: 10, scale: 2
    t.bigint "promotion_id", null: false
    t.datetime "updated_at", null: false
    t.index ["promotion_id", "minimum_value"], name: "unique_promotion_tiers", unique: true
    t.index ["promotion_id"], name: "index_promotion_tiers_on_promotion_id"
    t.check_constraint "discount_percent >= 1 AND discount_percent <= 100", name: "promotion_tiers_percent_range"
    t.check_constraint "minimum_value >= 0::numeric", name: "promotion_tiers_minimum_nonnegative"
  end

  create_table "promotions", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.bigint "category_id"
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "ends_at"
    t.integer "kind", default: 0, null: false
    t.string "name", null: false
    t.bigint "product_id"
    t.bigint "seller_id"
    t.datetime "starts_at"
    t.datetime "updated_at", null: false
    t.index "lower((code)::text)", name: "index_promotions_on_lower_code", unique: true, where: "(code IS NOT NULL)"
    t.index ["category_id"], name: "index_promotions_on_category_id"
    t.index ["product_id"], name: "index_promotions_on_product_id"
    t.index ["seller_id"], name: "index_promotions_on_seller_id"
    t.check_constraint "ends_at IS NULL OR starts_at IS NULL OR ends_at > starts_at", name: "promotions_valid_dates"
    t.check_constraint "kind = 0 AND code IS NOT NULL AND product_id IS NULL AND category_id IS NULL AND seller_id IS NULL OR kind = 1 AND code IS NULL AND product_id IS NOT NULL AND category_id IS NULL AND seller_id IS NULL OR kind = 2 AND code IS NULL AND product_id IS NULL AND category_id IS NOT NULL AND seller_id IS NULL OR kind = 3 AND code IS NULL AND product_id IS NULL AND category_id IS NULL AND seller_id IS NOT NULL AND starts_at IS NOT NULL AND ends_at IS NOT NULL", name: "promotions_valid_target"
  end

  create_table "seller_orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "order_id", null: false
    t.bigint "seller_id", null: false
    t.string "status", default: "confirmed", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id", "seller_id"], name: "index_seller_orders_on_order_id_and_seller_id", unique: true
    t.index ["order_id"], name: "index_seller_orders_on_order_id"
    t.index ["seller_id"], name: "index_seller_orders_on_seller_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "products"
  add_foreign_key "carts", "users", column: "buyer_id"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "order_items", "seller_orders"
  add_foreign_key "orders", "promotions"
  add_foreign_key "orders", "users", column: "buyer_id"
  add_foreign_key "products", "categories"
  add_foreign_key "products", "users", column: "seller_id"
  add_foreign_key "promotion_tiers", "promotions"
  add_foreign_key "promotions", "categories"
  add_foreign_key "promotions", "products"
  add_foreign_key "promotions", "users", column: "seller_id"
  add_foreign_key "seller_orders", "orders"
  add_foreign_key "seller_orders", "users", column: "seller_id"
end
