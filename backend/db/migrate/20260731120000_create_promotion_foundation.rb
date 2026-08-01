class CreatePromotionFoundation < ActiveRecord::Migration[8.1]
  def up
    rename_table :coupons, :promotions
    rename_column :orders, :coupon_code, :promotion_code

    add_column :promotions, :name, :string
    add_column :promotions, :kind, :integer, default: 0, null: false
    add_reference :promotions, :product, foreign_key: true
    add_reference :promotions, :category, foreign_key: true
    add_column :promotions, :starts_at, :datetime
    add_column :promotions, :ends_at, :datetime

    add_column :orders, :promotion_name, :string
    add_column :orders, :promotion_kind, :string

    execute "UPDATE promotions SET name = code"
    change_column_null :promotions, :name, false

    execute <<~SQL
      UPDATE orders
      SET promotion_name = promotions.name,
          promotion_kind = 'coupon'
      FROM promotions
      WHERE LOWER(orders.promotion_code) = LOWER(promotions.code)
    SQL

    add_index :promotions,
              "LOWER(code)",
              unique: true,
              where: "code IS NOT NULL",
              name: "index_promotions_on_lower_code"
  end

  def down
    remove_index :promotions, name: "index_promotions_on_lower_code"

    remove_column :orders, :promotion_kind
    remove_column :orders, :promotion_name

    remove_column :promotions, :ends_at
    remove_column :promotions, :starts_at
    remove_reference :promotions, :category, foreign_key: true
    remove_reference :promotions, :product, foreign_key: true
    remove_column :promotions, :kind
    remove_column :promotions, :name

    rename_column :orders, :promotion_code, :coupon_code
    rename_table :promotions, :coupons
  end
end
