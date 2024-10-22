drop table if exists web_sales_partitioned;
create table web_sales_partitioned
(
    ws_sold_date_sk           integer                       ,
    ws_sold_time_sk           integer                       ,
    ws_ship_date_sk           integer                       ,
    ws_item_sk                integer               not null,
    ws_bill_customer_sk       integer                       ,
    ws_bill_cdemo_sk          integer                       ,
    ws_bill_hdemo_sk          integer                       ,
    ws_bill_addr_sk           integer                       ,
    ws_ship_customer_sk       integer                       ,
    ws_ship_cdemo_sk          integer                       ,
    ws_ship_hdemo_sk          integer                       ,
    ws_ship_addr_sk           integer                       ,
    ws_web_page_sk            integer                       ,
    ws_web_site_sk            integer                       ,
    ws_ship_mode_sk           integer                       ,
    ws_warehouse_sk           integer                       ,
    ws_promo_sk               integer                       ,
    ws_order_number           integer               not null,
    ws_quantity               integer                       ,
    ws_wholesale_cost         decimal(7,2)                  ,
    ws_list_price             decimal(7,2)                  ,
    ws_sales_price            decimal(7,2)                  ,
    ws_ext_discount_amt       decimal(7,2)                  ,
    ws_ext_sales_price        decimal(7,2)                  ,
    ws_ext_wholesale_cost     decimal(7,2)                  ,
    ws_ext_list_price         decimal(7,2)                  ,
    ws_ext_tax                decimal(7,2)                  ,
    ws_coupon_amt             decimal(7,2)                  ,
    ws_ext_ship_cost          decimal(7,2)                  ,
    ws_net_paid               decimal(7,2)                  ,
    ws_net_paid_inc_tax       decimal(7,2)                  ,
    ws_net_paid_inc_ship      decimal(7,2)                  ,
    ws_net_paid_inc_ship_tax  decimal(7,2)                  ,
    ws_net_profit             decimal(7,2)                  ,
    primary key (ws_item_sk, ws_order_number, ws_sold_date_sk)
)PARTITION BY RANGE (ws_sold_date_sk);

-- Create partitions for each year, this script fills those partitions with the min and max d_date_sk
-- keys for that year. Since the d_date_sk does not have the standard date format, we need to execute
-- a select statement to retrieve the minimum d_date_sk and maximum d_date_sk for each year
DO $$
DECLARE
    record_row RECORD;  -- Variable to hold each row in the loop
BEGIN
    -- Iterate over the results of the SELECT statement
    FOR record_row IN
        SELECT MIN(d_date_sk) AS min_date, MAX(d_date_sk) AS max_date,
               EXTRACT(YEAR FROM d_date) AS year_date, COUNT(*) AS count_dates
        FROM date_dim
        JOIN web_sales ON d_date_sk = ws_sold_date_sk
        GROUP BY EXTRACT(YEAR FROM d_date)
        ORDER BY EXTRACT(YEAR FROM d_date) ASC
    LOOP
        -- Construct and execute the dynamic SQL for creating the partition
        EXECUTE format('
            CREATE TABLE web_sales_partitioned_%s PARTITION OF web_sales_partitioned
            FOR VALUES FROM (%s) TO (%s)',
            record_row.year_date, record_row.min_date, record_row.max_date
        );
    END LOOP;
END $$;
CREATE TABLE web_sales_partitioned_default PARTITION OF web_sales_partitioned DEFAULT;

-- Now we fill the partitions, first with all non-null records
INSERT INTO web_sales_partitioned
SELECT * FROM web_sales  where ws_sold_date_sk is not null;

-- Postgres does not allow null values for primary keys, due to automatic non-null constraint
-- That is why we assign the value -1 to replace all null values for ws_sold_date_sk
INSERT INTO web_sales_partitioned(ws_sold_date_sk, ws_sold_time_sk, ws_ship_date_sk, ws_item_sk,
	ws_bill_customer_sk, ws_bill_cdemo_sk, ws_bill_hdemo_sk, ws_bill_addr_sk, ws_ship_customer_sk,
	ws_ship_cdemo_sk, ws_ship_hdemo_sk, ws_ship_addr_sk, ws_web_page_sk,
	ws_web_site_sk, ws_ship_mode_sk, ws_warehouse_sk, ws_promo_sk, ws_order_number,
	ws_quantity, ws_wholesale_cost, ws_list_price, ws_sales_price, ws_ext_discount_amt,
	ws_ext_sales_price, ws_ext_wholesale_cost, ws_ext_list_price, ws_ext_tax, ws_coupon_amt,
	ws_ext_ship_cost, ws_net_paid, ws_net_paid_inc_tax, ws_net_paid_inc_ship,
	ws_net_paid_inc_ship_tax, ws_net_profit	)
SELECT -1, ws_sold_time_sk, ws_ship_date_sk, ws_item_sk, ws_bill_customer_sk,
	ws_bill_cdemo_sk, ws_bill_hdemo_sk, ws_bill_addr_sk, ws_ship_customer_sk,
	ws_ship_cdemo_sk, ws_ship_hdemo_sk, ws_ship_addr_sk, ws_web_page_sk,
	ws_web_site_sk, ws_ship_mode_sk, ws_warehouse_sk, ws_promo_sk, ws_order_number,
	ws_quantity, ws_wholesale_cost, ws_list_price, ws_sales_price, ws_ext_discount_amt,
	ws_ext_sales_price, ws_ext_wholesale_cost, ws_ext_list_price, ws_ext_tax, ws_coupon_amt,
	ws_ext_ship_cost, ws_net_paid, ws_net_paid_inc_tax, ws_net_paid_inc_ship,
	ws_net_paid_inc_ship_tax, ws_net_profit
FROM web_sales where ws_sold_date_sk is null;

-- we can not create one global index so we create index separately on each partition
-- for that we use the following script. Also hash index is used since only equality operators
-- are used in the queries regarding this key
DO $$
DECLARE
    record_row RECORD;  -- Variable to hold each row in the loop
BEGIN
    -- Iterate over the results of the SELECT statement
    FOR record_row IN
        SELECT inhrelid::regclass AS partition_name
		FROM pg_inherits
		WHERE inhparent = 'web_sales_partitioned'::regclass
    LOOP
        -- Construct and execute the dynamic SQL for creating the partition
        EXECUTE format('
            CREATE INDEX %s_ind ON %s USING HASH (ws_sold_date_sk)',
            record_row.partition_name, record_row.partition_name
        );
    END LOOP;
END $$;