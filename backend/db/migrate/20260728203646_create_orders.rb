class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.string :customer_name
      t.string :customer_email
      t.text :customer_address
      t.decimal :total_amount, precision: 10, scale: 2, default: 0.0
      t.string :coupon_code
      t.decimal :discount_amount, precision: 10, scale: 2, default: 0.0
      t.decimal :final_amount, precision: 10, scale: 2, default: 0.0
      t.string :status, default: "pending"

      t.timestamps
    end
  end
end
