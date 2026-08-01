# Rails Database Query Catalog

**Project:** Rediff Store

**Scope:** explicit and implicit database access in `app/`, plus seed scripts

**Database:** PostgreSQL through Rails 8.1 Active Record

**Companion document:** `DATABASE_ARCHITECTURE_REPORT.md`

## 1. How to read this catalog

The SQL below is representative, not byte-for-byte captured SQL. Rails may change aliases, selected columns, bind syntax, transaction/savepoint statements, and preload order. Values shown as `$1`, `$2`, and so on are bound parameters.

Four distinctions are important:

1. **Relation builders are lazy.** Calls such as `where`, `order`, `group`, `limit`, and `includes` usually build an `ActiveRecord::Relation`; they do not query until records or an aggregate are requested.
2. **Terminal methods execute.** `find`, `find_by`, `count`, `sum`, `to_a`, `each`, `max_by`, and usually `any?`/`empty?` cause SQL when the relation or association is not already loaded.
3. **Association methods add predicates.** `current_user.orders.find(id)` is not the same as `Order.find(id)`; it adds `buyer_id = current_user.id`, which provides ownership protection.
4. **A single Ruby call can produce several statements.** `save`, `update`, `destroy`, AASM events, and Devise actions can run validations, callbacks, dependent deletes, and transactions.

## 2. Active Record functions used by this project

### Read and relation functions

| Rails call used | Executes immediately? | What it does | Representative SQL |
|---|---:|---|---|
| `Model.find(id)` | Yes | Finds by primary key; raises if missing | `SELECT * FROM models WHERE id = $1 LIMIT 1` |
| `association.find(id)` | Yes | Finds inside the association owner scope | `SELECT * FROM children WHERE owner_id = $1 AND id = $2 LIMIT 1` |
| `find_by(...)` | Yes | Returns first matching row or nil | `SELECT * FROM table WHERE ... LIMIT 1` |
| `find_or_initialize_by(...)` | Read now; possible write later | Finds a row or creates an unsaved Ruby object | `SELECT * FROM table WHERE ... LIMIT 1` |
| `find_or_create_by!(...)` | Read, then possible insert | Finds or validates/inserts; raises on failure | `SELECT ... LIMIT 1`, then possibly `INSERT ... RETURNING id` |
| `where(...)` | No | Adds SQL predicates | Later: `... WHERE column = $1` |
| named scope `available` | No | Project scope equivalent to `where(active: true)` | Later: `... WHERE active = TRUE` |
| `order(...)` | No | Adds ordering | Later: `... ORDER BY created_at DESC` |
| `limit(n)` | No | Adds row limit | Later: `... LIMIT n` |
| `group(...)` | No | Adds grouping for an aggregate | Later: `... GROUP BY category_id` |
| `includes(...)` | No by itself | Requests eager loading; normally primary query plus one query per association type | `SELECT parents ...`; `SELECT children ... WHERE parent_id IN (...)` |
| `reload` | Yes | Discards cached record/association data and fetches again | `SELECT * FROM ... WHERE ...` |
| `to_a` | Yes if unloaded | Materializes a relation and performs requested preloads | `SELECT ...`, plus preload queries |
| `each` | Yes if unloaded | Loads relation, then iterates in Ruby | `SELECT ...` |
| `index_by` | Yes if relation/association unloaded | Loads rows, then constructs a Ruby hash | `SELECT ...`; hashing is in memory |
| `max_by` | Yes if relation unloaded | Loads every candidate; comparison is in Ruby, not SQL `MAX` | `SELECT * FROM ...`; max calculation is in memory |
| `first(5)` | Yes if relation unloaded | Fetches first five records respecting order | `SELECT ... ORDER BY ... LIMIT 5` |
| `any?` | Usually yes if unloaded | Checks existence without loading all rows | `SELECT 1 AS one FROM ... LIMIT 1` |
| `empty?` | Usually yes if unloaded | Checks whether any matching row exists | `SELECT 1 AS one FROM ... LIMIT 1` |
| association attribute access | Sometimes | Loads an unloaded `belongs_to` or collection | e.g. `SELECT * FROM users WHERE id = $1 LIMIT 1` |

### Aggregate functions

| Rails call used | SQL generated | Result |
|---|---|---|
| `Model.count` | `SELECT COUNT(*) FROM table` | Total row count |
| `relation.count` | `SELECT COUNT(*) FROM table WHERE ...` | Count matching rows |
| `group(:column).count` | `SELECT COUNT(*) AS count_all, column FROM table ... GROUP BY column` | Ruby hash of grouped counts |
| `relation.sum(:column)` | `SELECT SUM(column) FROM table WHERE ...` | Database-calculated sum |
| `loaded_array.sum(&:method)` | No SQL | Ruby-calculated sum; called several times in cart/promotion calculations |
| `association.count` | Normally SQL even if preloaded | `SELECT COUNT(*) FROM children WHERE owner_id = $1` |
| `association.size` | SQL only if unloaded/counter unavailable | Uses a loaded collection when possible; preferable after `includes` |

### Object construction and writes

| Rails call used | Executes immediately? | Behavior / representative SQL |
|---|---:|---|
| `Model.new(...)` | No | Creates an unsaved Ruby object |
| `association.build(...)` | No | Creates an unsaved object and automatically assigns its foreign key |
| `save` / `save!` | Yes | Validations/callbacks, then `INSERT ... RETURNING id` for new rows or `UPDATE ... WHERE id = ...` for changed rows |
| `create!` / association `create!` | Yes | Build + validate + insert; association form assigns owner FK |
| `update(...)` / `update!(...)` | Yes | Assigns fields, validates/callbacks, then `UPDATE`; bang form raises on failure |
| `destroy` / `destroy!` | Yes | Runs callbacks/dependent behavior, then `DELETE FROM ... WHERE id = $1` |
| `transaction` | Yes | Wraps statements with `BEGIN` and `COMMIT`, or `ROLLBACK` on error/explicit rollback |
| `lock!` | Yes | Reloads one row with a pessimistic row lock | `SELECT * FROM table WHERE id = $1 LIMIT 1 FOR UPDATE` |
| `with_lock` | Yes | Starts/joins transaction, locks the record, then executes block | `BEGIN`; `SELECT ... FOR UPDATE`; block SQL; `COMMIT` |

### Project calls that look database-related but do not query by themselves

- `new`, `build`, enum methods such as `buyer?`, `coupon?`, and `Promotion.kinds` operate in Ruby.
- `group_by`, `to_h`, `reject`, `find` on an Array, `sum(&:total_price)`, and `values.sum` operate in memory after records were loaded.
- AASM predicates such as `may_process?`, `processing?`, and `delivered?` inspect the current object in memory.
- Rails session access/deletion is not an Active Record query in this application.
- `errors.count`, `errors.full_messages`, and form rendering do not query the database.

## 3. Public catalog and category queries

### `ProductsController#index`

When `category_id` is present:

1. `Category.find(params[:category_id])`
   - `SELECT categories.* FROM categories WHERE categories.id = $1 LIMIT 1`
2. `@category.products.available.order(created_at: :desc)` builds a lazy relation.
   - When the view evaluates/iterates it: `SELECT products.* FROM products WHERE products.category_id = $1 AND products.active = TRUE ORDER BY products.created_at DESC`
3. `Category.order(:name)` builds a lazy relation.
   - When the filter bar iterates: `SELECT categories.* FROM categories ORDER BY categories.name ASC`

Without a category:

1. `Product.available.includes(:category).order(created_at: :desc)` builds a relation.
2. On view use, Rails normally issues:
   - `SELECT products.* FROM products WHERE products.active = TRUE ORDER BY products.created_at DESC`
   - `SELECT categories.* FROM categories WHERE categories.id IN (...)`
3. It also loads all categories for the filter bar as above.

The view calls `@products.any?` before `each`. If the relation is unloaded, that can add `SELECT 1 ... LIMIT 1` before the full product query.

### `ProductsController#show`

`Product.available.find(params[:id])`:

```sql
SELECT products.*
FROM products
WHERE products.active = TRUE AND products.id = $1
LIMIT 1;
```

The view accesses `@product.category`; because category was not included, this normally adds:

```sql
SELECT categories.* FROM categories WHERE categories.id = $1 LIMIT 1;
```

For a signed-in buyer, `cart_item_for(@product)` may also load the current cart and all its items; see section 8.

### `CategoriesController#index`

1. `Category.order(:name)` → on iteration: `SELECT categories.* FROM categories ORDER BY name ASC`.
2. `Product.available.group(:category_id).count` executes immediately:

```sql
SELECT COUNT(*) AS count_all, products.category_id
FROM products
WHERE products.active = TRUE
GROUP BY products.category_id;
```

This is already one efficient grouped query, not an N+1 query.

### `CategoriesController#show`

1. `Category.find(id)` → category lookup by PK.
2. `@category.products.available.includes(:seller).order(created_at: :desc)` → active category products and one seller preload query:
   - `SELECT products.* FROM products WHERE category_id = $1 AND active = TRUE ORDER BY created_at DESC`
   - `SELECT users.* FROM users WHERE users.id IN (...)`

The current view does not use the preloaded seller, so that seller preload is unnecessary work. The view also calls `@products.count`, then `@products.any?`, then iterates. An unloaded relation can therefore cause a `COUNT`, an existence query, and the actual row/preload queries.

## 4. Seller-side queries and writes

### `Seller::DashboardController#show`

- `current_user.products.order(created_at: :desc)` builds `WHERE seller_id = current_user.id ORDER BY created_at DESC`.
- The view calls `any?` and then `first(5)`, normally producing an existence query and a limited product query.
- `current_user.seller_orders.order(created_at: :desc).limit(5)` becomes:

```sql
SELECT seller_orders.*
FROM seller_orders
WHERE seller_orders.seller_id = $1
ORDER BY seller_orders.created_at DESC
LIMIT 5;
```

### `Seller::CategoriesController`

`index`:

- all categories ordered by name;
- `current_user.products.group(:category_id).count`:

```sql
SELECT COUNT(*) AS count_all, products.category_id
FROM products
WHERE products.seller_id = $1
GROUP BY products.category_id;
```

`show`:

- `Category.find(id)`;
- `current_user.products.where(category: @category).order(created_at: :desc)`:

```sql
SELECT products.*
FROM products
WHERE products.seller_id = $1 AND products.category_id = $2
ORDER BY products.created_at DESC;
```

### `Seller::ProductsController`

`index` uses seller ownership, orders newest, and preloads categories:

```sql
SELECT products.* FROM products
WHERE seller_id = $1 ORDER BY created_at DESC;
SELECT categories.* FROM categories WHERE id IN (...);
```

`new` and `create` call `current_user.products.build(...)`. This performs no query and sets `seller_id` in memory. On successful `save`:

```sql
INSERT INTO products
  (seller_id, category_id, title, description, price, stock, active, created_at, updated_at)
VALUES (...) RETURNING id;
```

`edit`, `show`, `update`, and `destroy` first use `current_user.products.find(id)`:

```sql
SELECT products.*
FROM products
WHERE products.seller_id = $1 AND products.id = $2
LIMIT 1;
```

That ownership condition prevents one seller from changing another seller's product.

- `update(product_params)` validates and executes `UPDATE products SET ... WHERE id = $1` when fields changed.
- “destroy” does not delete. `Product#archive` calls `update(active: false)`, producing `UPDATE products SET active = FALSE, updated_at = ... WHERE id = $1`.
- `load_categories` queries all categories ordered by name for the form.

### `Seller::OrdersController`

`index`:

```sql
SELECT seller_orders.*
FROM seller_orders
WHERE seller_orders.seller_id = $1
ORDER BY seller_orders.created_at DESC;

SELECT orders.* FROM orders WHERE orders.id IN (...);
SELECT order_items.* FROM order_items WHERE order_items.seller_order_id IN (...);
```

The two latter statements come from `includes(:order, :order_items)`.

However, the view then calls `seller_order.seller_total`, whose implementation is `order_items.sum(:subtotal)`. That issues one extra query per seller order:

```sql
SELECT SUM(order_items.subtotal)
FROM order_items
WHERE order_items.seller_order_id = $1;
```

`show` and every state-changing action use `current_user.seller_orders.find(id)`, adding seller ownership to the PK lookup. `@seller_order.order` and `@seller_order.order_items` query their associated records if not already loaded.

State actions call AASM methods covered in section 7.

## 5. Admin queries and writes

### `Admin::DashboardController#show`

Four immediate aggregate queries run:

```sql
SELECT COUNT(*) FROM categories;
SELECT COUNT(*) FROM products WHERE active = TRUE;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM promotions WHERE active = TRUE;
```

### `Admin::CategoriesController`

- `index`: `SELECT categories.* FROM categories ORDER BY name ASC` when iterated.
- `set_category`: `SELECT categories.* FROM categories WHERE id = $1 LIMIT 1`.
- `new`: no SQL.
- `create`: validates name presence and uniqueness. The uniqueness validator normally checks:

```sql
SELECT 1 AS one FROM categories WHERE categories.name = $1 LIMIT 1;
```

Then it inserts the category.

- `update`: may perform a uniqueness check excluding the current ID, then `UPDATE categories ... WHERE id = $1`.
- `destroy`: because products and promotions use `restrict_with_error`, Rails checks dependent associations (existence queries) before deletion. If none exist: `DELETE FROM categories WHERE id = $1`.

### `Admin::PromotionsController`

`index` loads promotions newest and preloads both optional target types:

```sql
SELECT promotions.* FROM promotions ORDER BY created_at DESC;
SELECT products.* FROM products WHERE id IN (...);
SELECT categories.* FROM categories WHERE id IN (...);
```

`new` / `Promotion.new` perform no SQL. `create`/`save` and `update` run validations. Code uniqueness normally runs an expression comparison such as:

```sql
SELECT 1 AS one
FROM promotions
WHERE LOWER(promotions.code) = LOWER($1)
[AND promotions.id <> $2]
LIMIT 1;
```

Then Rails issues an `INSERT` or `UPDATE`. The `before_validation` callback can clear inappropriate product/category/code fields before writing.

`toggle` calls `update(active: !active)`:

```sql
UPDATE promotions SET active = $1, updated_at = $2 WHERE id = $3;
```

Promotion forms query all products ordered by title and all categories ordered by name.

### `Admin::OrdersController`

- `index`: `SELECT orders.* FROM orders ORDER BY created_at DESC` when used.
- `set_order`: primary-key order lookup.
- `show`: seller parts plus sellers and order lines:

```sql
SELECT seller_orders.* FROM seller_orders WHERE order_id = $1;
SELECT users.* FROM users WHERE id IN (...);
SELECT order_items.* FROM order_items WHERE seller_order_id IN (...);
```

The view calls two SQL aggregate methods per seller part:

```sql
SELECT SUM(subtotal) FROM order_items WHERE seller_order_id = $1;
SELECT SUM(discount_amount) FROM order_items WHERE seller_order_id = $1;
```

This is a `2N` aggregate-query pattern despite the order-item preload.

### `Admin::SellerOrdersController`

`SellerOrder.find(id)` is an unrestricted admin PK lookup. AASM event calls then write the seller-order state and refresh the parent order as described in section 7. Accessing `@seller_order.order` for redirect can query the order unless callbacks already loaded it.

## 6. Buyer-side queries and writes

### `Buyer::DashboardController#show`

```sql
SELECT orders.*
FROM orders
WHERE orders.buyer_id = $1
ORDER BY orders.created_at DESC
LIMIT 5;
```

The view may precede this with an existence query through `@orders.any?`.

### `Buyer::OrdersController#index`

The association ownership scope and preload produce:

```sql
SELECT orders.*
FROM orders
WHERE orders.buyer_id = $1
ORDER BY orders.created_at DESC;

SELECT order_items.*
FROM order_items
WHERE order_items.order_id IN (...);
```

The view calls `order.order_items.count` per order. `count` normally issues:

```sql
SELECT COUNT(*) FROM order_items WHERE order_items.order_id = $1;
```

Using `order.order_items.size` would reuse the included rows and remove these N extra counts.

### `Buyer::OrdersController#show`

The order lookup is ownership-safe:

```sql
SELECT orders.*
FROM orders
WHERE orders.buyer_id = $1 AND orders.id = $2
LIMIT 1;
```

Seller parts are loaded with seller and line preloads, using the same three-query pattern as the admin detail page. The view's iteration uses the preloaded associations. `@order.may_cancel_order?` accesses `seller_orders`; if the association is not considered loaded by the earlier relation evaluation, it can issue another seller-order query.

### `Buyer::OrdersController#new` and `#create`

- `current_user.orders.build` is in-memory construction and sets `buyer_id`.
- `set_cart`, `set_summary`, promotion evaluation, and checkout queries are covered in sections 7–9.
- Successful order placement inserts the order through `save`, even though the controller itself never calls `save`; the model workflow does.

### `Buyer::CartsController#show` and promotion actions

`@cart.cart_items.includes(:product)` is lazy. When promotion/summary/view materializes it:

```sql
SELECT cart_items.* FROM cart_items WHERE cart_items.cart_id = $1;
SELECT products.* FROM products WHERE products.id IN (...);
```

`apply_promotion` performs the same cart/product loading and then the promotion queries described in section 9.

### Cart line actions

`add_item`:

1. Find active product by ID.
2. `Cart#add_product` calls:
   - `SELECT cart_items.* FROM cart_items WHERE cart_id = $1 AND product_id = $2 LIMIT 1`.
3. Existing line: quantity changes in memory; new line: `cart_items.build` has no SQL.
4. `save` validates uniqueness and stock/availability, then inserts or updates. The uniqueness validator normally executes:

```sql
SELECT 1 AS one
FROM cart_items
WHERE product_id = $1 AND cart_id = $2 [AND id <> $3]
LIMIT 1;
```

`cart_item` for remove/increment/decrement is ownership-scoped by cart:

```sql
SELECT cart_items.*
FROM cart_items
WHERE cart_items.cart_id = $1 AND cart_items.id = $2
LIMIT 1;
```

- `remove_item`: `DELETE FROM cart_items WHERE id = $1`.
- `increase_quantity`: validation may load its product, then `UPDATE cart_items SET quantity = quantity_value, updated_at = ... WHERE id = $1`.
- `decrease_quantity`: quantity 1 destroys the row; otherwise performs the validated update.
- Turbo response rendering calls `cart_item_count`, adding a cart quantity `SUM` after mutation.

## 7. Order, fulfillment, and stock model queries

### `Order#place_from_cart`

This is the most write-intensive workflow.

1. `Order.transaction` → `BEGIN` when the first statement executes.
2. `cart.cart_items.includes(:product).to_a`:

```sql
SELECT cart_items.* FROM cart_items WHERE cart_id = $1;
SELECT products.* FROM products WHERE id IN (...);
```

3. For every item, `item.product.lock!` normally reloads and locks that product separately:

```sql
SELECT products.* FROM products WHERE id = $1 LIMIT 1 FOR UPDATE;
```

This is N lock queries for N cart lines.

4. Cart/promotion calculations are in Ruby after the relevant rows are loaded, except promotion candidate lookup.
5. `save` inserts the order:

```sql
INSERT INTO orders
  (buyer_id, customer_name, customer_email, customer_address,
   total_amount, discount_amount, final_amount,
   promotion_name, promotion_kind, promotion_code, status,
   created_at, updated_at)
VALUES (...) RETURNING id;
```

6. `items.group_by` is in-memory. One `seller_orders.create!` per unique seller inserts:

```sql
INSERT INTO seller_orders
  (order_id, seller_id, status, created_at, updated_at)
VALUES (...) RETURNING id;
```

7. One `order_items.create!` per cart line inserts the historical line snapshot.
8. One `product.update!` per line decrements stock:

```sql
UPDATE products SET stock = $1, updated_at = $2 WHERE id = $3;
```

9. `cart.destroy!` invokes `has_many :cart_items, dependent: :destroy`. Rails deletes the cart items (potentially one row at a time because callbacks are honored), then deletes the cart.
10. Success → `COMMIT`; validation failure/rollback → `ROLLBACK`.

The method therefore performs approximately: 2 load/preload statements + N product lock statements + 1 order insert + S seller-order inserts + N order-item inserts + N stock updates + cart-item deletion work + 1 cart delete, where N is lines and S is sellers.

### `Order#cancel_order`

1. Starts a transaction and locks the order with `SELECT ... FOR UPDATE`.
2. Loads seller orders ordered by ID:
   - `SELECT seller_orders.* FROM seller_orders WHERE order_id = $1 ORDER BY id ASC`.
3. Calls `cancel_by_buyer` for every active cancellable seller part.
4. Each seller cancellation uses its own `with_lock`, updates seller-order status through AASM, restores stock, and refreshes the order.
5. Finally updates the order status/reason/time to canceled.

Because every seller-part callback refreshes the parent, a multi-seller cancellation can repeatedly reload seller orders and execute three aggregate sums. This is correctable query amplification.

### `Order#refresh_status`

1. `seller_orders.reload`:
   - `SELECT seller_orders.* FROM seller_orders WHERE order_id = $1`.
2. Status selection is in Ruby.
3. `order_items.where(seller_order: active_parts)` builds an `IN` predicate using active seller-order IDs.
4. Three separate immediate sums:

```sql
SELECT SUM(subtotal) FROM order_items WHERE order_id = $1 AND seller_order_id IN (...);
SELECT SUM(discount_amount) FROM order_items WHERE order_id = $1 AND seller_order_id IN (...);
SELECT SUM(final_amount) FROM order_items WHERE order_id = $1 AND seller_order_id IN (...);
```

5. One order update writes the derived status and totals.

The three sums should be one SQL aggregate returning all three values.

### `SellerOrder` AASM events

`process!`, `ship!`, and `deliver!` update `seller_orders.status`, then invoke `refresh_order`. Representative write:

```sql
UPDATE seller_orders SET status = $1, updated_at = $2 WHERE id = $3;
```

`reject_order` and `cancel_by_buyer` use `with_lock`, so Rails opens/joins a transaction and locks the seller-order row. Rejection also writes reason/time. Their `close_seller_order` callback restores stock and refreshes the parent.

### `SellerOrder#restore_stock`

1. `order_items.includes(:product).each` loads seller-order lines and their products in two queries.
2. Each product then uses `with_lock`:
   - `SELECT products.* FROM products WHERE id = $1 LIMIT 1 FOR UPDATE`.
3. Each product gets one stock `UPDATE`.

### Seller-order aggregate methods

- `seller_total` → one `SELECT SUM(subtotal) ... WHERE seller_order_id = ?`.
- `promotion_total` → one `SELECT SUM(discount_amount) ... WHERE seller_order_id = ?`.

These always use database aggregates and do not reuse preloaded line objects.

## 8. Current-cart and layout queries

### `ApplicationController#current_cart`

For a buyer, `current_user.cart` loads the has-one association if it is not cached:

```sql
SELECT carts.* FROM carts WHERE carts.buyer_id = $1 LIMIT 1;
```

If no row exists, `current_user.create_cart!` inserts one:

```sql
INSERT INTO carts (buyer_id, created_at, updated_at)
VALUES ($1, $2, $3) RETURNING id;
```

This means merely visiting a page that renders buyer cart UI can create a cart.

### `ApplicationController#cart_item_count`

```sql
SELECT SUM(cart_items.quantity)
FROM cart_items
WHERE cart_items.cart_id = $1;
```

The shared navbar calls it on buyer page renders; Turbo cart updates call it again for the badge.

### `ApplicationController#current_promotion`

If the session contains a promotion code, it first invokes the coupon lookup from section 9. If that code is absent or valid, it returns immediately. If the stored code is invalid, it removes the code from the session and calls `Promotion.best_for(items)` again, which executes the automatic-promotion candidate query. An invalid saved code can therefore cause two promotion queries: one code lookup and one automatic-rule lookup.

### `ApplicationHelper#cart_item_for`

The first call per request executes `current_cart.cart_items.index_by(&:product_id)` when the association is unloaded:

```sql
SELECT cart_items.* FROM cart_items WHERE cart_items.cart_id = $1;
```

It then builds a hash in memory. Later product cards use that hash without one query per product. This is request-level memoization, not a database index or persistent cache.

### `Cart#add_product`

`cart_items.find_by(product_id: product.id)` performs one scoped line lookup. If found, quantity is changed only in memory until the caller saves. If not found, `cart_items.build(...)` constructs an unsaved line with `cart_id` assigned and performs no SQL. `Buyer::CartsController#add_item` is the caller that subsequently invokes `save`.

### `Cart#summary`

When the caller does not pass `items:`, the method executes `cart_items.includes(:product).to_a`, normally loading lines and products with two statements. Subtotal, item count, discounts, and final total are then calculated in Ruby.

The cart controller currently loads `@cart_items` for promotion evaluation and then calls `@cart.summary(@promotion)` without passing those items. Because these are separate relations, Rails can load the same cart items/products again. Passing the already materialized collection as `items:` avoids that duplicate query pair. Checkout intentionally reloads and locks current data later for correctness, so request-display reuse and checkout revalidation should remain separate concerns.

### `CartItem` calculation and mutation methods

- `total_price` is Ruby multiplication, but accessing `product.price` first loads the product by PK if the `belongs_to` association is not already loaded.
- `increase_quantity` and the update branch of `decrease_quantity` call validated `update`; custom validations inspect product stock/active state and can trigger that product lookup.
- the quantity-one branch of `decrease_quantity` calls `destroy`, producing a row delete.

## 9. Promotion queries and calculations

### Coupon-code path in `Promotion.best_for`

```ruby
find_by("LOWER(code) = ?", code.downcase)
```

Representative SQL:

```sql
SELECT promotions.*
FROM promotions
WHERE LOWER(code) = $1
LIMIT 1;
```

PostgreSQL can use the existing unique partial `LOWER(code)` index for non-null codes. Eligibility and the actual discount are calculated in Ruby over loaded cart items/products.

### Automatic-promotion path

The lazy relation is:

```ruby
where(active: true, kind: %i[product_discount category_discount sale])
```

When `max_by` enumerates it:

```sql
SELECT promotions.*
FROM promotions
WHERE promotions.active = TRUE
  AND promotions.kind IN (1, 2, 3);
```

Every returned promotion is then checked in Ruby against every cart line. Time windows, minimum order values, product IDs, and category IDs are not used to reduce the candidate rows in SQL. The winner's discount is calculated again after `max_by`.

### Pure in-memory promotion functions

After items/products and promotions have loaded, these do not themselves issue SQL:

- `discounts_for(items)` uses `items.to_h`.
- `discount_total(items)` uses Ruby hash values and `sum`.
- `eligible?` checks active flag, dates, and cart subtotal in Ruby.
- `discount_for` compares product/category IDs and calculates decimal percentages in Ruby.

`item.product.category_id` reads the foreign-key field from the loaded product; it does not need to load a `Category` row.

## 10. Model validation and association-generated queries

### Uniqueness validations

These can issue a `SELECT 1 ... LIMIT 1` before insert/update:

- `Category.name` globally unique;
- `CartItem.product_id` within `cart_id`;
- `Promotion.code` case-insensitively unique;
- Devise `User.email` unique.

The database unique indexes remain essential because a validation query and insert are not one atomic operation. Categories currently lack that DB unique index.

### Belongs-to validation/access

Rails `belongs_to` is required by default unless `optional: true`. Validation may use an already assigned object; accessing an unloaded association causes a PK lookup. Promotion product/category belongs-to associations are optional at the association layer, with kind-specific presence enforced by custom validations.

### Dependent behavior

- Destroying a cart destroys its cart items.
- Destroying an order destroys seller orders and order items according to model declarations; note that seller-order `order_items` are restrictive, so callback/deletion ordering matters.
- Destroying a user/category/product with restricted children performs dependent existence checks and refuses deletion when children exist.
- Product “destroy” in the seller controller archives instead, so those dependent checks are normally avoided.

## 11. Devise-generated queries not written explicitly in controllers

The application calls `authenticate_user!`, `current_user`, registration, password recovery, remember-me, and sign-out behavior from Devise. Their SQL lives in the Devise gem, not this repository, but common database access includes:

- login/user lookup by normalized email: `SELECT users.* FROM users WHERE email = $1 LIMIT 1`;
- session deserialization/current-user lookup by ID: `SELECT users.* FROM users WHERE id = $1 LIMIT 1` when not already cached;
- registration email uniqueness check and user insert;
- account update: user `UPDATE` after password/validation rules;
- password-reset token lookup and `UPDATE` of token/sent timestamp/password fields;
- remember-me timestamp update when used.

Exact Devise statements depend on Warden session state and configured callbacks. They should be included in request query measurements even though they are not explicit application calls.

## 12. Seed-script queries

Seeds are administrative setup queries, not normal request traffic.

### `db/seeds.rb`

- Three `User.find_or_create_by!(email: ...)` calls: one email lookup each, then an insert only if missing.
- Categories/products/promotions use `find_or_initialize_by`: one lookup each, followed by `update!`, which inserts a new record or updates an existing record.
- Welcome coupon uses `Promotion.find_by("LOWER(code) = ?", ...)`, then `Promotion.new` if missing, followed by `update!`.
- Final `User.count`, `Category.count`, `Product.count`, and `Promotion.count` run four independent `COUNT(*)` statements.

### `db/seed1.rb`

- `User.find_or_initialize_by(email: ...)` performs one user lookup.
- `save!` inserts or updates depending on whether the user existed and changed.

## 13. Query count patterns worth fixing first

| Page/workflow | Current extra work | Recommended change |
|---|---|---|
| Seller order list | one `SUM` per seller order | grouped aggregate or persisted seller-order totals |
| Admin order detail | two `SUM`s per seller part | one grouped aggregate or persisted seller-order totals |
| Buyer order list | one `COUNT` per order despite preload | use association `size` |
| Category detail | count + existence + row load; unused seller preload | avoid redundant count/existence and remove unused preload |
| Order refresh | three scans/sums over same line set | one aggregate select |
| Multi-seller cancellation | refresh/sums repeated per seller part | close parts, then refresh parent once |
| Promotion selection | all active automatic promotions × all cart lines in Ruby | SQL-filter candidates and calculate each once |
| Checkout | one lock/insert/update per line | retain correctness, sort locks; bulk operations only if measured |
| All index pages | no pagination | add pagination and composite indexes |
| Buyer layout | cart lookup and quantity sum on many requests | load a request-scoped cart summary once |

## 14. Representative request-level query flows

### Buyer opens the product index

Likely sequence:

1. Devise current-user lookup if session user is not cached.
2. Product existence check from `@products.any?`.
3. Active products query.
4. Category preload for product cards.
5. All-categories filter query.
6. Current cart lookup; possible cart insert if none exists.
7. Cart-items query for `cart_item_for` hash.
8. Cart quantity sum for navbar badge.

This stays constant with product count because the helper memoizes cart items and categories are preloaded.

### Seller opens order list with N seller orders

Likely sequence:

1. Current-user lookup if necessary.
2. Seller-order existence query from view `any?`.
3. Seller-orders query.
4. Parent-order preload.
5. Order-item preload.
6. N subtotal `SUM` queries.

The last N statements are avoidable.

### Admin opens one order with S seller parts

Likely sequence:

1. Order lookup.
2. Seller-orders query.
3. Sellers preload.
4. Order-items preload.
5. `2 × S` total/discount sum queries.
6. Potential seller-order association query for cancellation eligibility.

### Buyer places an order with N lines and S sellers

The approximate formula is:

- cart/items/product loading: about 2 queries;
- promotion candidate lookup: 1 query;
- N product row locks;
- 1 order insert;
- S seller-order inserts;
- N order-item inserts;
- N product stock updates;
- cart-item deletion work plus 1 cart delete;
- transaction boundary statements.

This workflow is deliberately write-heavy because it preserves stock/order correctness. Optimize lock order and batching carefully; do not trade away transactional integrity merely to reduce statement count.

## 15. Verification notes

This catalog was produced from all current application models, controllers, helpers, relevant views, and seed files. PostgreSQL was not reachable in the workspace, so exact SQL logs and `EXPLAIN` plans could not be captured. To verify the representative SQL against a running database:

1. enable development SQL logs or subscribe to `sql.active_record`;
2. add request query-count tests;
3. use Bullet or strict-loading tests for accidental N+1s;
4. run `EXPLAIN (ANALYZE, BUFFERS)` on the final SQL with production-like volumes;
5. use `pg_stat_statements` to rank actual cumulative cost before adding denormalized structures.
