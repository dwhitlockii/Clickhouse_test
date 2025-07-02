#!/bin/bash
# dev-benchmark.sh: Run ClickHouse performance benchmarks
# Usage: ./scripts/dev-benchmark.sh

set -e

RESULTS_CSV=benchmark_results.csv
RESULTS_JSON=benchmark_results.json

# Helper to run a query and time it
run_benchmark() {
  local name="$1"
  local query="$2"
  local node="$3"
  local start end duration
  start=$(date +%s%3N)
  docker exec -i $node clickhouse-client --user=admin --password=admin_strong_password --query "$query" > /dev/null
  end=$(date +%s%3N)
  duration=$((end - start))
  echo "$name,$duration" >> "$RESULTS_CSV"
  echo "  {\"name\": \"$name\", \"duration_ms\": $duration }," >> "$RESULTS_JSON"
  echo "[dev-benchmark] $name: $duration ms"
}

# Prepare result files
rm -f "$RESULTS_CSV" "$RESULTS_JSON"
echo "benchmark,duration_ms" > "$RESULTS_CSV"
echo "[" > "$RESULTS_JSON"

NODE=ch-node1

# Insert benchmark
run_benchmark "insert_user_activity" "INSERT INTO default.user_activity_local (user_id,login_time,logout_time,session_id,ip_address) VALUES (999,'2024-07-01 16:00:00','2024-07-01 17:00:00','bench999','10.0.0.1')" "$NODE"

# Select benchmark
run_benchmark "select_user_activity" "SELECT count(*) FROM default.user_activity" "$NODE"

# Join benchmark
run_benchmark "join_activity_logs" "SELECT count(*) FROM default.user_activity ua JOIN default.system_logs sl ON ua.login_time = sl.log_time" "$NODE"

# Aggregation benchmark
run_benchmark "agg_sales_orders" "SELECT product, sum(amount) FROM default.sales_orders GROUP BY product" "$NODE"

echo "  {\"name\": \"END\", \"duration_ms\": 0 }" >> "$RESULTS_JSON"
echo "]" >> "$RESULTS_JSON"

cat "$RESULTS_CSV"
echo "[dev-benchmark] Results written to $RESULTS_CSV and $RESULTS_JSON" 