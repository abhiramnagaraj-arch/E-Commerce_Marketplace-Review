class AddCommerceFoundation < ActiveRecord::Migration[8.1]
  def up
    add_column :products, :active, :boolean, default: true, null: false

    add_column :order_items, :product_title, :string
    add_column :order_items, :subtotal, :decimal, precision: 10, scale: 2, default: 0, null: false
    add_column :order_items, :discount_amount, :decimal, precision: 10, scale: 2, default: 0, null: false
    add_column :order_items, :final_amount, :decimal, precision: 10, scale: 2, default: 0, null: false

    execute <<~SQL
      UPDATE order_items
      SET product_title = products.title
      FROM products
      WHERE order_items.product_id = products.id
    SQL

    execute <<~SQL
      UPDATE order_items
      SET subtotal = COALESCE(price, 0) * COALESCE(quantity, 0),
          final_amount = COALESCE(price, 0) * COALESCE(quantity, 0)
    SQL

    change_column_null :order_items, :product_title, false
  end

  def down
    remove_column :order_items, :final_amount
    remove_column :order_items, :discount_amount
    remove_column :order_items, :subtotal
    remove_column :order_items, :product_title
    remove_column :products, :active
  end
end
