class AddCommerceConstraints < ActiveRecord::Migration[8.1]
  def change
    change_column_null :products, :seller_id, false
    change_column_null :carts, :buyer_id, false
    change_column_null :orders, :buyer_id, false

    add_index :cart_items,
              %i[cart_id product_id],
              unique: true,
              name: "index_cart_items_on_cart_and_product"

    add_check_constraint :products, "stock >= 0", name: "products_stock_not_negative"
    add_check_constraint :cart_items, "quantity > 0", name: "cart_items_quantity_positive"
  end
end
