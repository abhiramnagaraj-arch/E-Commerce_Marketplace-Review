Your next task should not be promotions immediately. First make checkout, stock, order history, cancellation, and administration reliable. Promotions depend on all of them.

## Recommended build order

1. Ecommerce correctness
2. Admin section
3. Order state management with AASM
4. Promotion foundation
5. Promotion types
6. Promotion integration with cart and checkout
7. Focused verification

---

## 1. Fix these ecommerce issues first

### Inventory handling

Currently, placing an order does not properly reserve or reduce product stock.

Implement:

- Check stock again during checkout.
- Lock products while creating the order.
- Reduce stock inside the same database transaction.
- Roll everything back if one product has insufficient stock.
- Restore stock when an order is canceled.

The cart validation is useful, but checkout must perform the final stock check because stock may change after the product was added.

### Order snapshots

Historical orders should not change when a seller edits a product.

Add to `order_items`:

- `product_title`
- `discount_amount`
- `final_amount`

The existing `price` already acts as a price snapshot.

An order item should retain its title, original price, discount, and final amount permanently.

### Product deletion

Replace permanent deletion with simple archiving:

```text
products.active = true / false
```

Why:

- Products referenced by old orders must remain.
- Sellers should see “Archive product” instead of deleting database records.
- Buyers only see active products.

Avoid adding a soft-delete gem. One boolean is enough.

### Database constraints

Add:

- Unique index on `cart_items(cart_id, product_id)`.
- `null: false` for product seller, order buyer, and cart buyer after existing data is backfilled.
- Stock cannot be negative.
- Quantity must be positive.

### Money calculations

Use decimal values throughout.

Avoid:

- Floats
- JavaScript price calculations
- Totals received through form parameters

The backend must always recalculate the order immediately before saving it.

---

## 2. Admin design

Adding an admin role is the correct direction.

Update the existing user roles:

```ruby
enum :role, {
  buyer: 0,
  seller: 1,
  admin: 2
}
```

Create:

```text
app/controllers/admin/
  base_controller.rb
  dashboard_controller.rb
  categories_controller.rb
  promotions_controller.rb
  orders_controller.rb
```

The base controller should contain only:

- Authentication
- Admin-role verification

### Admin pages

Build these pages:

```text
/admin
/admin/categories
/admin/promotions
/admin/orders
```

Admin responsibilities:

- Add and edit categories.
- Create and manage promotions.
- Activate and deactivate promotions.
- View all orders.
- Move orders through valid states.
- Cancel eligible orders.

Sellers should only read categories. Categories are shared across the entire store, so individual sellers should not rename or delete them.

### Do not permanently delete promotions

Promotions used by historical orders should remain available.

Use:

```text
active = false
```

instead of deleting them.

---

## 3. Order state management with AASM

AASM supports Active Record state transitions and transaction-backed events, making it suitable for this order workflow. [Official AASM documentation](https://github.com/aasm/aasm)

Use this simple lifecycle:

```text
confirmed → processing → shipped → delivered
     │           │
     └───────────┴────→ canceled
```

Do not add more states until payment processing exists.

### Events

```text
process
ship
deliver
cancel
```

Rules:

- `confirmed` can become `processing` or `canceled`.
- `processing` can become `shipped` or `canceled`.
- `shipped` can only become `delivered`.
- `delivered` and `canceled` are final.
- A shipped order cannot be canceled.

### Order fields

Add:

```text
status
canceled_at
cancel_reason
```

### Cancellation flow

Buyer:

```text
Order page
  → Cancel button
  → Enter reason
  → Order#cancel_order!
  → AASM moves order to canceled
  → Stock is restored
  → Buyer sees confirmation
```

Admin uses the same model method.

Response messages:

```text
Order canceled successfully. Product stock has been restored.
```

Invalid transition:

```text
This order can no longer be canceled because it has already shipped.
```

The view should only check:

```ruby
@order.may_cancel?
```

It should not contain status-transition logic.

### Keep stock logic in `Order`

Recommended methods:

```ruby
reserve_stock!
restore_stock!
cancel_order!(reason)
```

The controller should only call the method and redirect.

---

## 4. Unified promotion design

Do not create separate models such as:

```text
Coupon
ProductOffer
CategoryOffer
SaleOffer
FirstOrderOffer
BuyGetOffer
```

That creates repeated code.

Use one `Promotion` model with a `kind` enum.

Rename the existing `coupons` table to `promotions` and extend it.

### Promotion kinds

| Kind | Applies to | Required configuration |
|---|---|---|
| `coupon` | Entire eligible cart | Code and minimum cart value |
| `product_discount` | One product | Product and discount percentage |
| `category_discount` | Products in one category | Category and percentage |
| `buy_x_get_y` | Specific product quantities | Buy product, get product, X and Y |
| `sale` | Entire cart during a period | Percentage and dates |
| `first_order` | Buyer’s first valid order | Percentage and optional minimum |

This gives you six promotion types without six models.

### Keep the first version percentage-only

Use:

```text
discount_percent
```

Do not initially support both fixed and percentage discounts. Fixed discounts create allocation and rounding complexity.

They can be added later with:

```text
discount_type: percentage / fixed
```

### Promotion columns

```text
name
kind
code
discount_percent
min_order_amount
product_id
category_id
buy_product_id
get_product_id
buy_quantity
get_quantity
starts_at
ends_at
active
```

Most columns will be nullable depending on the promotion kind. That is acceptable and simpler than polymorphic tables or JSON rules.

---

## 5. Promotion model structure

Keep all promotion rules in one model with small private methods.

Suggested public interface:

```ruby
Promotion.active_now
Promotion.automatic
promotion.eligible?(cart, buyer, code: nil)
promotion.discounts_for(cart)
```

Private methods:

```ruby
coupon_discount
product_discount
category_discount
buy_x_get_y_discount
sale_discount
first_order_discount
```

Use validations based on `kind`:

- Coupon requires a unique code.
- Product discount requires a product.
- Category discount requires a category.
- Buy-X-get-Y requires both products and quantities.
- Sale requires start and end dates.
- First-order promotion does not require a target.

Do not build:

- A rule engine
- JSON conditions
- STI subclasses
- Polymorphic promotion targets
- One service class per promotion

Those would be unnecessary for this project.

---

## 6. Promotion selection rule

Do not support stacking initially.

Use exactly one promotion per cart.

Recommended rule:

1. If the buyer enters a valid coupon, use that coupon.
2. Otherwise evaluate automatic promotions.
3. Apply the automatic promotion producing the largest valid discount.
4. Display the applied promotion’s name.
5. Recalculate it again during checkout.

This prevents combinations such as:

```text
Coupon + product discount + category discount + first-order discount
```

Promotion stacking can become extremely difficult to reason about.

---

## 7. Buy-X-get-Y rule

Implement this last because it is the most complicated promotion.

For the first version:

- Buyer must add both X and Y products to the cart.
- The backend marks the eligible Y quantity as free.
- Do not automatically insert products into the cart.

Example:

```text
Buy 2 laptops
Get 1 mouse free
```

Calculation:

```text
eligible_free_quantity =
  number_of_laptops / 2

actual_free_quantity =
  minimum of eligible_free_quantity and mouse quantity
```

For the same-product case:

```text
Buy 2, get 1 of the same product
```

Every group of three contains one free item.

Clearly separate the same-product and different-product calculations into two private methods.

---

## 8. Backend pricing structure

Let `Cart` remain the central pricing object.

Suggested interface:

```ruby
cart.pricing_for(buyer, code: nil)
```

It should return:

```ruby
{
  lines: {
    cart_item_id => {
      subtotal: ...,
      discount: ...,
      total: ...
    }
  },
  subtotal: ...,
  discount: ...,
  total: ...,
  promotion: ...
}
```

All values are calculated in Ruby models.

The view only does this:

```erb
<%= @pricing[:subtotal] %>
<%= @pricing[:discount] %>
<%= @pricing[:total] %>
```

No multiplication, percentage calculation, promotion lookup, or minimum-cart checking belongs in ERB or JavaScript.

---

## 9. Checkout flow

The final checkout flow should be:

```text
Buyer changes cart
    ↓
Cart calculates current pricing
    ↓
Buyer opens checkout
    ↓
Backend displays pricing
    ↓
Buyer submits address
    ↓
Backend starts transaction
    ↓
Locks products
    ↓
Checks stock
    ↓
Recalculates promotion
    ↓
Creates order and order-item snapshots
    ↓
Reduces stock
    ↓
Confirms order
    ↓
Clears cart
```

Never reuse a total submitted by the browser.

### Promotion snapshots on orders

Add to `orders`:

```text
promotion_id
promotion_name
promotion_code
discount_amount
```

Add to `order_items`:

```text
subtotal
discount_amount
final_amount
product_title
```

This ensures old orders remain accurate even if an admin edits or deactivates the promotion.

---

## 10. Controller/model balance

### Models

`Cart`

- Quantity-independent pricing summary
- Promotion selection
- Subtotal and final total

`CartItem`

- Increment/decrement
- Stock validation
- Line subtotal

`Promotion`

- Eligibility
- Promotion-specific discounts
- Date and target validations

`Order`

- AASM transitions
- Stock reservation/restoration
- Cancellation

`OrderItem`

- Historical product and price snapshot

### Controllers

Controllers should only:

- Load records
- Authorize the user
- Call one model method
- Redirect or render

Example target:

```ruby
def cancel
  @order.cancel_order!(params[:reason])
  redirect_to buyer_order_path(@order), notice: "Order canceled successfully."
rescue AASM::InvalidTransition
  redirect_to buyer_order_path(@order), alert: "This order cannot be canceled."
end
```

Avoid placing stock loops, promotion selection, percentage calculations, or order totals in controllers.

---

## 11. Suggested implementation phases

### Phase 1: Ecommerce foundation

- Product archiving
- Order-item snapshots
- Checkout transaction
- Stock reduction
- Cart-item uniqueness
- Decimal-only calculation
- Admin role
- Admin category management

### Phase 2: Order states

- Add AASM
- Add order transitions
- Admin order management
- Buyer cancellation
- Stock restoration
- Cancellation UI responses

### Phase 3: Promotion foundation

- Rename Coupon to Promotion
- Add promotion fields
- Build admin promotion CRUD
- Add activation and date validation
- Store promotion snapshots on orders

### Phase 4: First four promotions

Implement in this order:

1. Coupon
2. Product discount
3. Category discount
4. Scheduled sale

These share straightforward percentage calculations.

### Phase 5: Conditional promotions

5. First-order discount  
6. Buy-X-get-Y

Build BOGO last.

### Phase 6: Checkout integration

- One-promotion selection
- Backend line pricing
- Checkout recalculation
- Order snapshots
- Promotion display on cart and orders

---

## Minimal verification matrix

Even with a small codebase, these cases are non-negotiable:

- Product cannot be purchased above stock.
- Order placement reduces stock.
- Failed checkout does not partially reduce stock.
- Cancellation restores stock once.
- Shipped order cannot be canceled.
- Expired promotion does not apply.
- Product promotion affects only its product.
- Category promotion affects only that category.
- First-order offer does not apply twice.
- BOGO never gives more free products than are in the cart.
- Seller cannot access admin pages.
- Buyer cannot access admin pages.
- Checkout ignores totals sent by the browser.

The best immediate next step is **Phase 1: ecommerce foundation**, especially transactional checkout, stock changes, product archiving, order snapshots, and the admin role. Promotions should begin only after those are reliable.