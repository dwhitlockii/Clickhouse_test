# CHANGELOG

## [Unreleased]

### Added
- Robust, production-grade reset scripts (`dev-reset.sh`, `dev-reset.ps1`) now:
  - Start the ClickHouse cluster
  - Wait for node readiness
  - Run all table creation SQL (`init/01_create_tables.sql`) on the cluster (via ch-node1)
  - Ensure all required tables exist before any data load
- Windows PowerShell parity for all major scripts
- Comprehensive README documentation for initialization and data load workflow
- Docker health checks for all ClickHouse nodes using the HTTP /ping endpoint
- Manual cluster health scripts: `scripts/cluster-health.sh` (Bash) and `scripts/cluster-health.ps1` (PowerShell)
- Major enhancement: Added new production-grade panels to the ClickHouse Grafana dashboard (`clickhouse-overview.json`):
  - Cluster Node Health
  - Keeper (ZooKeeper) Status
  - Query Performance (slow queries, errors)
  - Table Growth (row count over time)
  - Disk Usage by Table
  - Kafka Ingestion Rate
  - User Activity (top users, failed logins)
  - System Resource Usage (CPU, memory, disk I/O)
- All panels include robust queries, clear section headers, and detailed descriptions for operational excellence.

### Fixed
- ClickHouse config.xml for all nodes now includes all required path, tmp_path, user_files_path, format_schema_path, logger, and user_directories parameters
- All users.xml files now include a robust <default> user for system compatibility
- Data load scripts now assume tables exist, and reset scripts guarantee this precondition
- ClickHouse data source provisioning now explicitly sets 'server' and 'port' in grafana/provisioning.yaml, ensuring the Server address is always populated in the Grafana UI and preventing blank/required field errors.
- Set a secure password for the default user in all ClickHouse nodes and updated the Grafana data source provisioning to resolve authentication errors and enable dashboard data population.
- users.xml is now mounted for all ClickHouse nodes in docker-compose.yml, ensuring the correct user/password config is always used by the containers and authentication works as expected.
- users.xml structure was fixed to include <profiles> and <quotas> for ClickHouse compatibility, resolving startup and authentication errors.

### Improved
- Error handling and logging in all scripts
- Idempotent, repeatable environment setup for onboarding and CI/CD
- Updated README with explicit instructions for automated provisioning of the default home dashboard, location of preferences file, Docker Compose mount path, and troubleshooting tips for dashboard visibility.

### Changed
- The "ClickHouse Cluster Overview" dashboard is now set as the default home dashboard for all users via automated provisioning (`grafana/provisioning/preferences/org-preferences.yaml`).

---

## [2024-07-02]
- Initial robust cluster setup, config, and workflow hardening 