-- 01_create_tables.sql: Create replicated and distributed tables
-- Uses macros for cluster awareness

-- Replicated table for user_activity
CREATE TABLE IF NOT EXISTS default.user_activity_local ON CLUSTER '{cluster}' (
    user_id UInt32,
    login_time DateTime,
    logout_time DateTime,
    session_id String,
    ip_address String
) ENGINE = ReplicatedMergeTree('/clickhouse/tables/{shard}/user_activity', '{replica}')
ORDER BY (user_id, login_time);

-- Distributed table for user_activity
CREATE TABLE IF NOT EXISTS default.user_activity ON CLUSTER '{cluster}' AS default.user_activity_local
ENGINE = Distributed('{cluster}', default, user_activity_local, user_id);

-- Replicated table for sales_orders
CREATE TABLE IF NOT EXISTS default.sales_orders_local ON CLUSTER '{cluster}' (
    order_id UInt32,
    user_id UInt32,
    product String,
    amount Float32,
    order_time DateTime
) ENGINE = ReplicatedMergeTree('/clickhouse/tables/{shard}/sales_orders', '{replica}')
ORDER BY (order_id);

-- Distributed table for sales_orders
CREATE TABLE IF NOT EXISTS default.sales_orders ON CLUSTER '{cluster}' (
    order_id UUID,
    customer_id UInt32,
    product_name String,
    amount Float64,
    created_at DateTime
) ENGINE = ReplicatedMergeTree()
PARTITION BY toYYYYMM(created_at)
ORDER BY (created_at);

-- Replicated table for system_logs
CREATE TABLE IF NOT EXISTS default.system_logs_local ON CLUSTER '{cluster}' (
    log_time DateTime,
    level String,
    ip_address String,
    message String
) ENGINE = ReplicatedMergeTree('/clickhouse/tables/{shard}/system_logs', '{replica}')
ORDER BY (log_time);

-- Distributed table for system_logs
CREATE TABLE IF NOT EXISTS default.system_logs ON CLUSTER '{cluster}' (
    log_id UUID,
    user_id UInt32,
    message String,
    timestamp DateTime
) ENGINE = ReplicatedMergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (timestamp)
SETTINGS index_granularity = 8192;

-- If you have a distributed table, use:
-- CREATE TABLE IF NOT EXISTS default.system_logs_dist AS default.system_logs
-- ENGINE = Distributed('{cluster}', default, system_logs, sipHash64(log_id)); 