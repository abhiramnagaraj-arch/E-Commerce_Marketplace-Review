class CleanUpPromotions < ActiveRecord::Migration[8.1]
  def up
    execute "DELETE FROM promotion_tiers"
    execute "DELETE FROM promotions"

    remove_index :promotion_tiers, name: "unique_quantity_tiers"
    remove_index :promotion_tiers, name: "unique_amount_tiers"
    remove_column :promotion_tiers, :minimum_quantity
    rename_column :promotion_tiers, :minimum_amount, :minimum_value

    add_index :promotion_tiers,
      [ :promotion_id, :minimum_value ],
      unique: true,
      name: "unique_promotion_tiers"

    remove_column :promotions, :discount_percent
    remove_column :promotions, :min_order_amount
    remove_column :promotions, :ladder_basis
    change_column_null :promotions, :active, false

    add_reference :orders, :promotion, foreign_key: true

    add_index :orders,
      [ :buyer_id, :promotion_id ],
      unique: true,
      where: "promotion_id IS NOT NULL AND promotion_kind = 'coupon'",
      name: "one_coupon_use_per_buyer"

    add_check_constraint :promotion_tiers,
      "minimum_value >= 0",
      name: "promotion_tiers_minimum_nonnegative"

    add_check_constraint :promotion_tiers,
      "discount_percent BETWEEN 1 AND 100",
      name: "promotion_tiers_percent_range"

    add_check_constraint :promotions,
      "ends_at IS NULL OR starts_at IS NULL OR ends_at > starts_at",
      name: "promotions_valid_dates"

    add_check_constraint :promotions, <<~SQL.squish, name: "promotions_valid_target"
      (kind = 0 AND code IS NOT NULL AND product_id IS NULL AND category_id IS NULL) OR
      (kind = 1 AND code IS NULL AND product_id IS NOT NULL AND category_id IS NULL) OR
      (kind = 2 AND code IS NULL AND product_id IS NULL AND category_id IS NOT NULL) OR
      (kind = 3 AND code IS NULL AND product_id IS NULL AND category_id IS NULL AND starts_at IS NOT NULL AND ends_at IS NOT NULL)
    SQL
  end

  def down
    remove_check_constraint :promotions, name: "promotions_valid_target"
    remove_check_constraint :promotions, name: "promotions_valid_dates"
    remove_check_constraint :promotion_tiers, name: "promotion_tiers_percent_range"
    remove_check_constraint :promotion_tiers, name: "promotion_tiers_minimum_nonnegative"

    remove_index :orders, name: "one_coupon_use_per_buyer"
    remove_reference :orders, :promotion, foreign_key: true

    add_column :promotions, :ladder_basis, :integer, default: 1, null: false
    add_column :promotions, :min_order_amount, :decimal, precision: 10, scale: 2, default: 0
    add_column :promotions, :discount_percent, :integer, default: 0

    remove_index :promotion_tiers, name: "unique_promotion_tiers"
    rename_column :promotion_tiers, :minimum_value, :minimum_amount
    add_column :promotion_tiers, :minimum_quantity, :integer

    add_index :promotion_tiers,
      [ :promotion_id, :minimum_quantity ],
      unique: true,
      where: "minimum_quantity IS NOT NULL",
      name: "unique_quantity_tiers"

    add_index :promotion_tiers,
      [ :promotion_id, :minimum_amount ],
      unique: true,
      where: "minimum_amount IS NOT NULL",
      name: "unique_amount_tiers"
  end
end
