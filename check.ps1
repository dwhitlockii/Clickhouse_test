$node = "ch-node1"

Write-Host "🔍 Checking if ClickHouse process is running on $node..."
docker exec $node pgrep -a clickhouse || Write-Host "❌ ClickHouse process not found."

Write-Host "`n🔍 Checking if port 8123 is listening..."
docker exec $node netstat -tulnp | findstr "8123" || Write-Host "❌ Port 8123 is NOT listening."

Write-Host "`n🔍 Trying /ping endpoint..."
$status = docker exec $node curl -s -o /dev/null -w "%{http_code}" http://localhost:8123/ping
Write-Host "Response: $status"
if ($status -ne "200") {
    Write-Host "❌ /ping failed. Continuing with more diagnostics..."
}

Write-Host "`n🔍 Checking for cluster config issues..."
docker exec $node cat /etc/clickhouse-server/config.d/cluster.xml 2>$null || Write-Host "⚠️ No cluster config found."

Write-Host "`n🔍 Checking ClickHouse logs (tail)..."
docker exec $node tail -n 50 /var/log/clickhouse-server/clickhouse-server.log

Write-Host "`n🔍 Checking ClickHouse stderr logs (tail)..."
docker exec $node tail -n 50 /var/log/clickhouse-server/stderr.log

Write-Host "`n🔍 Checking connection to Keeper (port 2181)..."
docker exec $node nc -vz keeper 2181
