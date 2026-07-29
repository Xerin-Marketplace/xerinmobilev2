<#
.SYNOPSIS
  XerinMarket Interactive Admin Tool
.DESCRIPTION
  Logs in as admin, then presents an interactive menu to:
  - List/search users
  - View seller details & KYC documents
  - Approve/reject sellers
  - List pending products
  - Approve/reject products
  - Manage categories & brands
  - View all sellers
  - And more
.EXAMPLE
  .\admin_tool.ps1
  .\admin_tool.ps1 -ApiUrl "http://localhost:8080"
#>

param(
    [string]$ApiUrl = "http://187.124.32.94:8080",
    [string]$AdminEmail = "superadmin@xerin.com",
    [string]$AdminPassword = "SuperAdmin123"
)

$ErrorActionPreference = "Stop"

# --- Colors ---
function W-C { param($text, $color = "White") Write-Host $text -ForegroundColor $color }
function W-Green { param($text) Write-Host $text -ForegroundColor Green }
function W-Red { param($text) Write-Host $text -ForegroundColor Red }
function W-Yellow { param($text) Write-Host $text -ForegroundColor Yellow }
function W-Cyan { param($text) Write-Host $text -ForegroundColor Cyan }
function W-Dim { param($text) Write-Host $text -ForegroundColor DarkGray }

# --- API helpers ---
$script:token = $null

function Invoke-Api {
    param(
        [string]$Method = "GET",
        [string]$Endpoint,
        [hashtable]$Body,
        [switch]$NoAuth
    )
    $headers = @{ "Content-Type" = "application/json" }
    if (-not $NoAuth -and $script:token) {
        $headers["Authorization"] = "Bearer $script:token"
    }
    $uri = "$ApiUrl$Endpoint"
    $params = @{
        Method  = $Method
        Uri     = $uri
        Headers = $headers
    }
    if ($Body) {
        $params.Body = ($Body | ConvertTo-Json -Depth 10)
    }
    try {
        $resp = Invoke-RestMethod @params
        return $resp
    }
    catch {
        $msg = $_.Exception.Message
        if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
            try { $errObj = $_.ErrorDetails.Message | ConvertFrom-Json; $msg = $errObj.detail } catch {}
        }
        W-Red "  API Error: $msg"
        return $null
    }
}

function Login-Admin {
    W-Cyan "`n[LOGIN] Logging in as admin ($AdminEmail)..."
    $resp = Invoke-Api -Method POST -Endpoint "/auth/login" -Body @{
        email    = $AdminEmail
        password = $AdminPassword
    } -NoAuth
    if ($resp -and $resp.access_token) {
        $script:token = $resp.access_token
        W-Green "  Logged in successfully!"
        return $true
    }
    W-Red "  Failed to login!"
    return $false
}

# --- Table helpers ---
function Print-Users {
    param($users)
    if (-not $users -or $users.Count -eq 0) {
        W-Yellow "  No users found."
        return
    }
    $format = "  {0,-36} {1,-20} {2,-25} {3,-15} {4,-10}"
    W-C ($format -f "ID", "Name", "Email", "Phone", "Status")
    W-Dim ("  " + ("-" * 110))
    foreach ($u in $users) {
        $name = "$($u.first_name) $($u.last_name)"
        W-C ($format -f $u.id, $name, $u.email, $u.phone, $u.status)
    }
    W-Dim "`n  Total: $($users.Count) users"
}

function Print-Sellers {
    param($sellers)
    if (-not $sellers -or $sellers.Count -eq 0) {
        W-Yellow "  No sellers found."
        return
    }
    $format = "  {0,-36} {1,-25} {2,-30} {3,-12}"
    W-C ($format -f "ID", "Business Name", "Email", "Status")
    W-Dim ("  " + ("-" * 108))
    foreach ($s in $sellers) {
        $email = if ($s.contact_email) { $s.contact_email } else { $s.user_email }
        W-C ($format -f $s.id, $s.business_name, $email, $s.status)
    }
    W-Dim "`n  Total: $($sellers.Count) sellers"
}

function Print-Products {
    param($products)
    if (-not $products -or $products.Count -eq 0) {
        W-Yellow "  No products found."
        return
    }
    $format = "  {0,-36} {1,-35} {2,-12} {3,-10} {4,-10}"
    W-C ($format -f "ID", "Name", "Price", "Status", "Currency")
    W-Dim ("  " + ("-" * 108))
    foreach ($p in $products) {
        $name = if ($p.name.Length -gt 33) { $p.name.Substring(0, 33) + "..." } else { $p.name }
        W-C ($format -f $p.id, $name, $p.price, $p.status, $p.currency)
    }
    W-Dim "`n  Total: $($products.Count) products"
}

function Print-Categories {
    param($cats)
    if (-not $cats -or $cats.Count -eq 0) {
        W-Yellow "  No categories found."
        return
    }
    $format = "  {0,-36} {1,-30} {2,-20}"
    W-C ($format -f "ID", "Name", "Slug")
    W-Dim ("  " + ("-" * 88))
    foreach ($c in $cats) {
        W-C ($format -f $c.id, $c.name, $c.slug)
    }
    W-Dim "`n  Total: $($cats.Count) categories"
}

function Print-Brands {
    param($brands)
    if (-not $brands -or $brands.Count -eq 0) {
        W-Yellow "  No brands found."
        return
    }
    $format = "  {0,-36} {1,-30} {2,-20}"
    W-C ($format -f "ID", "Name", "Slug")
    W-Dim ("  " + ("-" * 88))
    foreach ($b in $brands) {
        W-C ($format -f $b.id, $b.name, $b.slug)
    }
    W-Dim "`n  Total: $($brands.Count) brands"
}

# --- Menu actions ---

function Action-ListUsers {
    W-Cyan "`n[USERS] Fetching all users..."
    $users = Invoke-Api -Method GET -Endpoint "/admin/users?skip=0&limit=100"
    if ($users) { Print-Users $users }
}

function Action-SearchUser {
    $term = Read-Host "`n  Enter name or email to search"
    if ([string]::IsNullOrWhiteSpace($term)) { return }
    W-Cyan "`n  Searching for '$term'..."
    $users = Invoke-Api -Method GET -Endpoint "/admin/users?skip=0&limit=100"
    if ($users) {
        $filtered = $users | Where-Object {
            $_.email -match $term -or
            ("$($_.first_name) $($_.last_name)" -match $term) -or
            $_.phone -match $term
        }
        if ($filtered -and $filtered.Count -gt 0) {
            Print-Users $filtered
        } else {
            W-Yellow "  No users matched '$term'"
        }
    }
}

function Action-UserDetail {
    $id = Read-Host "`n  Enter user ID"
    if ([string]::IsNullOrWhiteSpace($id)) { return }
    W-Cyan "`n  Fetching user $id..."
    $user = Invoke-Api -Method GET -Endpoint "/admin/users/$id"
    if ($user) {
        W-Green "`n  +------------------------------------------"
        W-C  "  | Name:     $($user.first_name) $($user.last_name)"
        W-C  "  | Email:    $($user.email)"
        W-C  "  | Phone:    $($user.phone)"
        W-C  "  | Status:   $($user.status)"
        W-C  "  | Verified: $($user.is_verified)"
        W-C  "  | ID:       $($user.id)"
        W-Green "  +------------------------------------------"
    }
}

function Action-ListSellers {
    W-Cyan "`n[SELLERS] Fetching all sellers..."
    $sellers = Invoke-Api -Method GET -Endpoint "/admin/sellers?skip=0&limit=100"
    if ($sellers) { Print-Sellers $sellers }
}

function Action-PendingSellers {
    W-Cyan "`n[SELLERS] Fetching pending sellers..."
    $sellers = Invoke-Api -Method GET -Endpoint "/admin/sellers/pending"
    if ($sellers) {
        Print-Sellers $sellers
        if ($sellers.Count -gt 0) {
            $choice = Read-Host "`n  Approve/Reject a seller? (a=approve/r=reject/Enter=skip)"
            if ($choice -eq "a" -or $choice -eq "r") {
                $sid = Read-Host "  Enter seller ID"
                if ($choice -eq "a") {
                    $resp = Invoke-Api -Method POST -Endpoint "/admin/sellers/$sid/approve"
                    if ($resp) { W-Green "  Seller $sid approved!" }
                } else {
                    $reason = Read-Host "  Reason for rejection (optional)"
                    $body = @{}
                    if ($reason) { $body.reason = $reason }
                    $resp = Invoke-Api -Method POST -Endpoint "/admin/sellers/$sid/reject" -Body $body
                    if ($resp) { W-Green "  Seller $sid rejected!" }
                }
            }
        }
    }
}

function Action-SellerDetail {
    $id = Read-Host "`n  Enter seller ID"
    if ([string]::IsNullOrWhiteSpace($id)) { return }
    W-Cyan "`n  Fetching seller $id..."
    $seller = Invoke-Api -Method GET -Endpoint "/admin/sellers/$id"
    if ($seller) {
        W-Green "`n  +----------------------------------------------"
        W-C  "  | Business:   $($seller.business_name)"
        W-C  "  | Email:      $($seller.contact_email)"
        W-C  "  | Phone:      $($seller.contact_phone)"
        W-C  "  | Status:     $($seller.status)"
        W-C  "  | Seller ID:  $($seller.id)"
        W-C  "  | User ID:    $($seller.user_id)"
        if ($seller.approved_at) { W-C "  | Approved:   $($seller.approved_at)" }
        if ($seller.rejected_at) { W-C "  | Rejected:   $($seller.rejected_at)" }
        W-Green "  +----------------------------------------------"

        $docs = Invoke-Api -Method GET -Endpoint "/admin/sellers/$id/documents"
        if ($docs -and $docs.Count -gt 0) {
            W-Cyan "`n  KYC Documents:"
            foreach ($d in $docs) {
                W-C "    - $($d.document_type): $($d.document_number) (Status: $($d.status))"
            }
        }

        $choice = Read-Host "`n  Approve/Reject this seller? (a=approve/r=reject/Enter=skip)"
        if ($choice -eq "a") {
            $resp = Invoke-Api -Method POST -Endpoint "/admin/sellers/$id/approve"
            if ($resp) { W-Green "  Seller approved!" }
        } elseif ($choice -eq "r") {
            $reason = Read-Host "  Reason for rejection"
            $body = @{}
            if ($reason) { $body.reason = $reason }
            $resp = Invoke-Api -Method POST -Endpoint "/admin/sellers/$id/reject" -Body $body
            if ($resp) { W-Green "  Seller rejected!" }
        }
    }
}

function Action-PendingProducts {
    W-Cyan "`n[PRODUCTS] Fetching pending products..."
    $products = Invoke-Api -Method GET -Endpoint "/admin/products/pending?skip=0&limit=100"
    if ($products) {
        Print-Products $products
        if ($products.Count -gt 0) {
            W-Yellow "`n  Options: a=all approve | r=all reject | <id>=approve specific | Enter=skip"
            $choice = Read-Host "  Choice"
            if ($choice -eq "a") {
                $count = 0
                foreach ($p in $products) {
                    $r = Invoke-Api -Method POST -Endpoint "/admin/products/$($p.id)/approve"
                    if ($r) { $count++ }
                }
                W-Green "  Approved $count/$($products.Count) products!"
            } elseif ($choice -eq "r") {
                $count = 0
                foreach ($p in $products) {
                    $r = Invoke-Api -Method POST -Endpoint "/admin/products/$($p.id)/reject"
                    if ($r) { $count++ }
                }
                W-Green "  Rejected $count/$($products.Count) products!"
            } elseif ($choice -ne "") {
                $r = Invoke-Api -Method POST -Endpoint "/admin/products/$choice/approve"
                if ($r) { W-Green "  Product $choice approved!" }
            }
        }
    }
}

function Action-ApproveProduct {
    $id = Read-Host "`n  Enter product ID to approve"
    if ([string]::IsNullOrWhiteSpace($id)) { return }
    $resp = Invoke-Api -Method POST -Endpoint "/admin/products/$id/approve"
    if ($resp) { W-Green "  Product $id approved!" }
}

function Action-RejectProduct {
    $id = Read-Host "`n  Enter product ID to reject"
    if ([string]::IsNullOrWhiteSpace($id)) { return }
    $reason = Read-Host "  Reason (optional)"
    $body = @{}
    if ($reason) { $body.reason = $reason }
    $resp = Invoke-Api -Method POST -Endpoint "/admin/products/$id/reject" -Body $body
    if ($resp) { W-Green "  Product $id rejected!" }
}

function Action-ListCategories {
    W-Cyan "`n[CATEGORIES] Fetching product categories..."
    $cats = Invoke-Api -Method GET -Endpoint "/products/categories"
    if ($cats) { Print-Categories $cats }
}

function Action-CreateCategory {
    $name = Read-Host "`n  Category name"
    $slug = Read-Host "  Category slug (e.g. electronics)"
    if ([string]::IsNullOrWhiteSpace($name) -or [string]::IsNullOrWhiteSpace($slug)) { return }
    $resp = Invoke-Api -Method POST -Endpoint "/admin/product-categories" -Body @{
        name = $name
        slug = $slug
    }
    if ($resp) { W-Green "  Category '$name' created!" }
}

function Action-DeleteCategory {
    $id = Read-Host "`n  Enter category ID to delete"
    if ([string]::IsNullOrWhiteSpace($id)) { return }
    $confirm = Read-Host "  Confirm delete? (y/n)"
    if ($confirm -ne "y") { W-Yellow "  Cancelled."; return }
    $resp = Invoke-Api -Method DELETE -Endpoint "/admin/product-categories/$id"
    if ($resp) { W-Green "  Category $id deleted!" }
}

function Action-ListBrands {
    W-Cyan "`n[BRANDS] Fetching brands..."
    $brands = Invoke-Api -Method GET -Endpoint "/products/brands"
    if ($brands) { Print-Brands $brands }
}

function Action-CreateBrand {
    $name = Read-Host "`n  Brand name"
    $slug = Read-Host "  Brand slug (e.g. samsung)"
    if ([string]::IsNullOrWhiteSpace($name) -or [string]::IsNullOrWhiteSpace($slug)) { return }
    $resp = Invoke-Api -Method POST -Endpoint "/admin/brands" -Body @{
        name = $name
        slug = $slug
    }
    if ($resp) { W-Green "  Brand '$name' created!" }
}

function Action-DeleteBrand {
    $id = Read-Host "`n  Enter brand ID to delete"
    if ([string]::IsNullOrWhiteSpace($id)) { return }
    $confirm = Read-Host "  Confirm delete? (y/n)"
    if ($confirm -ne "y") { W-Yellow "  Cancelled."; return }
    $resp = Invoke-Api -Method DELETE -Endpoint "/admin/brands/$id"
    if ($resp) { W-Green "  Brand $id deleted!" }
}

function Action-ListBizCategories {
    W-Cyan "`n[BIZ CATEGORIES] Fetching business categories..."
    $cats = Invoke-Api -Method GET -Endpoint "/admin/business-categories"
    if ($cats) { Print-Categories $cats }
}

function Action-CreateBizCategory {
    $name = Read-Host "`n  Business category name"
    $slug = Read-Host "  Slug (e.g. fashion)"
    $desc = Read-Host "  Description (optional)"
    if ([string]::IsNullOrWhiteSpace($name) -or [string]::IsNullOrWhiteSpace($slug)) { return }
    $body = @{ name = $name; slug = $slug }
    if ($desc) { $body.description = $desc }
    $resp = Invoke-Api -Method POST -Endpoint "/admin/business-categories" -Body $body
    if ($resp) { W-Green "  Business category '$name' created!" }
}

function Action-DeleteBizCategory {
    $id = Read-Host "`n  Enter business category ID to delete"
    if ([string]::IsNullOrWhiteSpace($id)) { return }
    $confirm = Read-Host "  Confirm delete? (y/n)"
    if ($confirm -ne "y") { W-Yellow "  Cancelled."; return }
    $resp = Invoke-Api -Method DELETE -Endpoint "/admin/business-categories/$id"
    if ($resp) { W-Green "  Business category $id deleted!" }
}

function Action-CreateAdmin {
    $firstName = Read-Host "`n  First name"
    $lastName = Read-Host "  Last name"
    $email = Read-Host "  Email"
    $phone = Read-Host "  Phone (e.g. 2557xxxx)"
    $password = Read-Host "  Password"
    if ([string]::IsNullOrWhiteSpace($email) -or [string]::IsNullOrWhiteSpace($password)) {
        W-Yellow "  Email and password are required."
        return
    }
    $resp = Invoke-Api -Method POST -Endpoint "/admin/admins" -Body @{
        first_name = $firstName
        last_name  = $lastName
        email      = $email
        phone      = $phone
        password   = $password
    }
    if ($resp) { W-Green "  Admin '$email' created!" }
}

function Action-DeleteUser {
    $id = Read-Host "`n  Enter user ID to delete"
    if ([string]::IsNullOrWhiteSpace($id)) { return }
    $confirm = Read-Host "  Confirm delete user? This cannot be undone! (y/n)"
    if ($confirm -ne "y") { W-Yellow "  Cancelled."; return }
    $resp = Invoke-Api -Method DELETE -Endpoint "/admin/users/$id"
    if ($resp) { W-Green "  User $id deleted!" }
}

function Action-VerifyUser {
    $id = Read-Host "`n  Enter user ID to verify"
    if ([string]::IsNullOrWhiteSpace($id)) { return }
    $resp = Invoke-Api -Method PATCH -Endpoint "/admin/users/$id" -Body @{
        is_verified = $true
    }
    if ($resp) { W-Green "  User $id verified!" }
}

function Action-AllProducts {
    W-Cyan "`n[PRODUCTS] Fetching all products..."
    $products = Invoke-Api -Method GET -Endpoint "/products?skip=0&limit=100"
    if ($products) { Print-Products $products }
}

function Action-SellerProducts {
    $sellerId = Read-Host "`n  Enter seller ID (from seller list)"
    if ([string]::IsNullOrWhiteSpace($sellerId)) { return }
    W-Cyan "  Fetching products for seller $sellerId..."
    $products = Invoke-Api -Method GET -Endpoint "/products?skip=0&limit=100"
    if ($products) {
        $sellerProducts = $products | Where-Object { $_.seller_id -eq $sellerId }
        if ($sellerProducts -and $sellerProducts.Count -gt 0) {
            Print-Products $sellerProducts
        } else {
            W-Yellow "  No products found for seller $sellerId"
            W-Dim "  (Note: seller_id field may not be in product list response)"
        }
    }
}

function Action-HealthCheck {
    W-Cyan "`n[HEALTH] Checking API..."
    $resp = Invoke-Api -Method GET -Endpoint "/" -NoAuth
    if ($resp) {
        W-Green "  API is running!"
        W-C "  Response: $($resp | ConvertTo-Json -Compress)"
    }
}

function Action-FixAdminRole {
    W-Cyan "`n[FIX] Fix admin role via direct database connection..."
    W-Yellow "  This will connect to PostgreSQL and assign super_admin role."
    W-Yellow "  Admin email: $AdminEmail"
    W-Yellow ""

    $dbHost = Read-Host "  DB host (default: 187.124.32.94)"
    if ([string]::IsNullOrWhiteSpace($dbHost)) { $dbHost = "187.124.32.94" }
    $dbPort = Read-Host "  DB port (default: 5432)"
    if ([string]::IsNullOrWhiteSpace($dbPort)) { $dbPort = "5432" }
    $dbName = Read-Host "  DB name (default: xerinmarket)"
    if ([string]::IsNullOrWhiteSpace($dbName)) { $dbName = "xerinmarket" }
    $dbUser = Read-Host "  DB user (default: postgres)"
    if ([string]::IsNullOrWhiteSpace($dbUser)) { $dbUser = "postgres" }
    $dbPass = Read-Host "  DB password"
    if ([string]::IsNullOrWhiteSpace($dbPass)) {
        W-Red "  Password is required!"
        return
    }

    $env:PGPASSWORD = $dbPass
    $connStr = "-h $dbHost -p $dbPort -U $dbUser -d $dbName"

    W-Cyan "`n  Checking admin user..."
    $adminId = psql $connStr -t -A -c "SELECT id FROM users WHERE email = '$AdminEmail';" 2>&1
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($adminId)) {
        W-Red "  Could not find admin user or DB connection failed!"
        W-Red "  Error: $adminId"
        $env:PGPASSWORD = ""
        return
    }
    W-Green "  Admin found: ID = $adminId"

    W-Cyan "  Checking/creating super_admin role..."
    $roleId = psql $connStr -t -A -c "SELECT id FROM roles WHERE name = 'super_admin';" 2>&1
    if ([string]::IsNullOrWhiteSpace($roleId)) {
        $roleId = psql $connStr -t -A -c "INSERT INTO roles (id, name, description) VALUES (gen_random_uuid(), 'super_admin', 'Full system owner') RETURNING id;" 2>&1
        if ([string]::IsNullOrWhiteSpace($roleId)) {
            $roleId = psql $connStr -t -A -c "INSERT INTO roles (name, description) VALUES ('super_admin', 'Full system owner') RETURNING id;" 2>&1
        }
        W-Green "  Created super_admin role: $roleId"
    } else {
        W-Green "  super_admin role exists: $roleId"
    }

    W-Cyan "  Assigning super_admin role to admin..."
    $check = psql $connStr -t -A -c "SELECT 1 FROM user_roles WHERE user_id = '$adminId' AND role_id = '$roleId';" 2>&1
    if ([string]::IsNullOrWhiteSpace($check)) {
        psql $connStr -c "INSERT INTO user_roles (user_id, role_id) VALUES ('$adminId', '$roleId');" 2>&1 | Out-Null
        W-Green "  Assigned super_admin role!"
    } else {
        W-Yellow "  Already assigned."
    }

    W-Cyan "  Checking/creating admin role..."
    $adminRoleId = psql $connStr -t -A -c "SELECT id FROM roles WHERE name = 'admin';" 2>&1
    if ([string]::IsNullOrWhiteSpace($adminRoleId)) {
        $adminRoleId = psql $connStr -t -A -c "INSERT INTO roles (id, name, description) VALUES (gen_random_uuid(), 'admin', 'Platform administrator') RETURNING id;" 2>&1
        if ([string]::IsNullOrWhiteSpace($adminRoleId)) {
            $adminRoleId = psql $connStr -t -A -c "INSERT INTO roles (name, description) VALUES ('admin', 'Platform administrator') RETURNING id;" 2>&1
        }
        W-Green "  Created admin role: $adminRoleId"
    } else {
        W-Green "  admin role exists: $adminRoleId"
    }

    W-Cyan "  Assigning admin role..."
    $check2 = psql $connStr -t -A -c "SELECT 1 FROM user_roles WHERE user_id = '$adminId' AND role_id = '$adminRoleId';" 2>&1
    if ([string]::IsNullOrWhiteSpace($check2)) {
        psql $connStr -c "INSERT INTO user_roles (user_id, role_id) VALUES ('$adminId', '$adminRoleId');" 2>&1 | Out-Null
        W-Green "  Assigned admin role!"
    } else {
        W-Yellow "  Already assigned."
    }

    W-Cyan "  Setting admin status=active, is_verified=true..."
    psql $connStr -c "UPDATE users SET status = 'active', is_verified = true WHERE id = '$adminId';" 2>&1 | Out-Null
    W-Green "  Done!"

    W-Cyan "`n  Verifying..."
    $roles = psql $connStr -t -A -c "SELECT r.name FROM roles r JOIN user_roles ur ON ur.role_id = r.id WHERE ur.user_id = '$adminId';" 2>&1
    W-C "  Admin roles now: $roles"

    $env:PGPASSWORD = ""
    W-Green "`n  Admin role fixed! Select option 25 to re-login."
}

# --- Main menu ---
function Show-Menu {
    W-Cyan ""
    W-Cyan "+==========================================================+"
    W-Cyan "|        XerinMarket Admin Console                         |"
    W-Cyan "+==========================================================+"
    W-Cyan ""
    W-C  "  -- Users -------------------------------------------"
    W-C  "  1.  List all users"
    W-C  "  2.  Search users (name/email/phone)"
    W-C  "  3.  View user details"
    W-C  "  4.  Verify user"
    W-C  "  5.  Delete user"
    W-C  "  6.  Create new admin"
    W-C  ""
    W-C  "  -- Sellers -----------------------------------------"
    W-C  "  7.  List all sellers"
    W-C  "  8.  View pending sellers + approve/reject"
    W-C  "  9.  View seller details + KYC + approve/reject"
    W-C  ""
    W-C  "  -- Products ----------------------------------------"
    W-C  "  10. List all products"
    W-C  "  11. View pending products + approve/reject"
    W-C  "  12. Approve product by ID"
    W-C  "  13. Reject product by ID"
    W-C  "  14. View products by seller"
    W-C  ""
    W-C  "  -- Categories & Brands -----------------------------"
    W-C  "  15. List product categories"
    W-C  "  16. Create product category"
    W-C  "  17. Delete product category"
    W-C  "  18. List brands"
    W-C  "  19. Create brand"
    W-C  "  20. Delete brand"
    W-C  ""
    W-C  "  -- Business Categories -----------------------------"
    W-C  "  21. List business categories"
    W-C  "  22. Create business category"
    W-C  "  23. Delete business category"
    W-C  ""
    W-C  "  -- System ------------------------------------------"
    W-C  "  24. API health check"
    W-C  "  25. Re-login as admin"
    W-C  "  26. Fix admin role (direct DB connection)"
    W-C  ""
    W-Red  "  0.  Exit"
    W-Cyan ""
}

# --- Main loop ---
function Main {
    W-Cyan ""
    W-Cyan "+==========================================================+"
    W-Cyan "|        XerinMarket Admin Console                         |"
    W-Cyan "|        API: $ApiUrl"
    W-Cyan "+==========================================================+"

    if (-not (Login-Admin)) {
        W-Red "Cannot continue without admin login."
        return
    }

    while ($true) {
        Show-Menu
        $choice = Read-Host "  Select option"

        switch ($choice) {
            "1"  { Action-ListUsers }
            "2"  { Action-SearchUser }
            "3"  { Action-UserDetail }
            "4"  { Action-VerifyUser }
            "5"  { Action-DeleteUser }
            "6"  { Action-CreateAdmin }
            "7"  { Action-ListSellers }
            "8"  { Action-PendingSellers }
            "9"  { Action-SellerDetail }
            "10" { Action-AllProducts }
            "11" { Action-PendingProducts }
            "12" { Action-ApproveProduct }
            "13" { Action-RejectProduct }
            "14" { Action-SellerProducts }
            "15" { Action-ListCategories }
            "16" { Action-CreateCategory }
            "17" { Action-DeleteCategory }
            "18" { Action-ListBrands }
            "19" { Action-CreateBrand }
            "20" { Action-DeleteBrand }
            "21" { Action-ListBizCategories }
            "22" { Action-CreateBizCategory }
            "23" { Action-DeleteBizCategory }
            "24" { Action-HealthCheck }
            "25" { Login-Admin }
            "26" { Action-FixAdminRole }
            "0"  { W-Yellow "`n  Goodbye!`n"; return }
            default { W-Yellow "  Invalid option. Try again." }
        }

        if ($choice -ne "0") {
            W-Dim ""
            W-Dim "  Press Enter to continue..."
            [void](Read-Host)
        }
    }
}

Main
