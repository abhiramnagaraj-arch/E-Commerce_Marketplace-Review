class AddPromotionTiers < ActiveRecord::Migration[8.1]
  def up
    add_column :promotions, :ladder_basis, :integer, default: 1, null: false

    create_table :promotion_tiers do |t|
      t.references :promotion, null: false, foreign_key: true
      t.integer :minimum_quantity
      t.decimal :minimum_amount, precision: 10, scale: 2
      t.integer :discount_percent, null: false
      t.timestamps
    end

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

    execute "UPDATE promotions SET ladder_basis = 0 WHERE kind IN (1, 2)"

    execute <<~SQL
      INSERT INTO promotion_tiers
        (promotion_id, minimum_quantity, minimum_amount, discount_percent, created_at, updated_at)
      SELECT
        id,
        CASE WHEN kind IN (1, 2) THEN 1 ELSE NULL END,
        CASE WHEN kind IN (0, 3) THEN min_order_amount ELSE NULL END,
        discount_percent,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
      FROM promotions
      WHERE discount_percent > 0
    SQL
  end

  def down
    drop_table :promotion_tiers
    remove_column :promotions, :ladder_basis
  end
end
