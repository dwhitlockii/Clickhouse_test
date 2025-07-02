#!/bin/bash
# dev-load.sh: Load CSVs into all active ClickHouse nodes

set -e

for NODE in ch-node1 ch-node2 ch-node3; do
  if docker inspect -f '{{.State.Running}}' $NODE | grep true; then
    echo "[dev-load] 🚀 Loading CSVs into $NODE..."

    docker exec $NODE bash -c "clickhouse-client \
      --user=admin --password=admin_strong_password \
      --query 'INSERT INTO default.user_activity_local FORMAT CSVWithNames' < /tmp/user_activity.csv"

    docker exec $NODE bash -c "clickhouse-client \
      --user=admin --password=admin_strong_password \
      --query 'INSERT INTO default.sales_orders_local FORMAT CSVWithNames' < /tmp/sales_orders.csv"

    docker exec $NODE bash -c "clickhouse-client \
      --user=admin --password=admin_strong_password \
      --query 'INSERT INTO default.system_logs_local FORMAT CSVWithNames' < /tmp/system_logs.csv"
  else
    echo "[dev-load] ⚠️ Skipping $NODE (not running)"
  fi
done

echo "[dev-load] ✅ Data load complete."
