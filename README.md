# ClickHouse Dev Battlestation

## Overview
A production-style, containerized ClickHouse cluster for distributed query testing, benchmarking, and onboarding. Zero manual steps. Launch, load, and benchmark with a single command.

## Features
- 3+ ClickHouse nodes (replication + sharding)
- ClickHouse Keeper for coordination
- Grafana with preconfigured dashboards
- Kafka for stream ingestion testing
- All configs, data, and scripts in-repo
- Deterministic, idempotent, CI/CD-ready

## Directory Structure
```
./
├── docker-compose.yml         # Cluster definition
├── Makefile                   # Dev commands
├── README.md                  # This file
├── config/                    # All service configs
│   ├── clickhouse/node1/      # Node1 configs
│   ├── clickhouse/node2/      # Node2 configs
│   ├── clickhouse/node3/      # Node3 configs
│   └── keeper/                # Keeper config
├── data/                      # Static datasets (CSV/SQL)
├── init/                      # ClickHouse init scripts
├── grafana/dashboards/        # Grafana dashboards
├── kafka/                     # Kafka test topics/configs
└── scripts/                   # Data load, benchmark, reset scripts
```

## Quickstart
1. **Spin up cluster:**
   ```sh
   make dev-up
   ```
2. **Load sample data:**
   ```sh
   make dev-load
   ```
3. **Run benchmarks:**
   ```sh
   make dev-benchmark
   ```
4. **Reset environment:**
   ```sh
   make dev-reset
   ```

## Ports
- ClickHouse: 9001/9002/9003 (native), 8123/8124/8125 (HTTP)
- Grafana: 3000
- Kafka: 9092

## Robust Initialization & Data Load Workflow

### 1. Reset and Initialize the Cluster

**Linux/macOS (Bash):**
```sh
./scripts/dev-reset.sh
```
**Windows (PowerShell):**
```powershell
./scripts/dev-reset.ps1
```
- Stops and removes all containers/volumes
- Cleans up temp and benchmark files
- Starts the ClickHouse cluster
- Waits for nodes to be ready
- Runs all table creation SQL (init/01_create_tables.sql) on the cluster (via ch-node1)
- Ensures all required tables exist before any data load

### 2. Load Data

**Linux/macOS (Bash):**
```sh
./scripts/dev-load.sh
```
**Windows (PowerShell):**
```powershell
./scripts/dev-load.ps1
```
- Loads all CSV data into the correct tables on all nodes
- Assumes tables already exist (created by the reset step)

### 3. Run Benchmarks (Optional)

**Linux/macOS (Bash):**
```sh
./scripts/dev-benchmark.sh
```
**Windows (PowerShell):**
```powershell
./scripts/dev-benchmark.ps1
```

## Health Checks & Monitoring

### Docker Health Checks
- All ClickHouse nodes now have robust Docker health checks using the HTTP /ping endpoint.
- Docker will mark a node as 'unhealthy' if it fails to respond, enabling auto-restart and observability.
- Health check parameters: interval 10s, timeout 3s, retries 5, start_period 20s.

### Manual Cluster Health Scripts
- Use the provided scripts to check the health of all ClickHouse nodes at any time:

**Linux/macOS (Bash):**
```sh
./scripts/cluster-health.sh
```
**Windows (PowerShell):**
```powershell
./scripts/cluster-health.ps1
```
- Each script will output 'ch-nodeX: healthy' or 'ch-nodeX: unhealthy' for every node.
- Useful for CI/CD, troubleshooting, or manual monitoring.

## Grafana Dashboard: ClickHouse Cluster Overview

A fully automated, production-grade Grafana dashboard is provisioned at container startup. No manual steps are required. The dashboard provides:

- **Cluster Node Health:** Status, version, and uptime for each ClickHouse node.
- **Keeper (ZooKeeper) Status:** Keeper node state, leader/follower, and raft health.
- **Query Performance:** Top slow queries and recent query errors (last 24h).
- **Table Growth:** Row count over time for key tables (e.g., sales_orders).
- **Disk Usage:** Disk space used by each table.
- **Kafka Ingestion Rate:** Rows ingested per minute from Kafka (if applicable).
- **User Activity:** Top users by query count and recent failed logins.
- **System Resource Usage:** CPU, memory, and disk I/O usage from system metrics.
- **Existing Panels:** Total rows in sales_orders, recent queries, active connections.

### Default Home Dashboard
The "ClickHouse Cluster Overview" dashboard is now set as the default home dashboard for all users. When you log in to Grafana, you will land directly on this dashboard. This is fully automated via provisioning—no manual steps required.

- **Provisioning file:** `grafana/provisioning/preferences/org-preferences.yaml`
- **Docker Compose mount:** `/etc/grafana/provisioning/preferences/org-preferences.yaml`

### Accessing the Dashboard
- Open Grafana at [http://localhost:3000](http://localhost:3000)
- Login with the default credentials (see docker-compose or provisioning files)
- The "ClickHouse Cluster Overview" dashboard is available immediately under the main folder and as the home page

### Troubleshooting
If you do not see the dashboard on login:
- Ensure the provisioning file is mounted correctly in the Grafana container
- Restart Grafana: `docker-compose restart grafana`
- If issues persist, run `docker-compose down -v && docker-compose up -d` to force a clean reprovision

### Panel Details
Each panel is robust, uses optimized ClickHouse queries, and is resilient to missing or partial data. All panels are auto-provisioned via `grafana/provisioning/dashboards/clickhouse-overview.json` and referenced in `grafana/provisioning/dashboards/clickhouse-dashboard.yaml`.

For more on adding or customizing panels, see the [Grafana documentation](https://grafana.com/docs/grafana/v7.5/panels/add-a-panel/).

### Authentication Note
The ClickHouse `default` user now requires a password (`clickhouse_default_password`). This is set in all ClickHouse nodes and in the Grafana data source provisioning for secure, automated access. If you change this password, update both the ClickHouse user configs and the Grafana provisioning file accordingly.

### Troubleshooting: User Credentials
users.xml is now mounted for all ClickHouse nodes to ensure the correct user/password config is used. If you change user credentials, update both the users.xml and the Grafana provisioning file, and fully restart the containers with 'docker-compose down -v && docker-compose up -d'.

---

## Notes
- The reset scripts are robust and idempotent: you can run them as often as needed.
- All table creation is handled automatically; no manual SQL execution is required.
- Data load scripts will fail if tables do not exist—always run the reset script first after any environment change.
- All scripts provide error handling and clear logging.

## Next Steps
- Extend the cluster, add new datasets, or customize user roles as needed.
- For troubleshooting, consult logs in /var/log/clickhouse-server/ (inside containers).
- For advanced configuration, see the config/ directory and init/ SQL scripts.

## Running Scripts on Windows (or Any OS)

If you are on Windows or want a cross-platform way to run the scripts in ./scripts/ (which are Bash scripts), use the provided dev-shell Docker service:

1. **Start the dev-shell container:**
   ```sh
   docker-compose up -d dev-shell
   ```
2. **Open a shell inside the container:**
   ```sh
   docker-compose exec dev-shell bash
   ```
3. **Run any script as usual:**
   ```sh
   ./scripts/dev-load.sh
   ./scripts/dev-benchmark.sh
   ./scripts/dev-reset.sh
   ```

This approach works on Windows, Mac, and Linux, and does not require Bash or Unix tools on your host system. All scripts will have access to your project files and Docker.

## PowerShell Scripts for Windows Users

For Windows users, PowerShell equivalents of the Bash scripts are provided in the ./scripts/ directory:

- dev-load.ps1
- dev-benchmark.ps1
- dev-reset.ps1

### Requirements
- Docker CLI must be available in your PATH
- Run scripts from the project root

### Usage
Open PowerShell in the project root and run:

```powershell
# Load data
./scripts/dev-load.ps1

# Run benchmarks
./scripts/dev-benchmark.ps1

# Reset environment
./scripts/dev-reset.ps1
```

All scripts provide robust error handling and logging. They are functionally equivalent to the Bash scripts and require no additional dependencies beyond Docker.

---
Direct, annotated, and ready for production-style dev. Extend as needed. 