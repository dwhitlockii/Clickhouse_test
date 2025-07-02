# =====================================================================
# dev-reset.ps1
# Purpose: Reset ClickHouse dev environment on Windows
# Usage:   .\dev-reset.ps1
# Requires: Docker CLI in PATH, run from project root
# =====================================================================

$ErrorActionPreference = 'Stop'

function Timestamp { return (Get-Date -Format "yyyy-MM-dd HH:mm:ss") }

Write-Host "[dev-reset] 🔧 Stopping and removing containers/volumes..."
docker-compose down -v

# Clean up benchmark results
Remove-Item -ErrorAction SilentlyContinue benchmark_results.csv, benchmark_results.json

# Clean up any temp files
Get-ChildItem -Recurse -Include *.tmp | Remove-Item -Force -ErrorAction SilentlyContinue

# Start the cluster
Write-Host "[dev-reset] 🚀 Starting ClickHouse cluster..."
docker-compose up -d

Write-Host "[dev-reset] ⏳ Giving containers time to start..."
Start-Sleep -Seconds 20

# ClickHouse nodes
$nodes = @("ch-node1", "ch-node2", "ch-node3")

function Wait-For-Keeper {
    Write-Host "`n$(Timestamp)🔍 Checking ClickHouse Keeper availability from ch-node1..."

    Write-Host "$(Timestamp)🔧 Ensuring netcat (nc) is installed in ch-node1..."
    docker exec ch-node1 bash -c "command -v nc >/dev/null || (apt update && apt install -y netcat)" | Out-Null

    $maxAttempts = 15
    for ($i = 0; $i -lt $maxAttempts; $i++) {
        $result = docker exec ch-node1 nc -vz keeper 2181 2>&1
        if ($result -like "*succeeded*") {
            Write-Host "$(Timestamp)✅ Keeper is reachable on port 2181." -ForegroundColor Green
            return
        } else {
            Write-Host "$(Timestamp)⏳ Keeper not yet reachable (attempt $i): $result" -ForegroundColor Yellow
            Start-Sleep -Seconds 2
        }
    }

    throw "$(Timestamp)❌ Failed to connect to Keeper at keeper:2181 after $maxAttempts attempts."
}

function Wait-For-ClickHouse {
    param([string]$node)

    $maxAttempts = 30
    for ($i = 0; $i -lt $maxAttempts; $i++) {
        try {
            $status = docker exec $node clickhouse-client --host localhost --query "SELECT 1 FORMAT TabSeparated" 2>$null
            if ($status -eq "1") {
                Write-Host "$(Timestamp)✅ $node is healthy." -ForegroundColor Green
                return
            }
        } catch {
            # Ignore errors, just retry
        }

        Write-Host "$(Timestamp)⏳ $node not ready (attempt $i), waiting..." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
    }

    throw "$(Timestamp)❌ Node $node did not become healthy in time!"
}

# --- Health checks ---
Wait-For-Keeper

Write-Host "`n🧪 Waiting for all ClickHouse nodes to pass health checks..."
foreach ($node in $nodes) {
    Wait-For-ClickHouse -node $node
}

# --- Create tables ---
Write-Host "[dev-reset] 🧱 Creating tables on the cluster..."
Get-Content ./init/01_create_tables.sql -Raw | docker exec -i ch-node1 clickhouse-client --user default --multiquery

Write-Host "`n[dev-reset] ✅ Table creation complete."

# --- Load CSV data into tables ---
Write-Host "`n[dev-reset] 📥 Loading CSV data into ClickHouse tables..."

$csvLoads = @(
    @{ File = "data/sales_orders.csv"; Table = "default.sales_orders" },
    @{ File = "data/system_logs.csv"; Table = "default.system_logs" },
    @{ File = "data/user_activity.csv"; Table = "default.user_activity" }
)

foreach ($load in $csvLoads) {
    $file = $load.File
    $table = $load.Table
    if (Test-Path $file) {
        Write-Host "[dev-reset] ⏳ Loading $file into $table..."
        Get-Content $file | docker exec -i ch-node1 clickhouse-client --user default --query "INSERT INTO $table FORMAT CSVWithNames"
        Write-Host "[dev-reset] ✅ Loaded $file into $table." -ForegroundColor Green
    } else {
        Write-Host "[dev-reset] ⚠️ File $file not found, skipping $table." -ForegroundColor Yellow
    }
}

Write-Host "`n[dev-reset] 🎉 Data load complete."

Write-Host "`n[dev-reset] 🚀 Cluster is fully reset, tables created, and data loaded!" -ForegroundColor Cyan
