class AddFulfillmentToOrderItems < ActiveRecord::Migration[8.1]
  def up
    add_column :order_items, :status, :string, default: "confirmed", null: false
    add_column :order_items, :rejection_reason, :text
    add_column :order_items, :rejected_at, :datetime
    add_column :order_items, :canceled_at, :datetime

    execute <<~SQL
      UPDATE order_items
      SET status = seller_orders.status,
          rejection_reason = seller_orders.rejection_reason,
          rejected_at = seller_orders.rejected_at
      FROM seller_orders
      WHERE order_items.seller_order_id = seller_orders.id
    SQL

    execute <<~SQL
      UPDATE order_items
      SET canceled_at = orders.canceled_at
      FROM orders
      WHERE order_items.order_id = orders.id
        AND order_items.status = 'canceled'
    SQL
  end

  def down
    remove_column :order_items, :canceled_at
    remove_column :order_items, :rejected_at
    remove_column :order_items, :rejection_reason
    remove_column :order_items, :status
  end
end
