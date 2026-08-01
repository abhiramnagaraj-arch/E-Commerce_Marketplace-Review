class AddSellerFulfillment < ActiveRecord::Migration[8.1]
  def up
    create_table :seller_orders do |t|
      t.references :order, null: false, foreign_key: true
      t.references :seller, null: false, foreign_key: { to_table: :users }
      t.string :status, default: "confirmed", null: false
      t.text :rejection_reason
      t.datetime :rejected_at
      t.timestamps
    end

    add_index :seller_orders, %i[order_id seller_id], unique: true
    add_reference :order_items, :seller_order, foreign_key: true
    add_column :orders, :cancel_reason, :text
    add_column :orders, :canceled_at, :datetime

    execute <<~SQL
      INSERT INTO seller_orders (order_id, seller_id, status, created_at, updated_at)
      SELECT DISTINCT order_items.order_id,
                      products.seller_id,
                      CASE
                        WHEN orders.status IN ('confirmed', 'processing', 'shipped', 'delivered', 'canceled')
                          THEN orders.status
                        ELSE 'confirmed'
                      END,
                      orders.created_at,
                      CURRENT_TIMESTAMP
      FROM order_items
      JOIN products ON products.id = order_items.product_id
      JOIN orders ON orders.id = order_items.order_id
    SQL

    execute <<~SQL
      UPDATE order_items
      SET seller_order_id = seller_orders.id
      FROM products, seller_orders
      WHERE products.id = order_items.product_id
        AND seller_orders.order_id = order_items.order_id
        AND seller_orders.seller_id = products.seller_id
    SQL

    change_column_null :order_items, :seller_order_id, false

    execute "UPDATE orders SET status = 'confirmed' WHERE status = 'pending'"
    change_column_default :orders, :status, from: "pending", to: "confirmed"
  end

  def down
    change_column_default :orders, :status, from: "confirmed", to: "pending"
    remove_column :orders, :canceled_at
    remove_column :orders, :cancel_reason
    remove_reference :order_items, :seller_order, foreign_key: true
    drop_table :seller_orders
  end
end
