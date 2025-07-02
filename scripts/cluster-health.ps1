# =====================================================================
# cluster-health.ps1
# Purpose: Check health of all ClickHouse nodes via /ping endpoint
# Usage:   .\cluster-health.ps1
# =====================================================================

$ErrorActionPreference = 'Stop'
$nodes = @('ch-node1', 'ch-node2', 'ch-node3')
foreach ($NODE in $nodes) {
    try {
        $result = docker exec $NODE curl -sf http://localhost:8123/ping
        if ($result -eq 'Ok.') {
            Write-Host "$($NODE): healthy"
        } else {
            Write-Host "$($NODE): unhealthy"
        }
    } catch {
        Write-Host "$($NODE): unhealthy"
    }
} 