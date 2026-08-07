  module Seller
    class ProductsController < BaseController
      before_action :set_product, only: %i[show edit update destroy]

      def index
        @products = current_user.products.includes(:category).order(created_at: :desc)
      end

      def new
        @product = current_user.products.build(category_id: params[:category_id])
        load_categories
      end

      def edit
        load_categories
      end

      def create
        @product = current_user.products.build(product_params)
        if @product.save
          redirect_to seller_product_path(@product), notice: "Product was successfully created."
        else
          load_categories
          render :new, status: :unprocessable_entity
        end
      end

      def update
        if @product.update(product_params)
          redirect_to seller_product_path(@product), notice: "Product was successfully updated."
        else
          load_categories
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        if @product.archive
          redirect_to seller_products_path, notice: "Product was archived."
        else
          redirect_to seller_products_path, alert: "Product could not be archived."
        end
      end

      private

      def set_product
        @product = current_user.products.find(params[:id])
      end

      def load_categories
        @categories = Category.order(:name)
      end

      def product_params
        params.require(:product).permit(:title, :description, :specifications, :price, :stock, :category_id, :active)
      end
    end
  end
