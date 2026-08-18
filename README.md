# Rediff Store

Rediff Store is a multi-vendor e-commerce marketplace built as a Ruby on Rails monolith. It provides separate buyer, seller, and administrator workflows, with server-rendered ERB views, Hotwire-powered cart updates, PostgreSQL persistence, and a responsive custom CSS interface.

The Rails application lives in [`backend/`](backend/). The files in [`frontend/`](frontend/) are reference notes; there is no separate frontend service to install or run.

## Current features

### Buyers

- Browse active products and categories without signing in
- Register or sign in with Devise
- Add products to a stock-aware cart and update quantities without a full-page reload
- Compare eligible promotions and select one offer per order
- Check out with customer and delivery details
- View order history and seller-level fulfillment progress
- Cancel an entire order or individual items before shipment; canceled stock is restored

### Sellers

- Register a seller account and access a role-protected dashboard
- Create, edit, view, and archive their own products
- Manage price, stock, brand, category, description, and JSON-backed specifications
- View only their portion of marketplace orders
- Move items through `confirmed -> processing -> shipped -> delivered`
- Reject eligible items with a reason; rejected stock is restored

### Administrators

- View marketplace totals from an admin dashboard
- Create, edit, and delete categories (categories with products are protected)
- View all orders and seller-level order breakdowns
- Create, edit, activate, and deactivate tiered promotions
- Target promotions at a coupon, product, category, or seller storefront

### Marketplace rules

- Product stock is locked and checked during checkout to prevent overselling
- Orders containing multiple sellers are split into `SellerOrder` records
- Item-level status changes roll up to seller-order and overall-order statuses
- Promotion discounts are stored on each order item for accurate seller totals
- Coupon use is limited to once per buyer
- Product deletion is implemented as archiving so historical order data remains intact

## Tech stack

| Area | Technology |
| --- | --- |
| Application | Ruby 3.2.3, Rails 8.1.3 |
| Database | PostgreSQL |
| Authentication | Devise |
| State transitions | AASM |
| UI | ERB, Propshaft, custom CSS |
| Interactivity | Hotwire (Turbo), Importmap |
| Server and jobs | Puma, Solid Queue, Solid Cache, Solid Cable |
| Quality tooling | Minitest, RuboCop, Brakeman, Bundler Audit |
| Deployment | Docker, Thruster, Kamal configuration |

## Getting started

### Prerequisites

- Git
- Ruby `3.2.3` (the version in [`backend/.ruby-version`](backend/.ruby-version))
- Bundler `4.0.16`
- PostgreSQL running locally
- PostgreSQL development headers if the `pg` gem needs to be compiled (`libpq-dev` on Debian/Ubuntu)

### 1. Clone and enter the Rails application

```bash
git clone https://github.com/abhiramnagaraj-arch/E-Commerce_Marketplace-Review.git
cd E-Commerce_Marketplace-Review/backend
```

All remaining commands in this README run from `backend/`.

### 2. Configure PostgreSQL

The development configuration in [`backend/config/database.yml`](backend/config/database.yml) currently expects:

```yaml
username: postgres
password: postgresql123
host: localhost
port: 5432
```

Update those values to match your local PostgreSQL installation. The configured databases are `ecommerce_development`, `ecommerce_test`, and `ecommerce_production`.

You can also provide a connection URL for an individual command, for example:

```bash
DATABASE_URL=postgres://postgres:your_password@localhost:5432/ecommerce_development bin/rails db:prepare
```

### 3. Install dependencies and prepare data

```bash
bundle install
bin/rails db:prepare
bin/rails db:seed
```

`db:prepare` creates the database when needed and loads the current schema. The seed is designed to be rerunnable and does not delete existing users, products, or orders.

### 4. Start the application

```bash
bin/rails server
```

Open [http://localhost:3000](http://localhost:3000). The health endpoint is available at [http://localhost:3000/up](http://localhost:3000/up).

## Demo data and accounts

Running `bin/rails db:seed` creates:

- 8 categories
- 25 products with brands and category-specific specifications
- 7 active, tiered promotions covering coupons, products, categories, and a seller sale
- One account for each application role

| Role | Email | Password | Landing page |
| --- | --- | --- | --- |
| Buyer | `buyer@example.com` | `password` | `/buyer` |
| Seller | `seller@example.com` | `password` | `/seller` |
| Admin | `admin@example.com` | `password` | `/admin` |

These credentials are for local demonstration only.

The seeded `SHOPMORE` coupon has three order-value tiers: 5% from Rs. 2,000, 8% from Rs. 5,000, and 10% from Rs. 10,000. Eligible offers appear automatically in the buyer's cart; buyers choose an unlocked offer rather than entering a coupon code manually.

## Application structure

```text
backend/
├── app/
│   ├── controllers/
│   │   ├── admin/       # Categories, promotions, and marketplace orders
│   │   ├── buyer/       # Dashboard, cart, checkout, and order cancellation
│   │   └── seller/      # Catalog management and order fulfillment
│   ├── models/          # Commerce rules, associations, and state transitions
│   ├── views/           # ERB pages and Turbo Stream responses
│   ├── javascript/      # Importmap entry point and UI behavior
│   └── assets/          # Custom application styling
├── config/routes.rb     # Public and role-scoped routes
├── db/migrate/          # Incremental database changes
├── db/schema.rb         # Current PostgreSQL schema
├── db/seeds.rb          # Demo users, catalog, and promotions
├── Dockerfile           # Production container image
└── test/                # Minitest locations (currently scaffolded)
```

The main data flow is:

```text
User (buyer) -> Cart -> CartItem -> Product <- User (seller)
     |                                |
     +-> Order -> SellerOrder -> OrderItem
           |
           +-> Promotion -> PromotionTier

Category -> Product
Category/Product/Seller <- Promotion
```

For deeper database documentation, see [`backend/DATABASE_ARCHITECTURE_REPORT.md`](backend/DATABASE_ARCHITECTURE_REPORT.md) and [`backend/DATABASE_QUERY_CATALOG.md`](backend/DATABASE_QUERY_CATALOG.md).

## Useful commands

```bash
# Run the test suite
bin/rails test

# Run system tests
bin/rails test:system

# Check code style
bundle exec rubocop

# Scan application code and dependencies
bundle exec brakeman --no-pager
bundle exec bundler-audit

# Inspect routes or reset local demo data
bin/rails routes
bin/rails db:reset
```

The CI template in `backend/.github/workflows/ci.yml` defines linting, security scans, unit tests, and system tests. Because GitHub only discovers workflows from the repository-root `.github/workflows/` directory, it must be moved there before it will run for this repository. Its referenced RuboCop, Brakeman, Bundler Audit, and Importmap binstubs are also absent; use the `bundle exec` commands above for the first three and either add a supported Importmap audit command or remove that CI step. The `test/` directories are scaffolded but do not yet contain project-specific test cases.

## Current status

The core marketplace demonstration is implemented: authentication, role isolation, catalog management, cart and checkout, tiered promotions, multi-seller order splitting, item-level fulfillment, cancellation/rejection handling, pagination, and responsive views are all present.

Areas still suitable for production hardening include adding project-specific automated tests, activating and correcting the CI template, moving database secrets fully into environment-managed configuration, configuring real email delivery, adding product image upload/storage, and replacing the placeholder hosts and registry values in [`backend/config/deploy.yml`](backend/config/deploy.yml).
