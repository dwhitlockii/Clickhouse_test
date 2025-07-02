#!/bin/bash
# dev-load.sh: Load all CSV data into ClickHouse cluster

set -e

# Load user_activity
for NODE in ch-node1 ch-node2 ch-node3; do
  echo "[dev-load] Loading user_activity.csv into $NODE..."
  docker exec $NODE bash -c "clickhouse-client \
    --user=admin --password=admin_strong_password \
    --query 'INSERT INTO default.user_activity_local FORMAT CSVWithNames' < /tmp/user_activity.csv"
done

# Load sales_orders
for NODE in ch-node1 ch-node2 ch-node3; do
  echo "[dev-load] Loading sales_orders.csv into $NODE..."
  docker exec $NODE bash -c "clickhouse-client \
    --user=admin --password=admin_strong_password \
    --query 'INSERT INTO default.sales_orders_local FORMAT CSVWithNames' < /tmp/sales_orders.csv"
done

# Load system_logs
for NODE in ch-node1 ch-node2 ch-node3; do
  echo "[dev-load] Loading system_logs.csv into $NODE..."
  docker exec $NODE bash -c "clickhouse-client \
    --user=admin --password=admin_strong_password \
    --query 'INSERT INTO default.system_logs_local FORMAT CSVWithNames' < /tmp/system_logs.csv"
done

echo "[dev-load] ✅ Data load complete."
