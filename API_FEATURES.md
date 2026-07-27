# XerinMarket — API Endpoints & Features Reference

## Overview

This document lists all backend API endpoints and their corresponding mobile app features.

---

## 1. Authentication (`/auth`)

| Endpoint | Method | Description |
|---|---|---|
| `/auth/register` | POST | Register a new customer |
| `/auth/register-seller` | POST | Register a new seller |
| `/auth/login` | POST | Login with phone/email + password |
| `/auth/logout` | POST | Logout and invalidate session |
| `/auth/refresh-token` | POST | Refresh access token using refresh token |
| `/auth/send-otp` | POST | Send OTP for phone verification |
| `/auth/verify-otp` | POST | Verify OTP code |
| `/auth/forgot-password` | POST | Request password reset |
| `/auth/reset-password` | POST | Reset password with token |

### Mobile Features:
- Sign in / Sign up screens
- OTP verification flow
- Password reset flow
- Auto token refresh on 401 (interceptor)
- Session management

---

## 2. User Profile (`/users`)

| Endpoint | Method | Description |
|---|---|---|
| `/users/me` | GET | Get current user profile |
| `/users/me` | PATCH | Update current user profile |
| `/addresses` | POST | Create new address |
| `/addresses` | GET | List user addresses |
| `/addresses/{id}` | PATCH | Update address |
| `/addresses/{id}` | DELETE | Delete address |

### Mobile Features:
- Profile info page (view/edit name, email, phone, avatar)
- Address management (add, edit, delete, set default)
- Addresses used in checkout flow

---

## 3. Products (`/products`)

| Endpoint | Method | Description |
|---|---|---|
| `/products` | GET | List products with filters: `search`, `category_id`, `brand_id`, `min_price`, `max_price`, `sort`, `skip`, `limit` |
| `/products` | POST | Create product (seller only) |
| `/products/my-products` | GET | Seller's own products |
| `/products/{id}` | GET | Get single product details |
| `/products/{id}` | PATCH | Update product (seller only) |
| `/products/{id}` | DELETE | Delete product (seller only) |
| `/products/categories` | GET | List all categories |
| `/products/categories` | POST | Create category (admin) |
| `/products/categories/{id}` | GET | Get category by ID |
| `/products/brands` | GET | List all brands |
| `/products/brands` | POST | Create brand (admin) |
| `/products/brands/{id}` | GET | Get brand by ID |
| `/products/{id}/images` | GET | List product images |
| `/products/{id}/images` | POST | Upload product image (seller) |
| `/products/{id}/images/{image_id}` | DELETE | Delete product image |
| `/products/{id}/variants` | GET | List product variants |
| `/products/{id}/variants` | POST | Create variant (seller) |
| `/products/{id}/variants/{variant_id}` | DELETE | Delete variant |
| `/products/{id}/tags` | GET | List product tags |
| `/products/{id}/tags` | POST | Add tag (seller) |
| `/products/{id}/tags/{tag_id}` | DELETE | Delete tag |

### Mobile Features:
- Home page: Featured products carousel
- Explore page: Search, filter by category/brand/price, sort
- Product detail page: Images, variants, tags, add to cart, buy now
- Category browsing
- Seller: Product CRUD, image upload, variant management

---

## 4. Cart (`/cart`)

| Endpoint | Method | Description |
|---|---|---|
| `/cart` | GET | Get current user's cart |
| `/cart/items` | POST | Add item to cart |
| `/cart/items/{id}` | PUT | Update cart item quantity |
| `/cart/items/{id}` | DELETE | Remove item from cart |
| `/cart` | DELETE | Clear entire cart |
| `/cart/apply-coupon` | POST | Apply coupon code to cart |
| `/cart/coupon` | DELETE | Remove coupon from cart |

### Mobile Features:
- Cart page: View items, change quantity, remove items
- Cart badge count in dashboard bottom nav
- Apply/remove coupon codes
- Cart total calculation with discounts
- Add to cart from product detail page

---

## 5. Orders (`/orders`)

| Endpoint | Method | Description |
|---|---|---|
| `/orders` | POST | Create order from cart |
| `/orders/my-orders` | GET | List user's orders (paginated: `page`, `page_size`) |
| `/orders/{id}` | GET | Get order details |
| `/orders/{id}/status` | PATCH | Update order status (seller/admin) |

### Mobile Features:
- Checkout page: Select address, add notes, place order
- Order history page: Filter by status, view all orders
- Order detail page: Items, summary, status history, track button
- Order tracking page: Visual timeline (Placed → Processing → Shipped → Delivered)
- Seller: View and update order statuses

---

## 6. Payments (`/payments`)

| Endpoint | Method | Description |
|---|---|---|
| `/payments/initiate` | POST | Initiate payment for an order |
| `/payments/callback` | POST | Payment callback from provider |
| `/payments/callback/{provider}` | POST | Provider-specific callback |
| `/payments/{id}` | GET | Get payment status |

### Mobile Features:
- Payment initiation after order creation
- Payment status tracking
- Payment method management (see below)

---

## 7. Payment Methods (`/payment-methods`)

| Endpoint | Method | Description |
|---|---|---|
| `/payment-methods` | GET | List user's saved payment methods |
| `/payment-methods` | POST | Add new payment method |
| `/payment-methods/{id}` | DELETE | Remove payment method |

### Mobile Features:
- Payment methods page: Add, view, delete cards/accounts
- Select payment method during checkout

---

## 8. Coupons (`/coupons`)

| Endpoint | Method | Description |
|---|---|---|
| `/coupons` | GET | List coupons (`active_only` filter) |
| `/coupons` | POST | Create coupon (admin) |
| `/coupons/{id}` | GET | Get coupon by ID |

### Mobile Features:
- Coupons page: Browse available coupons, discount display, expiry status
- Apply coupon in cart
- Apply coupon during checkout

---

## 9. Stores (`/stores`)

| Endpoint | Method | Description |
|---|---|---|
| `/stores` | GET | List all public stores (paginated: `page`, `page_size`, `search`) |
| `/stores/{slug}` | GET | Get public store by slug |
| `/stores/me` | GET | Get seller's own store |
| `/stores/me` | PATCH | Update store |
| `/stores/me/logo` | POST | Upload store logo |
| `/stores/me/banner` | POST | Upload store banner |
| `/stores/me/gallery` | GET | List gallery images |
| `/stores/me/gallery` | POST | Add gallery image |
| `/stores/me/opening-hours` | GET | List opening hours |
| `/stores/me/opening-hours` | POST | Add opening hours |

### Mobile Features:
- Stores page: Browse all stores with banners, logos, ratings, verified badges
- Store detail: View store info and products
- Seller: Store management (logo, banner, gallery, opening hours)

---

## 10. Seller (`/sellers`)

| Endpoint | Method | Description |
|---|---|---|
| `/sellers/me` | GET | Get seller profile |
| `/sellers/me` | PATCH | Update seller profile |
| `/sellers/profile` | GET | Get seller business profile |
| `/sellers/profile` | PATCH | Update business profile |
| `/sellers/kyc-documents` | POST | Upload KYC document |
| `/sellers/kyc-documents` | GET | List KYC documents |
| `/sellers/kyc-documents/bulk` | POST | Bulk upload KYC documents |
| `/sellers/kyc-status` | GET | Check KYC verification status |
| `/sellers/payout-accounts` | POST | Add payout account |
| `/sellers/payout-accounts` | GET | List payout accounts |
| `/sellers/payout-accounts/{id}` | DELETE | Remove payout account |
| `/sellers/admin/pending` | GET | List pending sellers (admin) |
| `/sellers/admin/{id}/documents` | GET | View seller documents (admin) |
| `/sellers/admin/{id}/approve` | POST | Approve seller (admin) |
| `/sellers/admin/{id}/reject` | POST | Reject seller (admin) |

### Mobile Features:
- Seller onboarding flow
- KYC document upload
- Payout account management
- Seller dashboard with analytics
- Seller profile and shop details

---

## 11. Admin (`/admin`)

| Endpoint | Method | Description |
|---|---|---|
| `/admin/users` | GET | List all users |
| `/admin/users` | POST | Create admin user |
| `/admin/users/{id}` | GET | Get user by ID |
| `/admin/users/{id}` | PATCH | Update user |
| `/admin/users/{id}` | DELETE | Delete user |
| `/admin/admins` | POST | Create admin |
| `/admin/business-categories` | GET/POST | List/create business categories |
| `/admin/business-categories/{id}` | PATCH/DELETE | Update/delete business category |
| `/admin/product-categories` | GET/POST | List/create product categories |
| `/admin/product-categories/{id}` | DELETE | Delete product category |
| `/admin/brands` | GET/POST | List/create brands |
| `/admin/brands/{id}` | DELETE | Delete brand |
| `/admin/sellers` | GET | List all sellers |
| `/admin/sellers/pending` | GET | List pending seller approvals |
| `/admin/sellers/{id}` | GET | Get seller details |
| `/admin/sellers/{id}/documents` | GET | View seller documents |
| `/admin/sellers/{id}/approve` | POST | Approve seller |
| `/admin/sellers/{id}/reject` | POST | Reject seller |
| `/admin/products/pending` | GET | List pending product approvals |
| `/admin/products/{id}/approve` | POST | Approve product |
| `/admin/products/{id}/reject` | POST | Reject product |

### Mobile Features:
- Admin user management
- Seller approval/rejection
- Product approval/rejection
- Category and brand management

---

## 12. Inventory (`/inventory`)

| Endpoint | Method | Description |
|---|---|---|
| `/inventory` | POST | Create inventory record |
| `/inventory/my-inventory` | GET | Seller's inventory |
| `/inventory/low-stock` | GET | Low stock alerts |
| `/inventory/product/{product_id}` | GET | Inventory by product |
| `/inventory/{id}` | GET/PATCH | Get/update inventory item |

### Mobile Features:
- Seller inventory management
- Low stock alerts
- Stock level tracking

---

## 13. Notifications (`/notifications`)

| Endpoint | Method | Description |
|---|---|---|
| `/notifications` | GET | List user notifications |
| `/notifications/{id}/read` | PATCH | Mark notification as read |
| `/notifications/read-all` | PATCH | Mark all as read |

### Mobile Features:
- Notifications page: View, mark read, mark all read
- Notification badges

---

## 14. Wishlist (`/wishlists`)

| Endpoint | Method | Description |
|---|---|---|
| `/wishlists` | GET | Get user's wishlist |
| `/wishlists/toggle/{product_id}` | POST | Toggle product in wishlist |
| `/wishlists/{id}` | DELETE | Remove wishlist item |

### Mobile Features:
- Wishlist page: View saved products
- Add/remove from wishlist (product detail, product cards)
- Guest mode prompt for wishlist

---

## Recommendation Features (Mobile App)

These features use existing `/products` endpoint with filters:

| Feature | API Used | Parameters |
|---|---|---|
| For You / Recommended | `GET /products` | `sort=featured&limit=20` |
| Trending Now | `GET /products` | `sort=popularity&limit=20` |
| Flash Deals | `GET /products` | `sale_price__gt=0&sort=discount&limit=20` |
| New Arrivals | `GET /products` | `sort=created_at&limit=20` |
| Top Rated | `GET /products` | `sort=rating&limit=20` |
| Best Sellers | `GET /products` | `sort=sales&limit=20` |
| Recently Viewed | Local storage | Stored on device, synced when available |
| Related Products | `GET /products` | `category_id={cat}&limit=10` (same category) |

### Mobile Pages:
- **For You Page** — Personalized recommendations with match reasons
- **Trending Page** — Flash deals with countdown timers + trending grid
- **Recently Viewed Page** — Products user has browsed
- **Stores Page** — Browse all stores with ratings and badges
- **Coupons Page** — Available coupons with discount display
- **Order Tracking Page** — Visual status timeline

---

## Mobile App Architecture

```
mobile/
├── lib/
│   ├── config/
│   │   ├── constants/     # API endpoints, app constants
│   │   ├── di/            # Service locator (GetIt)
│   │   ├── routes/        # GoRouter configuration
│   │   └── theme/         # Light/dark themes
│   ├── core/
│   │   ├── network/       # Dio client + interceptors
│   │   ├── storage/       # Token storage
│   │   └── errors/        # Custom exceptions
│   ├── features/
│   │   ├── auth/          # Login, register, OTP, password reset
│   │   ├── customer/      # Products, cart, orders, checkout, recommendations
│   │   ├── seller/        # Dashboard, products, KYC, payouts
│   │   ├── onboarding/    # First-time user onboarding
│   │   └── splash/        # Auth routing
│   └── app.dart           # Root widget + MultiBlocProvider
```

### State Management: Cubit (flutter_bloc)
### HTTP Client: Dio with interceptors
### Routing: GoRouter
### DI: GetIt

---

## 🔴 MISSING ENDPOINTS — Backend Needs to Implement

Hizi endpoints hazipo kwenye backend kwa sasa. Mobile app inahitaji backend developer azifanye:

### 1. Product Recommendations (`/products`)

| Endpoint | Method | Description | Parameters | Response |
|---|---|---|---|---|
| `/products/recommended` | GET | Products recommended for the current user based on browsing history, purchases, and preferences | `limit` (int, default 20) | `List[{product: ProductResponse, match_score: float, reason: string}]` |
| `/products/trending` | GET | Most viewed/purchased products in the last 7 days | `limit` (int, default 20) | `List[ProductResponse]` |
| `/products/flash-deals` | GET | Active flash deals (products with sale_price or special discount) | `limit` (int, default 20) | `List[{product: ProductResponse, original_price: float, deal_price: float, discount_percentage: float, end_date: string}]` |
| `/products/recently-viewed` | GET | Products the current user has recently viewed | `limit` (int, default 20) | `List[ProductResponse]` |
| `/products/{product_id}/related` | GET | Products related to the given product (same category, similar tags, same brand) | `limit` (int, default 10) | `List[ProductResponse]` |
| `/products/new-arrivals` | GET | Products sorted by `created_at` descending (newest first) | `limit` (int, default 20) | `List[ProductResponse]` |
| `/products/top-rated` | GET | Products sorted by `rating` descending | `limit` (int, default 20) | `List[ProductResponse]` |
| `/products/best-sellers` | GET | Products with highest sales count | `limit` (int, default 20) | `List[ProductResponse]` |

#### Notes for Backend Developer:
- All endpoints require authentication (`get_current_user`)
- `recommended` should use a simple algorithm: products from categories the user has ordered from, products from stores they've interacted with, or fallback to popular products
- `trending` can be based on order_items count in last 7 days or product views
- `flash-deals` should return products where `sale_price` is not null and `sale_price < price`
- `recently-viewed` requires a `recently_viewed` table or similar tracking mechanism
- `related` should query same `category_id` excluding the current product
- `new-arrivals`, `top-rated`, `best-sellers` can be simple sorted queries on existing `products` table

---

### 2. Store Products (`/stores`)

| Endpoint | Method | Description | Parameters | Response |
|---|---|---|---|---|
| `/stores/{slug}/products` | GET | List all products from a specific store | `skip`, `limit` | `List[ProductResponse]` |

#### Notes for Backend Developer:
- Query `products` table where `seller_id` matches the store's `seller_id`
- Should be public (no auth required)
- Support pagination with `skip` and `limit`

---

### 3. Coupon Validation (`/coupons`)

| Endpoint | Method | Description | Parameters | Response |
|---|---|---|---|---|
| `/coupons/validate/{code}` | GET | Validate a coupon code and return coupon details if valid | `code` (path) | `CouponResponse` with `is_valid`, `discount_amount` calculated |

#### Notes for Backend Developer:
- Check if coupon exists, is active, not expired, usage limit not exceeded
- Return calculated discount amount based on `discount_type` (percentage or fixed)
- If invalid, return 404 or 400 with error message

---

### 4. Recently Viewed Tracking

| Endpoint | Method | Description | Parameters | Response |
|---|---|---|---|---|
| `/products/{product_id}/view` | POST | Record that the current user viewed a product | `product_id` (path) | `204 No Content` |

#### Notes for Backend Developer:
- Create a `recently_viewed` table: `id`, `user_id`, `product_id`, `viewed_at`
- On POST, insert or update `viewed_at` to now
- Used by `/products/recently-viewed` endpoint above
- Requires authentication

---

### Summary Table

| # | Endpoint | Priority | Complexity |
|---|---|---|---|
| 1 | `GET /products/recommended` | High | Medium (needs recommendation logic) |
| 2 | `GET /products/trending` | High | Low (query order_items count) |
| 3 | `GET /products/flash-deals` | High | Low (filter sale_price) |
| 4 | `GET /products/recently-viewed` | Medium | Medium (needs new table) |
| 5 | `GET /products/{id}/related` | High | Low (same category query) |
| 6 | `GET /products/new-arrivals` | Low | Low (sort by created_at) |
| 7 | `GET /products/top-rated` | Low | Low (sort by rating) |
| 8 | `GET /products/best-sellers` | Medium | Low (sort by sales count) |
| 9 | `GET /stores/{slug}/products` | High | Low (filter by seller_id) |
| 10 | `GET /coupons/validate/{code}` | Medium | Low (query + validate) |
| 11 | `POST /products/{id}/view` | Medium | Low (insert into table) |
