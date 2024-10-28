drop table if exists catalog_sales_partitioned;
create table catalog_sales_partitioned
(
    cs_sold_date_sk           integer                       ,
    cs_sold_time_sk           integer                       ,
    cs_ship_date_sk           integer                       ,
    cs_bill_customer_sk       integer                       ,
    cs_bill_cdemo_sk          integer                       ,
    cs_bill_hdemo_sk          integer                       ,
    cs_bill_addr_sk           integer                       ,
    cs_ship_customer_sk       integer                       ,
    cs_ship_cdemo_sk          integer                       ,
    cs_ship_hdemo_sk          integer                       ,
    cs_ship_addr_sk           integer                       ,
    cs_call_center_sk         integer                       ,
    cs_catalog_page_sk        integer                       ,
    cs_ship_mode_sk           integer                       ,
    cs_warehouse_sk           integer                       ,
    cs_item_sk                integer               not null,
    cs_promo_sk               integer                       ,
    cs_order_number           integer               not null,
    cs_quantity               integer                       ,
    cs_wholesale_cost         decimal(7,2)                  ,
    cs_list_price             decimal(7,2)                  ,
    cs_sales_price            decimal(7,2)                  ,
    cs_ext_discount_amt       decimal(7,2)                  ,
    cs_ext_sales_price        decimal(7,2)                  ,
    cs_ext_wholesale_cost     decimal(7,2)                  ,
    cs_ext_list_price         decimal(7,2)                  ,
    cs_ext_tax                decimal(7,2)                  ,
    cs_coupon_amt             decimal(7,2)                  ,
    cs_ext_ship_cost          decimal(7,2)                  ,
    cs_net_paid               decimal(7,2)                  ,
    cs_net_paid_inc_tax       decimal(7,2)                  ,
    cs_net_paid_inc_ship      decimal(7,2)                  ,
    cs_net_paid_inc_ship_tax  decimal(7,2)                  ,
    cs_net_profit             decimal(7,2),
	primary key (cs_item_sk, cs_order_number,cs_sold_date_sk)
)PARTITION BY RANGE (cs_sold_date_sk);

select min(d_date_sk), max(d_date_sk), extract(year from d_date), COUNT(*) from date_dim
JOIN catalog_sales ON d_date_sk=cs_sold_date_sk
group by extract(year from d_date)
order by extract(year from d_date) ASC;

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
        JOIN catalog_sales ON d_date_sk = cs_sold_date_sk
        GROUP BY EXTRACT(YEAR FROM d_date)
        ORDER BY EXTRACT(YEAR FROM d_date) ASC
    LOOP
        -- Construct and execute the dynamic SQL for creating the partition
        EXECUTE format('
            CREATE TABLE catalog_sales_partitioned_%s PARTITION OF catalog_sales_partitioned
            FOR VALUES FROM (%s) TO (%s)',
            record_row.year_date, record_row.min_date, record_row.max_date
        );
    END LOOP;
END $$;
CREATE TABLE catalog_sales_partitioned_default PARTITION OF catalog_sales_partitioned DEFAULT;

-- Now we fill the partitions, first with all non-null records
INSERT INTO catalog_sales_partitioned
SELECT * FROM catalog_sales  where cs_sold_date_sk is not null;

-- Postgres does not allow null values for primary keys, automatic non-null constraint
-- That is why we assign the value -1 to replace all null values for cs_sold_date_sk
INSERT INTO catalog_sales_partitioned(cs_sold_date_sk,cs_sold_time_sk,cs_ship_date_sk,cs_bill_customer_sk,
	cs_bill_cdemo_sk,cs_bill_hdemo_sk,cs_bill_addr_sk,cs_ship_customer_sk,
	cs_ship_cdemo_sk,cs_ship_hdemo_sk,cs_ship_addr_sk,cs_call_center_sk,
	cs_catalog_page_sk,cs_ship_mode_sk,cs_warehouse_sk,cs_item_sk,cs_promo_sk,
	cs_order_number,cs_quantity,cs_wholesale_cost,cs_list_price,cs_sales_price,
	cs_ext_discount_amt,cs_ext_sales_price,cs_ext_wholesale_cost,cs_ext_list_price,
	cs_ext_tax,cs_coupon_amt,cs_ext_ship_cost,cs_net_paid,cs_net_paid_inc_tax,
	cs_net_paid_inc_ship,cs_net_paid_inc_ship_tax,cs_net_profit)
SELECT -1, cs_sold_time_sk,cs_ship_date_sk,cs_bill_customer_sk,
	cs_bill_cdemo_sk,cs_bill_hdemo_sk,cs_bill_addr_sk,cs_ship_customer_sk,
	cs_ship_cdemo_sk,cs_ship_hdemo_sk,cs_ship_addr_sk,cs_call_center_sk,
	cs_catalog_page_sk,cs_ship_mode_sk,cs_warehouse_sk,cs_item_sk,cs_promo_sk,
	cs_order_number,cs_quantity,cs_wholesale_cost,cs_list_price,cs_sales_price,
	cs_ext_discount_amt,cs_ext_sales_price,cs_ext_wholesale_cost,cs_ext_list_price,
	cs_ext_tax,cs_coupon_amt,cs_ext_ship_cost,cs_net_paid,cs_net_paid_inc_tax,
	cs_net_paid_inc_ship,cs_net_paid_inc_ship_tax,cs_net_profit
FROM catalog_sales where cs_sold_date_sk is null;

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
		WHERE inhparent = 'catalog_sales_partitioned'::regclass
    LOOP
        -- Construct and execute the dynamic SQL for creating the partition indexes
        EXECUTE format('
            CREATE INDEX idx_%s_cs_sold_date_sk ON %s USING HASH (cs_sold_date_sk)',
            record_row.partition_name, record_row.partition_name
        );
        EXECUTE format('
            CREATE INDEX idx_%s_cs_bill_customer_sk ON %s USING HASH (cs_bill_customer_sk)',
            record_row.partition_name, record_row.partition_name
        );
        EXECUTE format('
            CREATE INDEX idx_%s_cs_item_sk ON %s USING HASH (cs_item_sk)',
            record_row.partition_name, record_row.partition_name
        );
    END LOOP;
END $$;