# =====================================================================
# dev-benchmark.ps1
# Purpose: Run ClickHouse performance benchmarks from Windows PowerShell
# Usage:   .\dev-benchmark.ps1
# Requires: Docker CLI in PATH, run from project root
# =====================================================================

param()

$ErrorActionPreference = 'Stop'

$RESULTS_CSV = "benchmark_results.csv"
$RESULTS_JSON = "benchmark_results.json"

function Run-Benchmark {
    param(
        [string]$Name,
        [string]$Query,
        [string]$Node
    )
    $start = [int64](Get-Date -UFormat %s%3N)
    docker exec -i $Node clickhouse-client --user=admin --password=admin_strong_password --query "$Query" | Out-Null
    $end = [int64](Get-Date -UFormat %s%3N)
    $duration = $end - $start
    Add-Content -Path $RESULTS_CSV -Value "$Name,$duration"
    Add-Content -Path $RESULTS_JSON -Value "  {\"name\": \"$Name\", \"duration_ms\": $duration },"
    Write-Host "[dev-benchmark] $Name: $duration ms"
}

# Prepare result files
Remove-Item $RESULTS_CSV,$RESULTS_JSON -ErrorAction SilentlyContinue
"benchmark,duration_ms" | Set-Content $RESULTS_CSV
"[" | Set-Content $RESULTS_JSON

$NODE = "ch-node1"

# Insert benchmark
Run-Benchmark "insert_user_activity" "INSERT INTO default.user_activity_local (user_id,login_time,logout_time,session_id,ip_address) VALUES (999,'2024-07-01 16:00:00','2024-07-01 17:00:00','bench999','10.0.0.1')" $NODE

# Select benchmark
Run-Benchmark "select_user_activity" "SELECT count(*) FROM default.user_activity" $NODE

# Join benchmark
Run-Benchmark "join_activity_logs" "SELECT count(*) FROM default.user_activity ua JOIN default.system_logs sl ON ua.login_time = sl.log_time" $NODE

# Aggregation benchmark
Run-Benchmark "agg_sales_orders" "SELECT product, sum(amount) FROM default.sales_orders GROUP BY product" $NODE

"  {\"name\": \"END\", \"duration_ms\": 0 }" | Add-Content $RESULTS_JSON
"]" | Add-Content $RESULTS_JSON

Get-Content $RESULTS_CSV | Write-Host
Write-Host "[dev-benchmark] Results written to $RESULTS_CSV and $RESULTS_JSON" 