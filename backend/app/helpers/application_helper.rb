module ApplicationHelper
  def cart_item_for(product)
    @cart_items_by_product_id ||= current_cart.cart_items.index_by(&:product_id)
    @cart_items_by_product_id[product.id]
  end
end
