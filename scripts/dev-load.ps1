# =====================================================================
# dev-load.ps1
# Purpose: Load all CSV data into ClickHouse cluster from Windows PowerShell
# Usage:   .\dev-load.ps1
# Requires: Docker CLI in PATH, run from project root
# =====================================================================

param()

$ErrorActionPreference = 'Stop'

$nodes = @('ch-node1', 'ch-node2', 'ch-node3')

function Wait-For-ClickHouse {
    param([string]$node)

    $maxAttempts = 30
    $attempt = 0

    while ($attempt -lt $maxAttempts) {
        $status = docker exec $node curl -s -o /dev/null -w "%{http_code}" http://localhost:8123/ping
        if ($status -eq "200") {
            Write-Host "$node is healthy." -ForegroundColor Green
            return
        } else {
            Write-Host "$node not ready (attempt $attempt), waiting..." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
            $attempt++
        }
    }
    throw "Node $node did not become healthy in time!"
}

Write-Host "`n🧪 Waiting for all ClickHouse nodes to pass /ping health checks..."
foreach ($node in $nodes) {
    Wait-For-ClickHouse -node $node
}

# Load user_activity
foreach ($NODE in $nodes) {
    Write-Host "[dev-load] Loading user_activity.csv into $NODE..."
    Get-Content ./data/user_activity.csv -Raw | docker exec -i $NODE clickhouse-client --user=admin --password=admin_strong_password --query "INSERT INTO default.user_activity_local FORMAT CSVWithNames"
}

# Load sales_orders
foreach ($NODE in $nodes) {
    Write-Host "[dev-load] Loading sales_orders.csv into $NODE..."
    Get-Content ./data/sales_orders.csv -Raw | docker exec -i $NODE clickhouse-client --user=admin --password=admin_strong_password --query "INSERT INTO default.sales_orders_local FORMAT CSVWithNames"
}

# Load system_logs
foreach ($NODE in $nodes) {
    Write-Host "[dev-load] Loading system_logs.csv into $NODE..."
    Get-Content ./data/system_logs.csv -Raw | docker exec -i $NODE clickhouse-client --user=admin --password=admin_strong_password --query "INSERT INTO default.system_logs_local FORMAT CSVWithNames"
}

Write-Host "[dev-load] Data load complete." 