PRODUCT_BRANDS = {
  "MacBook Air M3 (16GB / 512GB)" => "Apple",
  "ThinkPad X1 Carbon Gen 11" => "Lenovo",
  "Sony WH-1000XM5 Wireless Headphones" => "Sony",
  "AirPods Pro (2nd Generation, USB-C)" => "Apple",
  "Logitech MX Master 3S Advanced Mouse" => "Logitech",
  "Keychron Q1 Pro Wireless Mechanical Keyboard" => "Keychron",
  "Lenovo Ideapad flex 5" => "Lenovo",
  "MacBook Air M3" => "Apple",
  "Logitech MX Master 3S" => "Logitech",
  "Samsung Galaxy S24" => "Samsung",
  "ASUS Vivobook 15" => "ASUS",
  "Sony WH-1000XM5" => "Sony",
  "boAt Airdopes 141" => "boAt",
  "Men's Cotton T-Shirt" => "Rediff Basics",
  "Women's Kurta Set" => "Biba",
  "Running Shoes" => "Campus",
  "Mixer Grinder" => "Preethi",
  "Cotton Bedsheet Set" => "Bombay Dyeing",
  "Non-Stick Cookware Set" => "Prestige",
  "Anti-Dandruff Shampoo" => "Head & Shoulders",
  "SPF 50 Sunscreen" => "Lakme",
  "Eau De Parfum" => "Fogg",
  "Premium Basmati Rice 5kg" => "India Gate",
  "Instant Coffee 200g" => "Nescafe",
  "Extra Virgin Olive Oil 1L" => "Figaro",
  "Atomic Habits" => "Random House",
  "The Alchemist" => "HarperCollins",
  "Python Crash Course" => "No Starch Press",
  "Premium Yoga Mat" => "Boldfit",
  "Adjustable Dumbbell Set" => "Lifelong",
  "Badminton Racket Set" => "Yonex",
  "Building Blocks Set" => "Funskool",
  "Remote Control Car" => "Rastar",
  "Family Board Game" => "Hasbro"
}.freeze

updated = 0
skipped = 0

Product.includes(:seller).find_each do |product|
  if product.brand.present?
    skipped += 1
  else
    product.update!(brand: PRODUCT_BRANDS.fetch(product.title, product.seller.name))
    updated += 1
  end
end

puts "Brands added to #{updated} products."
puts "#{skipped} products already had brands and were skipped."
