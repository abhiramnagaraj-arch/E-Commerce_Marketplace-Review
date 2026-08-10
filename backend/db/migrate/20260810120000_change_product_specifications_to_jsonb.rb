class ChangeProductSpecificationsToJsonb < ActiveRecord::Migration[8.1]
  def up
    add_column :products, :new_specifications, :jsonb, default: {}, null: false

    product_model = Class.new(ActiveRecord::Base) do
      self.table_name = "products"
    end
    product_model.reset_column_information

    product_model.find_each do |product|
      specifications = product.specifications.to_s.lines.filter_map do |line|
        key, value = line.strip.split(":", 2)
        [ key.strip, value.strip ] if key.present? && value.present?
      end.to_h

      product.update_column(:new_specifications, specifications)
    end

    remove_column :products, :specifications
    rename_column :products, :new_specifications, :specifications
  end

  def down
    change_column_default :products, :specifications, from: {}, to: nil
    change_column :products, :specifications, :text, using: "specifications::text"
  end
end
