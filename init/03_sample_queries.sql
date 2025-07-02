-- 03_sample_queries.sql: Sample queries for validation

-- Count user activity events (should match CSV row count)
SELECT count(*) AS user_activity_events FROM default.user_activity;

-- Count sales orders by product
SELECT product, count(*) AS order_count FROM default.sales_orders GROUP BY product ORDER BY order_count DESC;

-- Join: Find users with failed logins (join user_activity and system_logs)
SELECT ua.user_id, ua.login_time, sl.message
FROM default.user_activity AS ua
JOIN default.system_logs AS sl
  ON ua.login_time = sl.log_time AND sl.level = 'ERROR';

-- Sharding/replication check: Show replicas for user_activity_local
SELECT
    database,
    table,
    engine,
    replica_path,
    replica_name
FROM system.replicas
WHERE table = 'user_activity_local'; 