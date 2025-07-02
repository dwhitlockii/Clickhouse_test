#!/bin/bash
# dev-load.sh: Load all CSV data into ClickHouse cluster
# Usage: ./scripts/dev-load.sh

set -e

# Load user_activity
for NODE in ch-node1 ch-node2 ch-node3; do
  echo "[dev-load] Loading user_activity.csv into $NODE..."
  docker exec -i $NODE clickhouse-client --user=admin --password=admin_strong_password --query "INSERT INTO default.user_activity_local FORMAT CSVWithNames" < ./data/user_activity.csv

done

# Load sales_orders
for NODE in ch-node1 ch-node2 ch-node3; do
  echo "[dev-load] Loading sales_orders.csv into $NODE..."
  docker exec -i $NODE clickhouse-client --user=admin --password=admin_strong_password --query "INSERT INTO default.sales_orders_local FORMAT CSVWithNames" < ./data/sales_orders.csv

done

# Load system_logs
for NODE in ch-node1 ch-node2 ch-node3; do
  echo "[dev-load] Loading system_logs.csv into $NODE..."
  docker exec -i $NODE clickhouse-client --user=admin --password=admin_strong_password --query "INSERT INTO default.system_logs_local FORMAT CSVWithNames" < ./data/system_logs.csv

done

echo "[dev-load] Data load complete." 