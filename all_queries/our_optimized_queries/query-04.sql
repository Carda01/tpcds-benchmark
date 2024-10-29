-- Instead of using 1 CTE containing the various sales of catalog, web and store,
-- we create 3 CTEs one for catalog, one for web and one for store. That way
-- we avoid having a huge table containing a lot of duplicate customers attributes
-- When we join table in the main query, explicit joins are used for which query planner generally performs better
-- Also, used partitions with explicit joins taking advantage of partition pruning
-- by filtering by d_year (which is the attribute that splits the partitions)

--CTE containing the year total for store sales as a sum of various price components
-- for each customer for two specific years
WITH store_year_total AS (
    SELECT c.c_customer_id AS customer_id,
           c.c_first_name AS customer_first_name,
           c.c_last_name AS customer_last_name,
           c.c_preferred_cust_flag AS customer_preferred_cust_flag,
           c.c_birth_country AS customer_birth_country,
           c.c_login AS customer_login,
           c.c_email_address AS customer_email_address,
           d.d_year AS dyear,
           SUM(((ss_ext_list_price - ss_ext_wholesale_cost - ss_ext_discount_amt) + ss_ext_sales_price) / 2) AS year_total
    FROM customer c
    JOIN store_sales_partitioned ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year IN (2001, 2002)
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag,
             c.c_birth_country, c.c_login, c.c_email_address, d.d_year
),
-- CTE containing the year total for catalog sales as a sum of various price components
-- for each customer for two specific years
catalog_year_total AS (
    SELECT c.c_customer_id AS customer_id,
           c.c_first_name AS customer_first_name,
           c.c_last_name AS customer_last_name,
           c.c_preferred_cust_flag AS customer_preferred_cust_flag,
           c.c_birth_country AS customer_birth_country,
           c.c_login AS customer_login,
           c.c_email_address AS customer_email_address,
           d.d_year AS dyear,
           SUM(((cs_ext_list_price - cs_ext_wholesale_cost - cs_ext_discount_amt) + cs_ext_sales_price) / 2) AS year_total
    FROM customer c
    JOIN catalog_sales_partitioned cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year IN (2001, 2002)
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag,
             c.c_birth_country, c.c_login, c.c_email_address, d.d_year
),
-- CTE containing the year total for web sales as a sum of various price components
-- for each customer for two specific years
web_year_total AS (
    SELECT c.c_customer_id AS customer_id,
           c.c_first_name AS customer_first_name,
           c.c_last_name AS customer_last_name,
           c.c_preferred_cust_flag AS customer_preferred_cust_flag,
           c.c_birth_country AS customer_birth_country,
           c.c_login AS customer_login,
           c.c_email_address AS customer_email_address,
           d.d_year AS dyear,
           SUM(((ws_ext_list_price - ws_ext_wholesale_cost - ws_ext_discount_amt) + ws_ext_sales_price) / 2) AS year_total
    FROM customer c
    JOIN web_sales_partitioned ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year IN (2001, 2002)
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag,
             c.c_birth_country, c.c_login, c.c_email_address, d.d_year
)
-- Find all the customers with positive number of purchases for the first year in all channels
-- and for which the proportion of catalog sales in 2002 relative to 2001 is greater than
-- the proportion of store sales in 2002 relative to 2001 and also greater than
-- the proportion of web sales in 2002 relative to 2001
SELECT store_2002.customer_id,
       store_2002.customer_first_name,
       store_2002.customer_last_name,
       store_2002.customer_email_address
FROM store_year_total store_2001
JOIN store_year_total store_2002 ON store_2001.customer_id = store_2002.customer_id AND store_2001.dyear = 2001 AND store_2002.dyear = 2002
JOIN catalog_year_total cat_2001 ON store_2001.customer_id = cat_2001.customer_id AND cat_2001.dyear = 2001
JOIN catalog_year_total cat_2002 ON store_2001.customer_id = cat_2002.customer_id AND cat_2002.dyear = 2002
JOIN web_year_total web_2001 ON store_2001.customer_id = web_2001.customer_id AND web_2001.dyear = 2001
JOIN web_year_total web_2002 ON store_2001.customer_id = web_2002.customer_id AND web_2002.dyear = 2002
WHERE store_2001.year_total > 0
  AND cat_2001.year_total > 0
  AND web_2001.year_total > 0
  AND cat_2002.year_total / cat_2001.year_total > store_2002.year_total / store_2001.year_total
  AND cat_2002.year_total / cat_2001.year_total > web_2002.year_total / web_2001.year_total
ORDER BY store_2002.customer_id, store_2002.customer_first_name, store_2002.customer_last_name, store_2002.customer_email_address
LIMIT 100;