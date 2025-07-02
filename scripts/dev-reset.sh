#!/bin/bash
# dev-reset.sh: Reset ClickHouse dev environment
# Usage: ./scripts/dev-reset.sh

set -e

# Stop and remove containers/volumes
echo "[dev-reset] Stopping and removing containers/volumes..."
docker-compose down -v

# Clean up ClickHouse data/logs (named volumes are removed by docker-compose down -v)
# Clean up benchmark results
rm -f benchmark_results.csv benchmark_results.json

# Clean up any temp files
find . -name '*.tmp' -delete

# Start the cluster
echo "[dev-reset] Starting ClickHouse cluster..."
docker-compose up -d

# Wait for ClickHouse nodes to be ready
echo "[dev-reset] Waiting for ClickHouse nodes to be ready..."
sleep 10

# Create tables on the cluster
echo "[dev-reset] Creating tables on the cluster..."
docker exec -i ch-node1 clickhouse-client --user=admin --password=admin_strong_password --multiquery < ./init/01_create_tables.sql

echo "[dev-reset] Table creation complete."

echo "[dev-reset] Environment reset complete." 