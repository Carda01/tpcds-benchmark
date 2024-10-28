drop table if exists store_sales_partitioned;
create table store_sales_partitioned
(
    ss_sold_date_sk           integer                       ,
    ss_sold_time_sk           integer                       ,
    ss_item_sk                integer               not null,
    ss_customer_sk            integer                       ,
    ss_cdemo_sk               integer                       ,
    ss_hdemo_sk               integer                       ,
    ss_addr_sk                integer                       ,
    ss_store_sk               integer                       ,
    ss_promo_sk               integer                       ,
    ss_ticket_number          integer               not null,
    ss_quantity               integer                       ,
    ss_wholesale_cost         decimal(7,2)                  ,
    ss_list_price             decimal(7,2)                  ,
    ss_sales_price            decimal(7,2)                  ,
    ss_ext_discount_amt       decimal(7,2)                  ,
    ss_ext_sales_price        decimal(7,2)                  ,
    ss_ext_wholesale_cost     decimal(7,2)                  ,
    ss_ext_list_price         decimal(7,2)                  ,
    ss_ext_tax                decimal(7,2)                  ,
    ss_coupon_amt             decimal(7,2)                  ,
    ss_net_paid               decimal(7,2)                  ,
    ss_net_paid_inc_tax       decimal(7,2)                  ,
    ss_net_profit             decimal(7,2)                  ,
    primary key (ss_item_sk, ss_ticket_number,ss_sold_date_sk)
)PARTITION BY RANGE (ss_sold_date_sk);

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
        JOIN store_sales ON d_date_sk = ss_sold_date_sk
        GROUP BY EXTRACT(YEAR FROM d_date)
        ORDER BY EXTRACT(YEAR FROM d_date) ASC
    LOOP
        -- Construct and execute the dynamic SQL for creating the partition
        EXECUTE format('
            CREATE TABLE store_sales_partitioned_%s PARTITION OF store_sales_partitioned
            FOR VALUES FROM (%s) TO (%s)',
            record_row.year_date, record_row.min_date, record_row.max_date
        );
    END LOOP;
END $$;
CREATE TABLE store_sales_partitioned_default PARTITION OF store_sales_partitioned DEFAULT;

-- Now we fill the partitions, first with all non-null records
INSERT INTO store_sales_partitioned
SELECT * FROM store_sales  where ss_sold_date_sk is not null;

-- Postgres does not allow null values for primary keys, due to automatic non-null constraint
-- That is why we assign the value -1 to replace all null values for ss_sold_date_sk
INSERT INTO store_sales_partitioned(ss_sold_date_sk,ss_sold_time_sk,ss_item_sk,ss_customer_sk,
    ss_cdemo_sk,ss_hdemo_sk,ss_addr_sk,ss_store_sk,ss_promo_sk,ss_ticket_number,ss_quantity,
    ss_wholesale_cost,ss_list_price,ss_sales_price,ss_ext_discount_amt,ss_ext_sales_price,
    ss_ext_wholesale_cost,ss_ext_list_price,ss_ext_tax,ss_coupon_amt,ss_net_paid,ss_net_paid_inc_tax,
    ss_net_profit)
SELECT -1,ss_sold_time_sk,ss_item_sk,ss_customer_sk,ss_cdemo_sk,ss_hdemo_sk,
	ss_addr_sk,ss_store_sk,ss_promo_sk,ss_ticket_number,ss_quantity,ss_wholesale_cost,
	ss_list_price,ss_sales_price,ss_ext_discount_amt,ss_ext_sales_price,ss_ext_wholesale_cost,
	ss_ext_list_price,ss_ext_tax,ss_coupon_amt,ss_net_paid,ss_net_paid_inc_tax,ss_net_profit
FROM store_sales where ss_sold_date_sk is null;

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
		WHERE inhparent = 'store_sales_partitioned'::regclass
    LOOP
        -- Construct and execute the dynamic SQL for creating the partition indexes
        EXECUTE format('
            CREATE INDEX idx_%s_ss_sold_date_sk ON %s USING HASH (ss_sold_date_sk)',
            record_row.partition_name, record_row.partition_name
        );
        EXECUTE format('
            CREATE INDEX idx_%s_ss_item_sk ON %s USING HASH (ss_item_sk)',
            record_row.partition_name, record_row.partition_name
        );
        EXECUTE format('
            CREATE INDEX idx_%s_ss_customer_sk ON %s USING HASH (ss_customer_sk)',
            record_row.partition_name, record_row.partition_name
        );
        EXECUTE format('
            CREATE INDEX idx_%s_ss_addr_sk ON %s USING HASH (ss_addr_sk)',
            record_row.partition_name, record_row.partition_name
        );
        EXECUTE format('
            CREATE INDEX idx_%s_ss_ticket_number ON %s USING HASH (ss_ticket_number)',
            record_row.partition_name, record_row.partition_name
        );
        EXECUTE format('
            CREATE INDEX idx_%s_ss_wholesale_cost ON %s USING BTREE (ss_wholesale_cost)',
            record_row.partition_name, record_row.partition_name
        );
        EXECUTE format('
            CREATE INDEX idx_%s_ss_list_price ON %s USING BTREE (ss_list_price)',
            record_row.partition_name, record_row.partition_name
        );
        EXECUTE format('
            CREATE INDEX idx_%s_ss_sales_price ON %s USING BTREE (ss_sales_price)',
            record_row.partition_name, record_row.partition_name
        );
    END LOOP;
END $$;