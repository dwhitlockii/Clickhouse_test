-- 02_load_data.sql: Load CSVs into local tables
-- Assumes CSVs are mounted at /data/ in each container

-- Load user_activity
INSERT INTO default.user_activity_local FORMAT CSVWithNames
INFILE '/data/user_activity.csv';

-- Load sales_orders
INSERT INTO default.sales_orders_local FORMAT CSVWithNames
INFILE '/data/sales_orders.csv';

-- Load system_logs
INSERT INTO default.system_logs_local FORMAT CSVWithNames
INFILE '/data/system_logs.csv'; 