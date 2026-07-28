class ProductsController < ApplicationController
  before_action :set_product, only: %i[ show edit update destroy ]

  def index
    if params[:category_id].present?
      @category = Category.find(params[:category_id])
      @products = @category.products.order(created_at: :desc)
    else
      @products = Product.includes(:category).order(created_at: :desc)
    end
    @categories = Category.order(:name)
  end

  def show
  end

  def new
    @product = Product.new
    @categories = Category.order(:name)
  end

  def edit
    @categories = Category.order(:name)
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to @product, notice: "Product was successfully created."
    else
      @categories = Category.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @product.update(product_params)
      redirect_to @product, notice: "Product was successfully updated."
    else
      @categories = Category.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    redirect_to products_url, notice: "Product was successfully deleted."
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:title, :description, :price, :stock, :category_id)
  end
end
