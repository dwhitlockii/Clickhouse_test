#!/bin/bash
# cluster-health.sh: Check health of all ClickHouse nodes via /ping endpoint
set -e
NODES=(ch-node1 ch-node2 ch-node3)
for NODE in "${NODES[@]}"; do
  echo -n "$NODE: "
  if docker exec $NODE curl -sf http://localhost:8123/ping > /dev/null; then
    echo "healthy"
  else
    echo "unhealthy"
  fi
done 