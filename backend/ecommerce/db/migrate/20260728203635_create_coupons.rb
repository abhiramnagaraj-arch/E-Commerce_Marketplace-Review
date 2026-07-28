class CreateCoupons < ActiveRecord::Migration[8.1]
  def change
    create_table :coupons do |t|
      t.string :code
      t.integer :discount_percent, default: 0
      t.decimal :min_order_amount, precision: 10, scale: 2, default: 0.0
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
