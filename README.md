# ⚡ Rediff Store — Ruby on Rails MVC E-Commerce Demo

A complete, professional **Ruby on Rails 8 MVC E-Commerce Application** built for an internship demonstration. This repository contains the full backend Rails MVC application along with sample seed data and a responsive Vanilla CSS glassmorphism UI.

---

## 🚀 Quick Start Guide (For Team & Friends)

Follow these exact steps to clone, configure, and run this E-Commerce store on your local machine in under 5 minutes.

### 📋 Prerequisites
- **Ruby** (version 3.2+ or 4.0+)
- **PostgreSQL** installed and running on your machine
- **Bundler** (`gem install bundler`)
- **Git**

---

### Step 1: Clone the Repository
Open your terminal (PowerShell, Command Prompt, or Bash) and run:

```bash
git clone https://github.com/sanjay8523/abhicompany.git
cd abhicompany/backend/ecommerce
```

---

### Step 2: Configure Your PostgreSQL Password
Before running the database commands, you need to tell Rails your local PostgreSQL password.

1. Open `backend/ecommerce/config/database.yml` in your code editor.
2. Under the `default:` section, locate the `password:` field:
   ```yaml
   default: &default
     adapter: postgresql
     encoding: unicode
     username: postgres
     password: postgresql123 # <-- CHANGE THIS to your local PostgreSQL password
     host: localhost
     pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
   ```
3. Replace `YOUR_POSTGRES_PASSWORD_HERE` with the password you set when installing PostgreSQL (for example: `postgres`, `root`, `1234`, or leave empty if no password is set).
4. Save the file.

---

### Step 3: Install Gems & Dependencies
Inside the `backend/ecommerce` directory, run:

```bash
bundle install
```

---

### Step 4: Create Database, Run Migrations, & Seed Sample Data
Run the following Rails database commands to automatically create the PostgreSQL tables and populate them with sample products, categories, and promo coupons:

```bash
rails db:create
rails db:migrate
rails db:seed
```

> **What `db:seed` generates:**
> - **3 Categories:** Laptops & Computing, Audio & Headphones, Tech Accessories
> - **6 Premium Products:** MacBook Air M3, ThinkPad X1 Carbon, Sony XM5 Headphones, AirPods Pro 2, Logitech MX Master 3S, Keychron Q1 Pro
> - **2 Promo Coupons:** `WELCOME10` (10% off any order) and `MEGA20` (20% off orders above ₹5,000)

---

### Step 5: Start the Rails Web Server
Launch the application server:

```bash
rails server
```

Now open your browser and navigate to:
👉 **http://localhost:3000**

---

## 🏗️ MVC Architecture & Database Tables

```
Categories (id, name, description)
   │
   ├──< Products (id, title, description, price, stock, category_id)
           │
           ├──< CartItems (id, cart_id, product_id, quantity) >── Carts (id)
           │
           └──< OrderItems (id, order_id, product_id, quantity, price) >── Orders
```

### 📂 Key Directory Locations
- **Models & Associations:** `app/models/` (`Category.rb`, `Product.rb`, `Cart.rb`, `CartItem.rb`, `Coupon.rb`, `Order.rb`, `OrderItem.rb`)
- **Controllers:** `app/controllers/` (`ProductsController`, `CategoriesController`, `CartsController`, `OrdersController`)
- **ERB Views:** `app/views/`
- **Design System:** `app/assets/stylesheets/application.css`
- **Database Migrations:** `db/migrate/`
- **Seed Data:** `db/seeds.rb`
- **Routes Configuration:** `config/routes.rb`

---

## 🎟️ Testing Promo Coupon Codes
During your demo or testing, try entering these coupon codes in the Shopping Cart (`/cart`):
- `WELCOME10` — Instantly deducts **10%** from the subtotal.
- `MEGA20` — Instantly deducts **20%** on orders with a subtotal of ₹5,000 or higher.
