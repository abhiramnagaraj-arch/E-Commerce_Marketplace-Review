class AddOwnershipToCommerceRecords < ActiveRecord::Migration[8.1]
  def change
    add_reference :products, :seller, foreign_key: { to_table: :users }
    add_reference :orders, :buyer, foreign_key: { to_table: :users }
    add_reference :carts, :buyer, index: { unique: true }, foreign_key: { to_table: :users }
  end
end
