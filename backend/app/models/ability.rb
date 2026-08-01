class Ability
  include CanCan::Ability

  def initialize(user)
    can :read, Product
    can :read, Category

    return unless user

    if user.admin?
      can :manage, :all
    elsif user.seller?
      can :manage, Product, seller_id: user.id
      can :manage, SellerOrder, seller_id: user.id
      can :read, OrderItem, product: { seller_id: user.id }
    elsif user.buyer?
      can :manage, Cart, buyer_id: user.id
      can %i[create read], Order, buyer_id: user.id
    end
  end
end