  module Admin
    class PromotionsController < BaseController
      before_action :set_promotion, only: %i[edit update toggle]
      before_action :load_options, only: %i[new create edit update]

      def index
        @promotions = Promotion.includes(:product, :category, :seller, :tiers).order(created_at: :desc)
      end

      def new
        @promotion = Promotion.new(active: true)
        3.times { @promotion.tiers.build }
      end

      def create
        @promotion = Promotion.new(promotion_params)

        if @promotion.save
          redirect_to admin_promotions_path, notice: "Promotion was created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
        @promotion.tiers.build
      end

      def update
        if @promotion.update(promotion_params)
          redirect_to admin_promotions_path, notice: "Promotion was updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def toggle
        @promotion.toggle_status
        redirect_to admin_promotions_path, notice: "Promotion status was updated."
      end

      private

      def set_promotion
        @promotion = Promotion.find(params[:id])
      end

      def load_options
        @products = Product.order(:title)
        @categories = Category.order(:name)
        @sellers = User.seller.order(:name)
      end

      def promotion_params
        params.require(:promotion).permit(
          :name,
          :kind,
          :code,
          :product_id,
          :category_id,
          :seller_id,
          :starts_at,
          :ends_at,
          :active,
          tiers_attributes: %i[
            id minimum_value discount_percent _destroy
          ]
        )
      end
    end
  end
