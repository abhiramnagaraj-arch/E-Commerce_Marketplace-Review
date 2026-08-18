class MoveCancellationDetailsToOrderItems < ActiveRecord::Migration[8.1]
  def change
    add_column :order_items, :cancel_reason, :text

    reversible do |direction|
      direction.up do
        execute <<~SQL
          UPDATE order_items
          SET cancel_reason = COALESCE(orders.cancel_reason, 'Order canceled')
          FROM orders
          WHERE order_items.order_id = orders.id
            AND order_items.status = 'canceled'
        SQL
      end
    end

    remove_column :seller_orders, :rejection_reason, :text
    remove_column :seller_orders, :rejected_at, :datetime
  end
end
