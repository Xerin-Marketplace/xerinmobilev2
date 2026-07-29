#!/bin/bash
# ============================================================
# XerinMarket Seed Data Script (100 products with images)
# ============================================================
# This script:
#   1. SSH to server → fix super_admin role + create approved
#      seller for Ezra (airezra2@gmail.com) + business categories
#   2. API → create product categories + brands
#   3. API → create 100 products (as Ezra) + add images
#   4. API → approve all products (as admin)
#
# Usage:
#   bash seed_data.sh                          # default SSH
#   bash seed_data.sh --no-ssh                 # skip SSH step (if already fixed)
#   SSH_USER=root SSH_HOST=187.124.32.94 \
#   BACKEND_PATH=/root/Xerin-Gateway/BACKEND \
#   bash seed_data.sh
# ============================================================

set -e

API="http://187.124.32.94:8080"
SSH_USER="${SSH_USER:-root}"
SSH_HOST="${SSH_HOST:-187.124.32.94}"
BACKEND_PATH="${BACKEND_PATH:-/root/Xerin-Gateway/BACKEND}"
EZRA_EMAIL="airezra2@gmail.com"
EZRA_PASSWORD="mc544aar"
ADMIN_EMAIL="superadmin@xerin.com"
ADMIN_PASSWORD="SuperAdmin123"
DO_SSH=true

if [ "$1" = "--no-ssh" ]; then
  DO_SSH=false
fi

# Helper: extract JSON field
jval() {
  python3 -c "import sys,json; print(json.load(sys.stdin).get('$1',''))" 2>/dev/null
}

# Helper: create product + add images
create_product() {
  local name="$1" slug="$2" cat_id="$3" brand_id="$4" desc="$5" price="$6" sale="$7"
  local sku="SEED-$(echo "$slug" | tr '[:lower:]' '[:upper:]' | head -c 20)-$(printf '%03d' $PNUM)"

  local body="{\"category_id\":\"$cat_id\""
  if [ -n "$brand_id" ]; then body="$body,\"brand_id\":\"$brand_id\""; fi
  body="$body,\"sku\":\"$sku\",\"name\":\"$name\",\"slug\":\"$slug\",\"description\":\"$desc\",\"price\":$price"
  if [ -n "$sale" ]; then body="$body,\"sale_price\":$sale"; fi
  body="$body,\"currency\":\"TZS\"}"

  local resp
  resp=$(curl -s -X POST "$API/products" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $EZRA_TOKEN" \
    -d "$body")

  local pid
  pid=$(echo "$resp" | jval id)

  if [ -n "$pid" ]; then
    # Add 3 images per product
    for i in 1 2 3; do
      curl -s -X POST "$API/products/$pid/images" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $EZRA_TOKEN" \
        -d "{\"image_url\":\"https://picsum.photos/seed/${slug}-${i}/600/600\",\"is_primary\":$([ $i -eq 1 ] && echo true || echo false)}" > /dev/null
    done
    echo "  ✅ [$PNUM] $name"
  else
    echo "  ⚠️  [$PNUM] $name (skipped or error)"
  fi
}

echo ""
echo "=========================================="
echo "  XerinMarket Seed Data (100 products)"
echo "=========================================="

# ============================================================
# STEP 1: SSH — Fix super_admin role + create Ezra seller
# ============================================================
if [ "$DO_SSH" = true ]; then
  echo ""
  echo "[1/5] SSH: Fixing super_admin role + creating Ezra seller..."
  echo "  Connecting to $SSH_USER@$SSH_HOST..."

  ssh "$SSH_USER@$SSH_HOST" "cd $BACKEND_PATH && python3 -c \"
from api.database import SessionLocal
from api.models import User, Role, UserRole, Seller, SellerStatus, BusinessCategory, UserStatus
from api.security import hash_password
import datetime

db = SessionLocal()

# 1. Fix super_admin role
admin = db.query(User).filter(User.email == 'superadmin@xerin.com').first()
if admin:
    role = db.query(Role).filter(Role.name == 'super_admin').first()
    if not role:
        role = Role(name='super_admin', description='Full system owner')
        db.add(role); db.commit(); db.refresh(role)
    existing = db.query(UserRole).filter(UserRole.user_id == admin.id, UserRole.role_id == role.id).first()
    if not existing:
        db.add(UserRole(user_id=admin.id, role_id=role.id)); db.commit()
    admin.status = UserStatus.active
    admin.is_verified = True
    db.commit()
    print('  Super admin role fixed')
else:
    admin = User(first_name='Super', last_name='Admin', email='superadmin@xerin.com', phone='255767939809', password_hash=hash_password('SuperAdmin123'), status=UserStatus.active, is_verified=True)
    db.add(admin); db.commit(); db.refresh(admin)
    role = db.query(Role).filter(Role.name == 'super_admin').first()
    if not role:
        role = Role(name='super_admin', description='Full system owner')
        db.add(role); db.commit(); db.refresh(role)
    db.add(UserRole(user_id=admin.id, role_id=role.id)); db.commit()
    print('  Super admin created')

# 2. Create approved seller for Ezra
ezra = db.query(User).filter(User.email == 'airezra2@gmail.com').first()
if ezra:
    seller = db.query(Seller).filter(Seller.user_id == ezra.id).first()
    if not seller:
        seller = Seller(user_id=ezra.id, business_name='Ezra Tech Store', contact_email='airezra2@gmail.com', contact_phone='+255613976254', status=SellerStatus.approved, agreement_accepted=True, approved_at=datetime.datetime.now(datetime.timezone.utc))
        db.add(seller); db.commit(); db.refresh(seller)
        print('  Ezra seller created (approved)')
    elif seller.status != SellerStatus.approved:
        seller.status = SellerStatus.approved
        seller.approved_at = datetime.datetime.now(datetime.timezone.utc)
        db.commit()
        print('  Ezra seller approved')
    else:
        print('  Ezra seller already approved')
else:
    print('  WARNING: Ezra user not found!')

# 3. Create business categories
biz_cats = [
    ('Fashion & Clothing', 'fashion', 'Apparel, shoes, and accessories'),
    ('Electronics & Technology', 'electronics', 'Phones, computers, and gadgets'),
    ('Food & Grocery', 'food', 'Food items and groceries'),
    ('Beauty & Cosmetics', 'beauty', 'Beauty products and cosmetics'),
    ('Health & Pharmacy', 'health', 'Health products and medicine'),
    ('Home & Furniture', 'home', 'Home decor and furniture'),
    ('Sports & Fitness', 'sports', 'Sports equipment and fitness gear'),
    ('Books & Stationery', 'books', 'Books, office supplies, and stationery'),
    ('Toys & Kids', 'toys', 'Toys and kids items'),
    ('Automotive', 'automotive', 'Car parts and automotive items'),
    ('General Retail', 'general', 'General retail items'),
]
for name, slug, desc in biz_cats:
    existing = db.query(BusinessCategory).filter(BusinessCategory.slug == slug).first()
    if not existing:
        db.add(BusinessCategory(name=name, slug=slug, description=desc, active=True))
db.commit()
print('  Business categories ready')

db.close()
print('  SSH step complete')
\""
else
  echo ""
  echo "[1/5] Skipping SSH step (--no-ssh)"
fi

# ============================================================
# STEP 2: Login as Ezra + create categories & brands
# ============================================================
echo ""
echo "[2/5] Logging in as Ezra ($EZRA_EMAIL)..."

EZRA_TOKEN=$(curl -s -X POST "$API/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EZRA_EMAIL\",\"password\":\"$EZRA_PASSWORD\"}" | jval access_token)

if [ -z "$EZRA_TOKEN" ]; then
  echo "  ❌ Failed to login as Ezra"
  exit 1
fi
echo "  ✅ Logged in as Ezra"

# ─── Create product categories ───
echo ""
echo "  Creating product categories..."

CATS='[
  ["Smartphones","smartphones"],
  ["Laptops","laptops"],
  ["Audio","audio"],
  ["Cameras","cameras"],
  ["Wearables","wearables"],
  ["Gaming","gaming"],
  ["Men Fashion","men-fashion"],
  ["Women Fashion","women-fashion"],
  ["Shoes","shoes"],
  ["Bags & Accessories","bags-accessories"],
  ["Home Appliances","home-appliances"],
  ["Kitchen","kitchen"],
  ["Furniture","furniture"],
  ["Beauty","beauty-products"],
  ["Health","health-products"],
  ["Sports","sports-equipment"],
  ["Fitness","fitness"],
  ["Books","books"],
  ["Toys","toys-kids"],
  ["Automotive","automotive-parts"]
]'

# Read existing categories
EXISTING_CATS=$(curl -s "$API/products/categories")

declare -A CAT_ID
for i in $(seq 0 19); do
  cname=$(echo "$CATS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[$i][0])")
  cslug=$(echo "$CATS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[$i][1])")

  # Check if already exists
  cid=$(echo "$EXISTING_CATS" | python3 -c "import sys,json; cats=json.load(sys.stdin); print(next((c['id'] for c in cats if c['slug']=='$cslug'), ''))" 2>/dev/null)

  if [ -z "$cid" ]; then
    cid=$(curl -s -X POST "$API/products/categories" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $EZRA_TOKEN" \
      -d "{\"name\":\"$cname\",\"slug\":\"$cslug\"}" | jval id)
  fi
  CAT_ID[$cslug]=$cid
  echo "    ✅ $cname"
done

# ─── Create brands ───
echo ""
echo "  Creating brands..."

BRANDS='[
  ["Samsung","samsung"],["Apple","apple"],["Sony","sony"],
  ["Nike","nike"],["LG","lg"],["HP","hp"],["Dell","dell"],
  ["Lenovo","lenovo"],["Asus","asus"],["Acer","acer"],
  ["Bose","bose"],["JBL","jbl"],["Canon","canon"],
  ["Nikon","nikon"],["GoPro","gopro"],["Adidas","adidas"],
  ["Puma","puma"],["Under Armour","under-armour"],
  ["IKEA","ikea"],["Philips","philips"],["Generic","generic"]
]'

EXISTING_BRANDS=$(curl -s "$API/products/brands")

declare -A BRAND_ID
for i in $(seq 0 20); do
  bname=$(echo "$BRANDS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[$i][0])")
  bslug=$(echo "$BRANDS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[$i][1])")

  bid=$(echo "$EXISTING_BRANDS" | python3 -c "import sys,json; brands=json.load(sys.stdin); print(next((b['id'] for b in brands if b['slug']=='$bslug'), ''))" 2>/dev/null)

  if [ -z "$bid" ]; then
    bid=$(curl -s -X POST "$API/products/brands" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $EZRA_TOKEN" \
      -d "{\"name\":\"$bname\",\"slug\":\"$bslug\"}" | jval id)
  fi
  BRAND_ID[$bslug]=$bid
done
echo "    ✅ 21 brands ready"

# ============================================================
# STEP 3: Create 100 products with images
# ============================================================
echo ""
echo "[3/5] Creating 100 products with images..."

PNUM=0

# ─── Smartphones (15) ───
PNUM=$((PNUM+1)); create_product "iPhone 15 Pro Max 256GB" "iphone-15-pro-max-256gb" "${CAT_ID[smartphones]}" "${BRAND_ID[apple]}" "iPhone 15 Pro Max with A17 Pro chip, titanium body, 256GB storage, 48MP camera system." 3200000 ""
PNUM=$((PNUM+1)); create_product "iPhone 15 Pro 128GB" "iphone-15-pro-128gb" "${CAT_ID[smartphones]}" "${BRAND_ID[apple]}" "iPhone 15 Pro with A17 Pro chip, 128GB storage, pro camera system." 2800000 ""
PNUM=$((PNUM+1)); create_product "iPhone 15 128GB" "iphone-15-128gb" "${CAT_ID[smartphones]}" "${BRAND_ID[apple]}" "iPhone 15 with A16 chip, dynamic island, 128GB storage." 2200000 ""
PNUM=$((PNUM+1)); create_product "Samsung Galaxy S24 Ultra" "samsung-galaxy-s24-ultra" "${CAT_ID[smartphones]}" "${BRAND_ID[samsung]}" "Galaxy S24 Ultra with 512GB storage, 12GB RAM, 200MP camera, S Pen." 2500000 2300000
PNUM=$((PNUM+1)); create_product "Samsung Galaxy S24 Plus" "samsung-galaxy-s24-plus" "${CAT_ID[smartphones]}" "${BRAND_ID[samsung]}" "Galaxy S24+ with 256GB storage, 12GB RAM, triple camera." 2100000 ""
PNUM=$((PNUM+1)); create_product "Samsung Galaxy A55 5G" "samsung-galaxy-a55-5g" "${CAT_ID[smartphones]}" "${BRAND_ID[samsung]}" "Galaxy A55 5G with 128GB storage, 50MP camera, 5000mAh battery." 850000 750000
PNUM=$((PNUM+1)); create_product "Samsung Galaxy A15" "samsung-galaxy-a15" "${CAT_ID[smartphones]}" "${BRAND_ID[samsung]}" "Galaxy A15 with 64GB storage, 50MP camera, affordable pricing." 450000 ""
PNUM=$((PNUM+1)); create_product "Google Pixel 8 Pro" "google-pixel-8-pro" "${CAT_ID[smartphones]}" "${BRAND_ID[generic]}" "Pixel 8 Pro with 128GB, Tensor G3 chip, 50MP camera, AI features." 2300000 ""
PNUM=$((PNUM+1)); create_product "Xiaomi Redmi Note 13" "xiaomi-redmi-note-13" "${CAT_ID[smartphones]}" "${BRAND_ID[generic]}" "Redmi Note 13 with 128GB, 108MP camera, 5000mAh battery." 550000 480000
PNUM=$((PNUM+1)); create_product "Oppo Reno 11" "oppo-reno-11" "${CAT_ID[smartphones]}" "${BRAND_ID[generic]}" "Oppo Reno 11 with 256GB, 50MP portrait camera, sleek design." 950000 ""
PNUM=$((PNUM+1)); create_product "Tecno Camon 20 Pro" "tecno-camon-20-pro" "${CAT_ID[smartphones]}" "${BRAND_ID[generic]}" "Tecno Camon 20 Pro with 128GB, 64MP camera, 5000mAh battery." 520000 ""
PNUM=$((PNUM+1)); create_product "Infinix Note 30" "infinix-note-30" "${CAT_ID[smartphones]}" "${BRAND_ID[generic]}" "Infinix Note 30 with 128GB, 60MP camera, fast charging." 480000 420000
PNUM=$((PNUM+1)); create_product "Itel A70" "itel-a70" "${CAT_ID[smartphones]}" "${BRAND_ID[generic]}" "Itel A70 with 64GB, budget smartphone with essential features." 280000 ""
PNUM=$((PNUM+1)); create_product "Samsung Galaxy Z Flip 5" "samsung-galaxy-z-flip-5" "${CAT_ID[smartphones]}" "${BRAND_ID[samsung]}" "Galaxy Z Flip 5 foldable phone with 256GB, flex window." 2800000 2500000
PNUM=$((PNUM+1)); create_product "iPhone 14 128GB" "iphone-14-128gb" "${CAT_ID[smartphones]}" "${BRAND_ID[apple]}" "iPhone 14 with A15 chip, 128GB storage, advanced camera." 1900000 1700000

# ─── Laptops (12) ───
PNUM=$((PNUM+1)); create_product "MacBook Pro 14 M3 Pro" "macbook-pro-14-m3-pro" "${CAT_ID[laptops]}" "${BRAND_ID[apple]}" "MacBook Pro 14-inch with M3 Pro chip, 18GB RAM, 512GB SSD." 4500000 ""
PNUM=$((PNUM+1)); create_product "MacBook Air 13 M3" "macbook-air-13-m3" "${CAT_ID[laptops]}" "${BRAND_ID[apple]}" "MacBook Air 13-inch with M3 chip, 8GB RAM, 256GB SSD, lightweight." 3200000 ""
PNUM=$((PNUM+1)); create_product "Dell XPS 15" "dell-xps-15" "${CAT_ID[laptops]}" "${BRAND_ID[dell]}" "Dell XPS 15 with Intel i7, 16GB RAM, 512GB SSD, 4K display." 3800000 ""
PNUM=$((PNUM+1)); create_product "HP Pavilion 15" "hp-pavilion-15" "${CAT_ID[laptops]}" "${BRAND_ID[hp]}" "HP Pavilion 15 with Intel i5, 8GB RAM, 512GB SSD." 1800000 1600000
PNUM=$((PNUM+1)); create_product "Lenovo ThinkPad X1 Carbon" "lenovo-thinkpad-x1-carbon" "${CAT_ID[laptops]}" "${BRAND_ID[lenovo]}" "ThinkPad X1 Carbon with Intel i7, 16GB RAM, 1TB SSD, ultra-light." 4200000 ""
PNUM=$((PNUM+1)); create_product "Asus ROG Strix G16" "asus-rog-strix-g16" "${CAT_ID[laptops]}" "${BRAND_ID[asus]}" "ROG Strix G16 gaming laptop with RTX 4060, 16GB RAM, 1TB SSD." 5200000 ""
PNUM=$((PNUM+1)); create_product "Acer Aspire 5" "acer-aspire-5" "${CAT_ID[laptops]}" "${BRAND_ID[acer]}" "Acer Aspire 5 with Intel i5, 8GB RAM, 512GB SSD, budget friendly." 1200000 ""
PNUM=$((PNUM+1)); create_product "HP EliteBook 840" "hp-elitebook-840" "${CAT_ID[laptops]}" "${BRAND_ID[hp]}" "HP EliteBook 840 with Intel i7, 16GB RAM, 512GB SSD, business class." 3200000 2900000
PNUM=$((PNUM+1)); create_product "Dell Inspiron 15" "dell-inspiron-15" "${CAT_ID[laptops]}" "${BRAND_ID[dell]}" "Dell Inspiron 15 with Intel i3, 8GB RAM, 256GB SSD." 950000 ""
PNUM=$((PNUM+1)); create_product "Lenovo IdeaPad 3" "lenovo-ideapad-3" "${CAT_ID[laptops]}" "${BRAND_ID[lenovo]}" "Lenovo IdeaPad 3 with AMD Ryzen 5, 8GB RAM, 512GB SSD." 1100000 980000
PNUM=$((PNUM+1)); create_product "MacBook Pro 16 M3 Max" "macbook-pro-16-m3-max" "${CAT_ID[laptops]}" "${BRAND_ID[apple]}" "MacBook Pro 16-inch with M3 Max chip, 36GB RAM, 1TB SSD." 7200000 ""
PNUM=$((PNUM+1)); create_product "Asus ZenBook 14" "asus-zenbook-14" "${CAT_ID[laptops]}" "${BRAND_ID[asus]}" "Asus ZenBook 14 with Intel i7, 16GB RAM, 512GB SSD, OLED display." 2800000 ""

# ─── Audio (10) ───
PNUM=$((PNUM+1)); create_product "Sony WH-1000XM5 Headphones" "sony-wh-1000xm5-headphones" "${CAT_ID[audio]}" "${BRAND_ID[sony]}" "Sony WH-1000XM5 wireless noise cancelling headphones, 30hr battery." 850000 750000
PNUM=$((PNUM+1)); create_product "AirPods Pro 2nd Gen" "airpods-pro-2nd-gen" "${CAT_ID[audio]}" "${BRAND_ID[apple]}" "AirPods Pro 2nd Gen with USB-C, Active Noise Cancellation, Adaptive Audio." 650000 580000
PNUM=$((PNUM+1)); create_product "AirPods Max" "airpods-max" "${CAT_ID[audio]}" "${BRAND_ID[apple]}" "AirPods Max over-ear headphones with spatial audio and noise cancellation." 1500000 ""
PNUM=$((PNUM+1)); create_product "Bose QuietComfort Ultra" "bose-quietcomfort-ultra" "${CAT_ID[audio]}" "${BRAND_ID[bose]}" "Bose QC Ultra headphones with immersive audio, 24hr battery." 1200000 ""
PNUM=$((PNUM+1)); create_product "JBL Flip 6 Speaker" "jbl-flip-6-speaker" "${CAT_ID[audio]}" "${BRAND_ID[jbl]}" "JBL Flip 6 portable Bluetooth speaker, waterproof, 12hr battery." 320000 280000
PNUM=$((PNUM+1)); create_product "JBL Charge 5 Speaker" "jbl-charge-5-speaker" "${CAT_ID[audio]}" "${BRAND_ID[jbl]}" "JBL Charge 5 portable speaker with powerbank feature, 20hr battery." 450000 ""
PNUM=$((PNUM+1)); create_product "Sony WF-1000XM5 Earbuds" "sony-wf-1000xm5-earbuds" "${CAT_ID[audio]}" "${BRAND_ID[sony]}" "Sony WF-1000XM5 wireless earbuds with noise cancellation, 8hr battery." 680000 ""
PNUM=$((PNUM+1)); create_product "Samsung Galaxy Buds 3 Pro" "samsung-galaxy-buds-3-pro" "${CAT_ID[audio]}" "${BRAND_ID[samsung]}" "Galaxy Buds 3 Pro with ANC, 360 audio, wireless charging." 520000 460000
PNUM=$((PNUM+1)); create_product "Bose SoundLink Flex" "bose-soundlink-flex" "${CAT_ID[audio]}" "${BRAND_ID[bose]}" "Bose SoundLink Flex portable speaker, waterproof, compact design." 380000 ""
PNUM=$((PNUM+1)); create_product "JBL Tune 520BT" "jbl-tune-520bt" "${CAT_ID[audio]}" "${BRAND_ID[jbl]}" "JBL Tune 520BT wireless on-ear headphones, 57hr battery." 180000 150000

# ─── Cameras (5) ───
PNUM=$((PNUM+1)); create_product "Canon EOS R6 Mark II" "canon-eos-r6-mark-ii" "${CAT_ID[cameras]}" "${BRAND_ID[canon]}" "Canon EOS R6 Mark II mirrorless camera with 24.2MP, 4K video." 5200000 ""
PNUM=$((PNUM+1)); create_product "Nikon Z6 III" "nikon-z6-iii" "${CAT_ID[cameras]}" "${BRAND_ID[nikon]}" "Nikon Z6 III mirrorless camera with 24.5MP, 6K video capabilities." 4800000 ""
PNUM=$((PNUM+1)); create_product "GoPro HERO12 Black" "gopro-hero12-black" "${CAT_ID[cameras]}" "${BRAND_ID[gopro]}" "GoPro HERO12 Black action camera with 5.3K video, waterproof." 1800000 1600000
PNUM=$((PNUM+1)); create_product "Canon EOS R50" "canon-eos-r50" "${CAT_ID[cameras]}" "${BRAND_ID[canon]}" "Canon EOS R50 entry-level mirrorless camera with 24.2MP, 4K video." 2200000 ""
PNUM=$((PNUM+1)); create_product "Nikon Z30" "nikon-z30" "${CAT_ID[cameras]}" "${BRAND_ID[nikon]}" "Nikon Z30 vlogging camera with 20.9MP, 4K video, compact design." 1900000 1700000

# ─── Wearables (5) ───
PNUM=$((PNUM+1)); create_product "Apple Watch Series 9" "apple-watch-series-9" "${CAT_ID[wearables]}" "${BRAND_ID[apple]}" "Apple Watch Series 9 with S9 chip, always-on display, health tracking." 1200000 ""
PNUM=$((PNUM+1)); create_product "Apple Watch Ultra 2" "apple-watch-ultra-2" "${CAT_ID[wearables]}" "${BRAND_ID[apple]}" "Apple Watch Ultra 2 with titanium body, 36hr battery, adventure ready." 2200000 ""
PNUM=$((PNUM+1)); create_product "Samsung Galaxy Watch 6" "samsung-galaxy-watch-6" "${CAT_ID[wearables]}" "${BRAND_ID[samsung]}" "Galaxy Watch 6 with health tracking, sleep monitoring, AMOLED display." 780000 680000
PNUM=$((PNUM+1)); create_product "Samsung Galaxy Watch 6 Classic" "samsung-galaxy-watch-6-classic" "${CAT_ID[wearables]}" "${BRAND_ID[samsung]}" "Galaxy Watch 6 Classic with rotating bezel, premium design." 950000 ""
PNUM=$((PNUM+1)); create_product "Fitbit Versa 4" "fitbit-versa-4" "${CAT_ID[wearables]}" "${BRAND_ID[generic]}" "Fitbit Versa 4 fitness smartwatch with GPS, heart rate, 6+ days battery." 520000 450000

# ─── Gaming (5) ───
PNUM=$((PNUM+1)); create_product "PlayStation 5 Slim" "playstation-5-slim" "${CAT_ID[gaming]}" "${BRAND_ID[generic]}" "PlayStation 5 Slim console with 1TB SSD, 4K gaming, DualSense controller." 2200000 ""
PNUM=$((PNUM+1)); create_product "Xbox Series X" "xbox-series-x" "${CAT_ID[gaming]}" "${BRAND_ID[generic]}" "Xbox Series X console with 1TB SSD, 4K gaming, 120fps support." 2300000 ""
PNUM=$((PNUM+1)); create_product "PS5 DualSense Controller" "ps5-dualsense-controller" "${CAT_ID[gaming]}" "${BRAND_ID[generic]}" "DualSense wireless controller with haptic feedback and adaptive triggers." 280000 ""
PNUM=$((PNUM+1)); create_product "Xbox Wireless Controller" "xbox-wireless-controller" "${CAT_ID[gaming]}" "${BRAND_ID[generic]}" "Xbox wireless controller with textured grip, Bluetooth connectivity." 220000 190000
PNUM=$((PNUM+1)); create_product "Logitech G502 Mouse" "logitech-g502-mouse" "${CAT_ID[gaming]}" "${BRAND_ID[generic]}" "Logitech G502 gaming mouse with 11 programmable buttons, 25K DPI." 320000 ""

# ─── Men Fashion (8) ───
PNUM=$((PNUM+1)); create_product "Nike Air Max 90" "nike-air-max-90" "${CAT_ID[shoes]}" "${BRAND_ID[nike]}" "Nike Air Max 90 men's sneakers with visible Air cushioning, classic design." 350000 ""
PNUM=$((PNUM+1)); create_product "Nike Air Force 1" "nike-air-force-1" "${CAT_ID[shoes]}" "${BRAND_ID[nike]}" "Nike Air Force 1 low-top sneakers, timeless style, all-day comfort." 300000 270000
PNUM=$((PNUM+1)); create_product "Adidas Ultraboost 22" "adidas-ultraboost-22" "${CAT_ID[shoes]}" "${BRAND_ID[adidas]}" "Adidas Ultraboost 22 running shoes with Boost midsole, Primeknit upper." 420000 ""
PNUM=$((PNUM+1)); create_product "Adidas Samba OG" "adidas-samba-og" "${CAT_ID[shoes]}" "${BRAND_ID[adidas]}" "Adidas Samba OG classic sneakers, leather upper, gum sole." 280000 ""
PNUM=$((PNUM+1)); create_product "Nike Dri-FIT T-Shirt" "nike-dri-fit-t-shirt" "${CAT_ID[men-fashion]}" "${BRAND_ID[nike]}" "Nike Dri-FIT moisture-wicking t-shirt, breathable fabric, athletic fit." 85000 ""
PNUM=$((PNUM+1)); create_product "Men Slim Fit Jeans" "mens-slim-fit-jeans" "${CAT_ID[men-fashion]}" "${BRAND_ID[generic]}" "Slim fit denim jeans, stretch comfort, available in multiple sizes." 120000 98000
PNUM=$((PNUM+1)); create_product "Men Leather Jacket" "mens-leather-jacket" "${CAT_ID[men-fashion]}" "${BRAND_ID[generic]}" "Genuine leather jacket, classic design, multiple sizes available." 450000 380000
PNUM=$((PNUM+1)); create_product "Men Casual Watch" "mens-casual-watch" "${CAT_ID[men-fashion]}" "${BRAND_ID[generic]}" "Men's casual analog watch with leather strap, water resistant." 180000 ""

# ─── Women Fashion (8) ───
PNUM=$((PNUM+1)); create_product "Floral Summer Dress" "floral-summer-dress" "${CAT_ID[women-fashion]}" "${BRAND_ID[generic]}" "Beautiful floral summer dress, lightweight and comfortable fabric." 120000 89000
PNUM=$((PNUM+1)); create_product "Women Handbag" "womens-handbag" "${CAT_ID[bags-accessories]}" "${BRAND_ID[generic]}" "Elegant women's handbag, premium faux leather, spacious design." 180000 ""
PNUM=$((PNUM+1)); create_product "Women Heels" "womens-heels" "${CAT_ID[shoes]}" "${BRAND_ID[generic]}" "Elegant stiletto heels, comfortable padding, perfect for occasions." 220000 180000
PNUM=$((PNUM+1)); create_product "Women Sneakers" "womens-sneakers" "${CAT_ID[shoes]}" "${BRAND_ID[puma]}" "Puma women's sneakers, lightweight, comfortable cushioning." 250000 ""
PNUM=$((PNUM+1)); create_product "Silk Scarf" "silk-scarf" "${CAT_ID[women-fashion]}" "${BRAND_ID[generic]}" "Luxurious silk scarf with elegant pattern, versatile styling." 95000 ""
PNUM=$((PNUM+1)); create_product "Women Winter Coat" "womens-winter-coat" "${CAT_ID[women-fashion]}" "${BRAND_ID[generic]}" "Warm winter coat with faux fur hood, waterproof, insulated." 380000 320000
PNUM=$((PNUM+1)); create_product "Women Leggings" "womens-leggings" "${CAT_ID[women-fashion]}" "${BRAND_ID[under-armour]}" "Under Armour women's leggings, moisture-wicking, high-waist fit." 150000 ""
PNUM=$((PNUM+1)); create_product "Pearl Earrings" "pearl-earrings" "${CAT_ID[bags-accessories]}" "${BRAND_ID[generic]}" "Elegant pearl earrings, gold-plated, perfect gift item." 120000 98000

# ─── Home Appliances (10) ───
PNUM=$((PNUM+1)); create_product 'Samsung 55 4K Smart TV' "samsung-55-4k-smart-tv" "${CAT_ID[home-appliances]}" "${BRAND_ID[samsung]}" "Samsung 55-inch Crystal UHD 4K Smart TV with Tizen OS." 1200000 990000
PNUM=$((PNUM+1)); create_product 'LG 65 OLED TV' "lg-65-oled-tv" "${CAT_ID[home-appliances]}" "${BRAND_ID[lg]}" "LG 65-inch OLED evo TV with AI ThinQ, 4K resolution." 4500000 ""
PNUM=$((PNUM+1)); create_product "Samsung Double Door Fridge 435L" "samsung-double-door-fridge-435l" "${CAT_ID[home-appliances]}" "${BRAND_ID[samsung]}" "Samsung 435L double door refrigerator with digital inverter compressor." 1800000 ""
PNUM=$((PNUM+1)); create_product "LG 32L Microwave Oven" "lg-32l-microwave-oven" "${CAT_ID[kitchen]}" "${BRAND_ID[lg]}" "LG 32-liter NeoChef microwave oven with smart inverter technology." 450000 ""
PNUM=$((PNUM+1)); create_product "Philips Air Fryer 4.1L" "philips-air-fryer-4-1l" "${CAT_ID[kitchen]}" "${BRAND_ID[philips]}" "Philips 4.1L air fryer with rapid air technology, 7 presets." 380000 320000
PNUM=$((PNUM+1)); create_product "Samsung Front Load Washer 9kg" "samsung-front-load-washer-9kg" "${CAT_ID[home-appliances]}" "${BRAND_ID[samsung]}" "Samsung 9kg front load washing machine with EcoBubble technology." 1200000 1050000
PNUM=$((PNUM+1)); create_product "LG AC 1.5HP Inverter" "lg-ac-1-5hp-inverter" "${CAT_ID[home-appliances]}" "${BRAND_ID[lg]}" "LG 1.5HP inverter split AC with dual cool, energy efficient." 980000 ""
PNUM=$((PNUM+1)); create_product "Philips Electric Kettle 1.7L" "philips-electric-kettle-1-7l" "${CAT_ID[kitchen]}" "${BRAND_ID[philips]}" "Philips 1.7L electric kettle with stainless steel body, fast boiling." 120000 98000
PNUM=$((PNUM+1)); create_product "Samsung Vacuum Cleaner" "samsung-vacuum-cleaner" "${CAT_ID[home-appliances]}" "${BRAND_ID[samsung]}" "Samsung canister vacuum cleaner with 1800W motor, HEPA filter." 520000 ""
PNUM=$((PNUM+1)); create_product "LG Blender 1.5L" "lg-blender-1-5l" "${CAT_ID[kitchen]}" "${BRAND_ID[lg]}" "LG 1.5L blender with 3-speed settings, stainless steel blades." 180000 150000

# ─── Furniture (5) ───
PNUM=$((PNUM+1)); create_product "IKEA Office Chair" "ikea-office-chair" "${CAT_ID[furniture]}" "${BRAND_ID[ikea]}" "Ergonomic office chair with adjustable height, lumbar support, breathable mesh." 450000 380000
PNUM=$((PNUM+1)); create_product "Wooden Dining Table 6-Seater" "wooden-dining-table-6-seater" "${CAT_ID[furniture]}" "${BRAND_ID[generic]}" "Solid wood dining table, 6-seater, modern design, durable construction." 850000 ""
PNUM=$((PNUM+1)); create_product "IKEA Sofa Bed 3-Seater" "ikea-sofa-bed-3-seater" "${CAT_ID[furniture]}" "${BRAND_ID[ikea]}" "IKEA 3-seater sofa bed with storage, convertible design, comfortable." 980000 ""
PNUM=$((PNUM+1)); create_product "Bookshelf 5-Tier" "bookshelf-5-tier" "${CAT_ID[furniture]}" "${BRAND_ID[generic]}" "5-tier wooden bookshelf, sturdy construction, modern minimalist design." 320000 280000
PNUM=$((PNUM+1)); create_product "Queen Size Bed Frame" "queen-size-bed-frame" "${CAT_ID[furniture]}" "${BRAND_ID[generic]}" "Queen size bed frame with headboard, sturdy wooden construction." 680000 ""

# ─── Beauty (5) ───
PNUM=$((PNUM+1)); create_product "Maybelline Foundation Set" "maybelline-foundation-set" "${CAT_ID[beauty-products]}" "${BRAND_ID[generic]}" "Maybelline foundation set with 3 shades, long-lasting coverage." 95000 ""
PNUM=$((PNUM+1)); create_product "MAC Lipstick Collection" "mac-lipstick-collection" "${CAT_ID[beauty-products]}" "${BRAND_ID[generic]}" "MAC lipstick collection with 5 shades, matte finish, long-lasting." 180000 150000
PNUM=$((PNUM+1)); create_product "CeraVe Skincare Bundle" "cerave-skincare-bundle" "${CAT_ID[beauty-products]}" "${BRAND_ID[generic]}" "CeraVe skincare bundle: cleanser, moisturizer, and sunscreen for daily care." 150000 ""
PNUM=$((PNUM+1)); create_product "Nivea Body Lotion 400ml" "nivea-body-lotion-400ml" "${CAT_ID[beauty-products]}" "${BRAND_ID[generic]}" "Nivea body lotion 400ml, deep moisture, non-greasy formula." 45000 ""
PNUM=$((PNUM+1)); create_product "Beard Grooming Kit" "beard-grooming-kit" "${CAT_ID[beauty-products]}" "${BRAND_ID[generic]}" "Complete beard grooming kit: oil, balm, brush, and scissors." 120000 98000

# ─── Sports & Fitness (7) ───
PNUM=$((PNUM+1)); create_product "Adidas Football" "adidas-football" "${CAT_ID[sports-equipment]}" "${BRAND_ID[adidas]}" "Adidas professional football, FIFA approved, durable construction." 120000 ""
PNUM=$((PNUM+1)); create_product "Yoga Mat Premium" "yoga-mat-premium" "${CAT_ID[fitness]}" "${BRAND_ID[generic]}" "Premium yoga mat, 6mm thick, non-slip surface, eco-friendly material." 85000 68000
PNUM=$((PNUM+1)); create_product "Adjustable Dumbbells 20kg" "adjustable-dumbbells-20kg" "${CAT_ID[fitness]}" "${BRAND_ID[generic]}" "Adjustable dumbbells up to 20kg per hand, space-saving design." 450000 380000
PNUM=$((PNUM+1)); create_product "Nike Football Cleats" "nike-football-cleats" "${CAT_ID[sports-equipment]}" "${BRAND_ID[nike]}" "Nike football cleats with grip studs, lightweight, professional grade." 280000 ""
PNUM=$((PNUM+1)); create_product "Resistance Band Set" "resistance-band-set" "${CAT_ID[fitness]}" "${BRAND_ID[generic]}" "Resistance band set with 5 levels, door anchor, handles, and carry bag." 65000 ""
PNUM=$((PNUM+1)); create_product "Under Armour Hoodie" "under-armour-hoodie" "${CAT_ID[fitness]}" "${BRAND_ID[under-armour]}" "Under Armour men's hoodie, moisture-wicking, fleece-lined, athletic fit." 220000 180000
PNUM=$((PNUM+1)); create_product "Basketball Size 7" "basketball-size-7" "${CAT_ID[sports-equipment]}" "${BRAND_ID[generic]}" "Official size 7 basketball, indoor/outdoor, durable rubber cover." 95000 ""

# ─── Books (4) ───
PNUM=$((PNUM+1)); create_product "Atomic Habits by James Clear" "atomic-habits-james-clear" "${CAT_ID[books]}" "${BRAND_ID[generic]}" "Atomic Habits - bestselling book on building good habits and breaking bad ones." 45000 ""
PNUM=$((PNUM+1)); create_product "Rich Dad Poor Dad" "rich-dad-poor-dad" "${CAT_ID[books]}" "${BRAND_ID[generic]}" "Rich Dad Poor Dad by Robert Kiyosaki - financial education classic." 38000 ""
PNUM=$((PNUM+1)); create_product "The Alchemist" "the-alchemist" "${CAT_ID[books]}" "${BRAND_ID[generic]}" "The Alchemist by Paulo Coelho - philosophical novel about following dreams." 35000 ""
PNUM=$((PNUM+1)); create_product "Think and Grow Rich" "think-and-grow-rich" "${CAT_ID[books]}" "${BRAND_ID[generic]}" "Think and Grow Rich by Napoleon Hill - timeless success principles." 42000 35000

# ─── Toys (3) ───
PNUM=$((PNUM+1)); create_product "LEGO City Building Set" "lego-city-building-set" "${CAT_ID[toys-kids]}" "${BRAND_ID[generic]}" "LEGO City building set with 500+ pieces, ages 6+, creative play." 180000 ""
PNUM=$((PNUM+1)); create_product "Remote Control Car" "remote-control-car" "${CAT_ID[toys-kids]}" "${BRAND_ID[generic]}" "Remote control car with 2.4GHz transmitter, 4WD, rechargeable battery." 150000 120000
PNUM=$((PNUM+1)); create_product "Educational Puzzle Set" "educational-puzzle-set" "${CAT_ID[toys-kids]}" "${BRAND_ID[generic]}" "Educational puzzle set for kids, 6 puzzles, ages 3+, cognitive development." 65000 ""

# ─── Automotive (3) ───
PNUM=$((PNUM+1)); create_product "Car Phone Mount Holder" "car-phone-mount-holder" "${CAT_ID[automotive-parts]}" "${BRAND_ID[generic]}" "Universal car phone mount holder, 360-degree rotation, suction cup base." 45000 ""
PNUM=$((PNUM+1)); create_product "Jump Starter Power Bank" "jump-starter-power-bank" "${CAT_ID[automotive-parts]}" "${BRAND_ID[generic]}" "Portable car jump starter with 2000A peak, USB power bank, LED flashlight." 280000 230000
PNUM=$((PNUM+1)); create_product "Car Vacuum Cleaner" "car-vacuum-cleaner" "${CAT_ID[automotive-parts]}" "${BRAND_ID[generic]}" "Portable car vacuum cleaner, 12V, HEPA filter, 3 accessories included." 120000 98000

echo ""
echo "  ✅ Created $PNUM products"

# ============================================================
# STEP 4: Approve all products (as admin)
# ============================================================
echo ""
echo "[4/5] Approving all products as admin..."

ADMIN_TOKEN=$(curl -s -X POST "$API/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}" | jval access_token)

if [ -z "$ADMIN_TOKEN" ]; then
  echo "  ⚠️  Could not login as admin. Products will stay pending."
  echo "  Run SSH step first to fix admin role."
else
  echo "  ✅ Logged in as admin"

  # Get Ezra's seller products (my-products)
  MY_PRODUCTS=$(curl -s "$API/products/my-products?skip=0&limit=100" \
    -H "Authorization: Bearer $EZRA_TOKEN")

  # Approve each product
  TOTAL=$(echo "$MY_PRODUCTS" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null)
  APPROVED=0

  for i in $(seq 0 $((TOTAL-1))); do
    PID=$(echo "$MY_PRODUCTS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[$i]['id'])" 2>/dev/null)
    if [ -n "$PID" ]; then
      curl -s -X POST "$API/admin/products/$PID/approve" \
        -H "Authorization: Bearer $ADMIN_TOKEN" > /dev/null
      APPROVED=$((APPROVED+1))
    fi
  done
  echo "  ✅ Approved $APPROVED products"
fi

# ============================================================
# STEP 5: Verify
# ============================================================
echo ""
echo "[5/5] Verifying..."

CAT_COUNT=$(curl -s "$API/products/categories" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null)
echo "  📦 Product Categories: $CAT_COUNT"

PROD_COUNT=$(curl -s "$API/products?skip=0&limit=100" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d) if isinstance(d,list) else 0)" 2>/dev/null)
echo "  📦 Approved Products: $PROD_COUNT"

echo ""
echo "=========================================="
echo "  ✅ Seed complete! ($PNUM products)"
echo "=========================================="
echo ""
echo "Seller login (Ezra):"
echo "  Email:    $EZRA_EMAIL"
echo "  Password: $EZRA_PASSWORD"
echo ""
echo "Admin login:"
echo "  Email:    $ADMIN_EMAIL"
echo "  Password: $ADMIN_PASSWORD"
echo ""
