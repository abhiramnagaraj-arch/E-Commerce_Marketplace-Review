admin = User.find_or_initialize_by(email: "admin@example.com")

admin.assign_attributes(
  name: "Admin",
  password: "Admin@123",
  password_confirmation: "Admin@123",
  role: "admin"
)

admin.save!

puts "Admin account created or updated: #{admin.email}"