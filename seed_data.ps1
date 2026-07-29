<#
.SYNOPSIS
  XerinMarket Seed Data Script - Runs on the server directly
.DESCRIPTION
  Creates super admin, approved seller, business categories, product categories,
  brands, and 100 products with images directly in the database.
  Run this ON THE SERVER where the backend is hosted.

  Usage (on server, from BACKEND directory):
    python -m api.seed_products

  Or run this script from your machine if you have SSH access:
    ssh user@server "cd /path/to/BACKEND && python -m api.seed_products"
#>

param(
    [string]$ServerHost = "187.124.32.94",
    [string]$SshUser = "root",
    [string]$BackendPath = "/root/Xerin-Gateway/BACKEND"
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  XerinMarket Seed Data Script" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Option 1: Run directly on server via SSH
if ($ServerHost -ne "localhost" -and $ServerHost -ne "127.0.0.1") {
    Write-Host "Connecting to $ServerHost via SSH..." -ForegroundColor Yellow
    Write-Host "Backend path: $BackendPath" -ForegroundColor Yellow
    Write-Host ""
    ssh $SshUser@$ServerHost "cd $BackendPath && python -m api.seed_products"
    exit $LASTEXITCODE
}

# Option 2: Run locally (if you're already on the server)
Write-Host "Running seed script locally..." -ForegroundColor Yellow
Write-Host ""
python -m api.seed_products
