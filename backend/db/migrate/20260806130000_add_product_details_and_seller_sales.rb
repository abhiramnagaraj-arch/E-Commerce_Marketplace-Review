class AddProductDetailsAndSellerSales < ActiveRecord::Migration[8.1]
  def up
    add_column :products, :specifications, :text
    add_reference :promotions, :seller, foreign_key: { to_table: :users }

    execute <<~SQL
      UPDATE promotions
      SET seller_id = (
        SELECT seller_id
        FROM products
        ORDER BY id
        LIMIT 1
      )
      WHERE kind = 3
    SQL

    execute <<~SQL
      UPDATE promotions
      SET name = users.name || ' Store Sale'
      FROM users
      WHERE promotions.kind = 3
        AND promotions.seller_id = users.id
    SQL

    remove_check_constraint :promotions, name: "promotions_valid_target"
    add_check_constraint :promotions, <<~SQL.squish, name: "promotions_valid_target"
      kind = 0 AND code IS NOT NULL AND product_id IS NULL AND category_id IS NULL AND seller_id IS NULL OR
      kind = 1 AND code IS NULL AND product_id IS NOT NULL AND category_id IS NULL AND seller_id IS NULL OR
      kind = 2 AND code IS NULL AND product_id IS NULL AND category_id IS NOT NULL AND seller_id IS NULL OR
      kind = 3 AND code IS NULL AND product_id IS NULL AND category_id IS NULL AND seller_id IS NOT NULL AND starts_at IS NOT NULL AND ends_at IS NOT NULL
    SQL
  end

  def down
    remove_check_constraint :promotions, name: "promotions_valid_target"
    add_check_constraint :promotions, <<~SQL.squish, name: "promotions_valid_target"
      kind = 0 AND code IS NOT NULL AND product_id IS NULL AND category_id IS NULL OR
      kind = 1 AND code IS NULL AND product_id IS NOT NULL AND category_id IS NULL OR
      kind = 2 AND code IS NULL AND product_id IS NULL AND category_id IS NOT NULL OR
      kind = 3 AND code IS NULL AND product_id IS NULL AND category_id IS NULL AND starts_at IS NOT NULL AND ends_at IS NOT NULL
    SQL

    remove_reference :promotions, :seller, foreign_key: true
    remove_column :products, :specifications
  end
end
