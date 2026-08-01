seller = User.find_or_create_by!(email: "seller@example.com") do |user|
  user.name = "Demo Seller"
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

laptops = Category.find_or_initialize_by(name: "Laptops & Computing")
laptops.update!(description: "High-performance notebooks and workstations.")

audio = Category.find_or_initialize_by(name: "Audio & Headphones")
audio.update!(description: "Headphones, wireless earbuds, and speakers.")

accessories = Category.find_or_initialize_by(name: "Tech Accessories")
accessories.update!(description: "Keyboards, mice, chargers, and docks.")

macbook = Product.find_or_initialize_by(title: "MacBook Air M3")
macbook.update!(
  description: "Apple M3 laptop with 16GB memory and 512GB storage.",
  price: 114_900,
  stock: 15,
  category: laptops,
  seller: seller,
  active: true
)

headphones = Product.find_or_initialize_by(title: "Sony WH-1000XM5")
headphones.update!(
  description: "Wireless headphones with noise cancellation.",
  price: 29_990,
  stock: 25,
  category: audio,
  seller: seller,
  active: true
)

mouse = Product.find_or_initialize_by(title: "Logitech MX Master 3S")
mouse.update!(
  description: "Wireless productivity mouse.",
  price: 8_999,
  stock: 40,
  category: accessories,
  seller: seller,
  active: true
)

welcome = Promotion.find_by("LOWER(code) = ?", "welcome10") ||
          Promotion.new(code: "WELCOME10")
welcome.update!(
  name: "Welcome 10%",
  kind: :coupon,
  discount_percent: 10,
  min_order_amount: 1_000,
  starts_at: nil,
  ends_at: nil,
  active: true
)

macbook_offer = Promotion.find_or_initialize_by(name: "MacBook Offer")
macbook_offer.update!(
  kind: :product_discount,
  product: macbook,
  discount_percent: 8,
  min_order_amount: 0,
  starts_at: nil,
  ends_at: nil,
  active: true
)

audio_offer = Promotion.find_or_initialize_by(name: "Audio Offer")
audio_offer.update!(
  kind: :category_discount,
  category: audio,
  discount_percent: 5,
  min_order_amount: 0,
  starts_at: nil,
  ends_at: nil,
  active: true
)

store_sale = Promotion.find_or_initialize_by(name: "Store Sale")
store_sale.update!(
  kind: :sale,
  discount_percent: 3,
  min_order_amount: 0,
  starts_at: Time.current.beginning_of_day,
  ends_at: 30.days.from_now.end_of_day,
  active: true
)

puts "Seed data is ready."
puts "#{User.count} users"
puts "#{Category.count} categories"
puts "#{Product.count} products"
puts "#{Promotion.count} promotions"
