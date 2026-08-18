product_specifications = {
  "Samsung Galaxy S24" => <<~TEXT.strip,
    Display: 6.2-inch Dynamic AMOLED 2X
    Memory: 8 GB RAM
    Storage: 256 GB
    Camera: Triple rear camera system
    Battery: 4000 mAh
    Operating system: Android
  TEXT
  "ASUS Vivobook 15" => <<~TEXT.strip,
    Display: 15.6-inch Full HD
    Memory: 16 GB RAM
    Storage: 512 GB SSD
    Keyboard: Full-size keyboard
    Connectivity: Wi-Fi and Bluetooth
    Operating system: Windows 11
  TEXT
  "Sony WH-1000XM5" => <<~TEXT.strip,
    Type: Over-ear wireless headphones
    Connectivity: Bluetooth
    Noise control: Active noise cancellation
    Microphone: Built-in microphone
    Charging: USB-C
    Colour: Black
  TEXT
  "boAt Airdopes 141" => <<~TEXT.strip,
    Type: True wireless earbuds
    Connectivity: Bluetooth
    Microphone: Built-in microphone
    Charging case: Included
    Charging port: USB-C
    Water resistance: Sweat resistant
  TEXT
  "Men's Cotton T-Shirt" => <<~TEXT.strip,
    Material: Cotton
    Fit: Regular fit
    Sleeve type: Half sleeve
    Neck type: Round neck
    Pattern: Solid
    Care: Machine wash
  TEXT
  "Women's Kurta Set" => <<~TEXT.strip,
    Set includes: Kurta and bottoms
    Fit: Regular fit
    Pattern: Printed
    Sleeve type: Three-quarter sleeve
    Occasion: Casual and festive
    Care: Gentle machine wash
  TEXT
  "Running Shoes" => <<~TEXT.strip,
    Upper material: Breathable mesh
    Sole material: Rubber
    Closure: Lace-up
    Cushioning: Padded insole
    Usage: Running and daily training
    Care: Wipe with a clean cloth
  TEXT
  "Mixer Grinder" => <<~TEXT.strip,
    Power: 750 watts
    Number of jars: 3
    Speed settings: 3
    Blade material: Stainless steel
    Safety: Overload protection
    Power supply: 230 V
  TEXT
  "Cotton Bedsheet Set" => <<~TEXT.strip,
    Material: Cotton
    Bed size: Double
    Set includes: 1 bedsheet and 2 pillow covers
    Pattern: Printed
    Finish: Soft touch
    Care: Machine wash
  TEXT
  "Non-Stick Cookware Set" => <<~TEXT.strip,
    Pieces: 3
    Coating: Non-stick
    Body material: Aluminium
    Handle type: Heat-resistant
    Suitable for: Daily cooking
    Care: Hand wash recommended
  TEXT
  "Anti-Dandruff Shampoo" => <<~TEXT.strip,
    Product type: Shampoo
    Hair concern: Dandruff
    Usage: Apply to wet hair and rinse
    Suitable for: Regular use
    Container type: Bottle
    Storage: Store in a cool, dry place
  TEXT
  "SPF 50 Sunscreen" => <<~TEXT.strip,
    Sun protection: SPF 50
    Protection type: Broad spectrum
    Texture: Lightweight lotion
    Usage: Face and body
    Application: Apply before sun exposure
    Skin type: Suitable for daily use
  TEXT
  "Eau De Parfum" => <<~TEXT.strip,
    Fragrance type: Eau de parfum
    Form: Spray
    Usage: Everyday wear
    Scent profile: Fresh and long-lasting
    Container type: Glass bottle
    Storage: Keep away from direct sunlight
  TEXT
  "Premium Basmati Rice 5kg" => <<~TEXT.strip,
    Rice type: Basmati
    Net weight: 5 kg
    Grain type: Long grain
    Processing: Aged
    Diet type: Vegetarian
    Storage: Store in a cool, dry place
  TEXT
  "Instant Coffee 200g" => <<~TEXT.strip,
    Product type: Instant coffee
    Net weight: 200 g
    Form: Granules
    Preparation: Hot or cold
    Diet type: Vegetarian
    Storage: Keep the container tightly closed
  TEXT
  "Extra Virgin Olive Oil 1L" => <<~TEXT.strip,
    Oil type: Extra virgin olive oil
    Net volume: 1 litre
    Extraction: Cold extracted
    Usage: Cooking, dressing and salads
    Diet type: Vegetarian
    Storage: Store away from heat and sunlight
  TEXT
  "Atomic Habits" => <<~TEXT.strip,
    Format: Paperback
    Language: English
    Genre: Self-help
    Author: James Clear
    Audience: General readers
    Binding: Perfect bound
  TEXT
  "The Alchemist" => <<~TEXT.strip,
    Format: Paperback
    Language: English
    Genre: Fiction
    Author: Paulo Coelho
    Audience: General readers
    Binding: Perfect bound
  TEXT
  "Python Crash Course" => <<~TEXT.strip,
    Format: Paperback
    Language: English
    Subject: Python programming
    Level: Beginner to intermediate
    Learning style: Project based
    Audience: Students and developers
  TEXT
  "Premium Yoga Mat" => <<~TEXT.strip,
    Material: Non-slip foam
    Surface: Textured
    Usage: Yoga and floor exercises
    Portability: Rollable
    Cleaning: Wipe clean
    Included: Carry strap
  TEXT
  "Adjustable Dumbbell Set" => <<~TEXT.strip,
    Equipment type: Adjustable dumbbells
    Material: Metal and composite
    Grip: Textured handle
    Weight adjustment: Removable plates
    Usage: Home strength training
    Set includes: Dumbbells and weight plates
  TEXT
  "Badminton Racket Set" => <<~TEXT.strip,
    Set includes: 2 rackets and shuttlecocks
    Frame material: Lightweight alloy
    Grip: Cushioned
    Usage: Recreational badminton
    Skill level: Beginner and intermediate
    Carry cover: Included
  TEXT
  "Building Blocks Set" => <<~TEXT.strip,
    Toy type: Construction blocks
    Material: Plastic
    Play type: Creative building
    Skill development: Motor skills and imagination
    Colour: Multicolour
    Storage: Reusable box
  TEXT
  "Remote Control Car" => <<~TEXT.strip,
    Toy type: Remote control car
    Control type: Wireless remote
    Power source: Rechargeable battery
    Charging: USB charging cable
    Usage: Indoor and outdoor play
    Colour: Multicolour
  TEXT
  "Family Board Game" => <<~TEXT.strip
    Game type: Family board game
    Players: Multiple players
    Play mode: Competitive
    Skill development: Strategy and communication
    Usage: Indoor play
    Package includes: Board and game pieces
  TEXT
}

product_specifications.transform_values! do |text|
  text.lines.filter_map do |line|
    key, value = line.strip.split(":", 2)
    [ key.strip, value.strip ] if key.present? && value.present?
  end.to_h
end

updated = 0
skipped = 0
missing = []

Product.transaction do
  product_specifications.each do |title, specifications|
    product = Product.find_by(title: title)

    if product.nil?
      missing << title
    elsif product.specifications.present?
      skipped += 1
    else
      product.update!(specifications: specifications)
      updated += 1
    end
  end
end

puts "Specifications added to #{updated} products."
puts "#{skipped} products already had specifications and were skipped."
puts "Missing products: #{missing.join(', ')}" if missing.any?
