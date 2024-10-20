-- Create cte to filter the store sales for specific quarter
WITH filtered_store_sales AS (
	SELECT *
	FROM store_sales_partitioned
	JOIN date_dim d1 ON d1.d_date_sk = ss_sold_date_sk AND d1.d_year = 1999
	WHERE d1.d_quarter_name = '1999Q1'
),
-- Create another cte to filter the store returns for specific quarters
filtered_store_returns AS (
	SELECT *
	FROM store_returns
	JOIN date_dim d2 ON sr_returned_date_sk = d2.d_date_sk
   	WHERE d2.d_quarter_name in ('1999Q1','1999Q2','1999Q3')
),
-- Create another cte to filter the catalog_sales for specific quarters
filtered_catalog_sales AS (
	SELECT *
	FROM catalog_sales_partitioned
	JOIN date_dim d3 ON cs_sold_date_sk = d3.d_date_sk AND d3.d_year = 1999
   	WHERE d3.d_quarter_name in ('1999Q1','1999Q2','1999Q3')
)
select  i_item_id
       ,i_item_desc
       ,s_state
       ,count(ss_quantity) as store_sales_quantitycount
       ,avg(ss_quantity) as store_sales_quantityave
       ,stddev_samp(ss_quantity) as store_sales_quantitystdev
       ,stddev_samp(ss_quantity)/avg(ss_quantity) as store_sales_quantitycov
       ,count(sr_return_quantity) as store_returns_quantitycount
       ,avg(sr_return_quantity) as store_returns_quantityave
       ,stddev_samp(sr_return_quantity) as store_returns_quantitystdev
       ,stddev_samp(sr_return_quantity)/avg(sr_return_quantity) as store_returns_quantitycov
       ,count(cs_quantity) as catalog_sales_quantitycount ,avg(cs_quantity) as catalog_sales_quantityave
       ,stddev_samp(cs_quantity) as catalog_sales_quantitystdev
       ,stddev_samp(cs_quantity)/avg(cs_quantity) as catalog_sales_quantitycov
 from filtered_store_sales
 JOIN filtered_store_returns ON ss_customer_sk = sr_customer_sk AND ss_item_sk = sr_item_sk AND ss_ticket_number = sr_ticket_number
 JOIN filtered_catalog_sales ON sr_customer_sk = cs_bill_customer_sk AND sr_item_sk = cs_item_sk
 JOIN store ON s_store_sk = ss_store_sk
 JOIN item ON i_item_sk = ss_item_sk
 group by i_item_id
         ,i_item_desc
         ,s_state
 order by i_item_id
         ,i_item_desc
         ,s_state
limit 100;


