puts "🌱 Clearing old seed data..."
OrderItem.destroy_all
Order.destroy_all
CartItem.destroy_all
Cart.destroy_all
Product.destroy_all
Category.destroy_all
Coupon.destroy_all

puts "📁 Creating Categories..."
laptops = Category.create!(name: "Laptops & Computing", description: "High-performance notebooks, ultrabooks, and workstations.")
audio = Category.create!(name: "Audio & Headphones", description: "Studio quality headphones, wireless earbuds, and speakers.")
accessories = Category.create!(name: "Tech Accessories", description: "Keyboards, mice, chargers, and docking stations.")

puts "💻 Creating Products..."
Product.create!([
  {
    title: "MacBook Air M3 (16GB / 512GB)",
    description: "Apple M3 chip with 8-core CPU and 10-core GPU. Ultra-slim aluminum design with 18 hours battery life.",
    price: 114900.00,
    stock: 15,
    category: laptops
  },
  {
    title: "ThinkPad X1 Carbon Gen 11",
    description: "Intel Core i7-1360P, 16GB LPDDR5, 14-inch 2.8K OLED display. Built for enterprise productivity.",
    price: 129990.00,
    stock: 8,
    category: laptops
  },
  {
    title: "Sony WH-1000XM5 Wireless Headphones",
    description: "Industry-leading noise cancellation with two processors and 8 microphones. 30-hour battery life.",
    price: 29990.00,
    stock: 25,
    category: audio
  },
  {
    title: "AirPods Pro (2nd Generation, USB-C)",
    description: "Active Noise Cancellation, Adaptive Audio, and Personalized Spatial Audio with MagSafe charging case.",
    price: 24900.00,
    stock: 30,
    category: audio
  },
  {
    title: "Logitech MX Master 3S Advanced Mouse",
    description: "8K DPI optical sensor, quiet clicks, and electromagnetic MagSpeed scrolling wheel.",
    price: 8999.00,
    stock: 40,
    category: accessories
  },
  {
    title: "Keychron Q1 Pro Wireless Mechanical Keyboard",
    description: "QMK/VIA customizable 75% layout keyboard with CNC aluminum chassis and hot-swappable switches.",
    price: 16999.00,
    stock: 12,
    category: accessories
  }
])

puts "🎟️ Creating Promo Coupons..."
Coupon.create!([
  { code: "WELCOME10", discount_percent: 10, min_order_amount: 0.0, active: true },
  { code: "MEGA20", discount_percent: 20, min_order_amount: 5000.0, active: true }
])

puts "✅ Seed data created successfully!"
puts "   -> #{Category.count} Categories"
puts "   -> #{Product.count} Products"
puts "   -> #{Coupon.count} Coupons"
