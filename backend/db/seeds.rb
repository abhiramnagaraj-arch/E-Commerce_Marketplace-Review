seller = User.find_or_create_by!(email: "seller@example.com") do |user|
  user.name = "Demo Marketplace Seller"
  user.password = "password"
  user.role = :seller
end

User.find_or_create_by!(email: "buyer@example.com") do |user|
  user.name = "Demo Buyer"
  user.password = "password"
  user.role = :buyer
end

User.find_or_create_by!(email: "admin@example.com") do |user|
  user.name = "Store Admin"
  user.password = "password"
  user.role = :admin
end

category_data = {
  "Electronics" => "Mobiles, laptops, audio devices and accessories.",
  "Fashion" => "Clothing, footwear and everyday fashion.",
  "Home & Kitchen" => "Kitchen appliances and household essentials.",
  "Beauty & Personal Care" => "Skin care, hair care and personal products.",
  "Grocery" => "Daily groceries, beverages and cooking essentials.",
  "Books" => "Popular fiction, self-help and technical books.",
  "Sports & Fitness" => "Fitness, outdoor and sporting products.",
  "Toys & Games" => "Toys, games and creative products for children."
}

categories = {}

category_data.each do |name, description|
  category = Category.find_or_create_by!(name: name) do |row|
    row.description = description
  end
  categories[name] = category
end

product_data = [
  [ "Samsung Galaxy S24", "Electronics", 69_999, 20, "AI smartphone with AMOLED display and premium cameras." ],
  [ "ASUS Vivobook 15", "Electronics", 52_990, 12, "Everyday laptop with 16GB memory and 512GB SSD." ],
  [ "Sony WH-1000XM5", "Electronics", 29_990, 25, "Wireless noise-cancelling headphones." ],
  [ "boAt Airdopes 141", "Electronics", 1_299, 60, "Affordable wireless earbuds with long battery life." ],
  [ "Men's Cotton T-Shirt", "Fashion", 799, 100, "Comfortable regular-fit cotton T-shirt." ],
  [ "Women's Kurta Set", "Fashion", 1_499, 70, "Printed kurta set for everyday and festive wear." ],
  [ "Running Shoes", "Fashion", 2_499, 50, "Lightweight running shoes with cushioned sole." ],
  [ "Mixer Grinder", "Home & Kitchen", 3_499, 30, "750-watt mixer grinder with three jars." ],
  [ "Cotton Bedsheet Set", "Home & Kitchen", 1_299, 45, "Double-bed cotton bedsheet with pillow covers." ],
  [ "Non-Stick Cookware Set", "Home & Kitchen", 2_499, 35, "Three-piece cookware set for daily cooking." ],
  [ "Anti-Dandruff Shampoo", "Beauty & Personal Care", 399, 100, "Gentle daily shampoo for scalp care." ],
  [ "SPF 50 Sunscreen", "Beauty & Personal Care", 549, 90, "Lightweight broad-spectrum sunscreen." ],
  [ "Eau De Parfum", "Beauty & Personal Care", 1_299, 40, "Long-lasting everyday fragrance." ],
  [ "Premium Basmati Rice 5kg", "Grocery", 1_099, 80, "Long-grain aged basmati rice." ],
  [ "Instant Coffee 200g", "Grocery", 449, 120, "Rich instant coffee for hot and cold drinks." ],
  [ "Extra Virgin Olive Oil 1L", "Grocery", 899, 75, "Cold-extracted olive oil for cooking and salads." ],
  [ "Atomic Habits", "Books", 499, 70, "Practical guide to building better habits." ],
  [ "The Alchemist", "Books", 299, 90, "Popular novel about purpose and personal dreams." ],
  [ "Python Crash Course", "Books", 2_199, 35, "Project-based introduction to Python programming." ],
  [ "Premium Yoga Mat", "Sports & Fitness", 799, 65, "Non-slip exercise and yoga mat." ],
  [ "Adjustable Dumbbell Set", "Sports & Fitness", 1_599, 40, "Adjustable home workout dumbbell set." ],
  [ "Badminton Racket Set", "Sports & Fitness", 1_199, 45, "Two rackets with shuttlecocks and carry cover." ],
  [ "Building Blocks Set", "Toys & Games", 999, 55, "Creative building set with colourful blocks." ],
  [ "Remote Control Car", "Toys & Games", 1_499, 35, "Rechargeable remote control racing car." ],
  [ "Family Board Game", "Toys & Games", 699, 60, "Multiplayer board game for family game nights." ]
]

products = {}

product_data.each do |title, category_name, price, stock, description|
  product = Product.find_or_initialize_by(title: title, seller: seller)
  product.update!(
    category: categories[category_name],
    price: price,
    stock: stock,
    description: description,
    active: true
  )
  products[title] = product
end

def set_offer(name, details, levels)
  Promotion.transaction do
    offer = Promotion.find_or_initialize_by(name: name)
    offer.assign_attributes(details)
    offer.tiers.destroy_all if offer.persisted?
    levels.each { |level| offer.tiers.build(level) }
    offer.save!
  end
end

Promotion.where(name: [ "Welcome 10%", "MEGA20", "MacBook Offer", "Audio Offer", "Store Sale" ])
  .update_all(active: false)

set_offer(
  "Shop More Coupon",
  {
    kind: :coupon,
    code: "SHOPMORE",
    starts_at: nil,
    ends_at: nil,
    active: true
  },
  [
    { minimum_value: 2_000, discount_percent: 5 },
    { minimum_value: 5_000, discount_percent: 8 },
    { minimum_value: 10_000, discount_percent: 10 }
  ]
)

set_offer(
  "T-Shirt Multi-Buy Offer",
  {
    kind: :product_discount,
    product: products["Men's Cotton T-Shirt"],
    starts_at: nil,
    ends_at: nil,
    active: true
  },
  [
    { minimum_value: 2, discount_percent: 5 },
    { minimum_value: 3, discount_percent: 10 },
    { minimum_value: 5, discount_percent: 15 }
  ]
)

set_offer(
  "Coffee Stock-Up Offer",
  {
    kind: :product_discount,
    product: products["Instant Coffee 200g"],
    starts_at: nil,
    ends_at: nil,
    active: true
  },
  [
    { minimum_value: 2, discount_percent: 5 },
    { minimum_value: 4, discount_percent: 10 },
    { minimum_value: 6, discount_percent: 15 }
  ]
)

set_offer(
  "Fashion Combo Offer",
  {
    kind: :category_discount,
    category: categories["Fashion"],
    starts_at: nil,
    ends_at: nil,
    active: true
  },
  [
    { minimum_value: 2_000, discount_percent: 7 },
    { minimum_value: 5_000, discount_percent: 12 },
    { minimum_value: 10_000, discount_percent: 15 }
  ]
)

set_offer(
  "Beauty Basket Offer",
  {
    kind: :category_discount,
    category: categories["Beauty & Personal Care"],
    starts_at: nil,
    ends_at: nil,
    active: true
  },
  [
    { minimum_value: 1_000, discount_percent: 5 },
    { minimum_value: 2_500, discount_percent: 10 },
    { minimum_value: 5_000, discount_percent: 15 }
  ]
)

set_offer(
  "Electronics Upgrade Offer",
  {
    kind: :category_discount,
    category: categories["Electronics"],
    starts_at: nil,
    ends_at: nil,
    active: true
  },
  [
    { minimum_value: 25_000, discount_percent: 5 },
    { minimum_value: 60_000, discount_percent: 8 },
    { minimum_value: 100_000, discount_percent: 10 }
  ]
)

set_offer(
  "#{seller.name} Store Sale",
  {
    kind: :sale,
    seller: seller,
    starts_at: Time.current.beginning_of_day,
    ends_at: 60.days.from_now.end_of_day,
    active: true
  },
  [
    { minimum_value: 5_000, discount_percent: 10 },
    { minimum_value: 10_000, discount_percent: 15 },
    { minimum_value: 25_000, discount_percent: 20 }
  ]
)

puts "Demo marketplace data is ready."
puts "#{Category.count} categories"
puts "#{Product.count} products"
puts "#{Promotion.count} promotions"
puts "Existing users and marketplace records were not deleted."
