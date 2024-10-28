-- Instead of using 1 CTE containing the various sales of web and store
-- and using a lot of filters in the main query,
-- we create 2 CTEs one for web and one for store. That way
-- we avoid having a huge table containing a lot of duplicate customers attributes
-- When we join table in the main query, explicit joins are used for which 
-- query planner generally performs better
-- Also, used partitions with explicit joins taking advantage of partition pruning
-- by filtering by the d_year (which is the attribute that divides into the partitions)

-- CTE containing the yearly total for store sales as a substraction of price list minus discount
-- (specific metrics) for each customer for every year there is any data
WITH store_year_total AS (
    SELECT 
        c_customer_id AS customer_id,
        c_first_name AS customer_first_name,
        c_last_name AS customer_last_name,
        c_preferred_cust_flag AS customer_preferred_cust_flag,
        c_birth_country AS customer_birth_country,
        c_login AS customer_login,
        c_email_address AS customer_email_address,
        d_year AS dyear,
        SUM(ss_ext_list_price - ss_ext_discount_amt) AS year_total
    FROM 
        customer
    JOIN 
        store_sales_partitioned ON c_customer_sk = ss_customer_sk
    JOIN 
        date_dim ON ss_sold_date_sk = d_date_sk
    GROUP BY 
        c_customer_id,
        c_first_name,
        c_last_name,
        c_preferred_cust_flag,
        c_birth_country,
        c_login,
        c_email_address,
        d_year
),
-- CTE containing the yearly total for web sales as a substraction of price list minus discount
-- (specific metrics) for each customer for every year there is data
web_year_total AS (
    SELECT 
        c_customer_id AS customer_id,
        c_first_name AS customer_first_name,
        c_last_name AS customer_last_name,
        c_preferred_cust_flag AS customer_preferred_cust_flag,
        c_birth_country AS customer_birth_country,
        c_login AS customer_login,
        c_email_address AS customer_email_address,
        d_year AS dyear,
        SUM(ws_ext_list_price - ws_ext_discount_amt) AS year_total
    FROM 
        customer
    JOIN 
        web_sales_partitioned ON c_customer_sk = ws_bill_customer_sk
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        c_customer_id,
        c_first_name,
        c_last_name,
        c_preferred_cust_flag,
        c_birth_country,
        c_login,
        c_email_address,
        d_year
)
-- Find all the customers with positive number of purchases for the first year (1999) in 
-- the interested channels of web sales and store sales
-- and for which the proportion of web sales in 2000 relative to 1999 is greater than
-- the proportion of store sales in 2000 relative to 1999 
SELECT
    t_s_secyear.customer_id,
    t_s_secyear.customer_first_name,
    t_s_secyear.customer_last_name,
    t_s_secyear.customer_email_address
FROM 
    store_year_total t_s_firstyear
JOIN 
    store_year_total t_s_secyear 
    ON t_s_secyear.customer_id = t_s_firstyear.customer_id
    AND t_s_firstyear.dyear = 1999
    AND t_s_secyear.dyear = 2000
JOIN 
    web_year_total t_w_firstyear 
    ON t_s_firstyear.customer_id = t_w_firstyear.customer_id
    AND t_w_firstyear.dyear = 1999
JOIN 
    web_year_total t_w_secyear 
    ON t_s_firstyear.customer_id = t_w_secyear.customer_id
    AND t_w_secyear.dyear = 2000
WHERE 
    t_s_firstyear.year_total > 0
    AND t_w_firstyear.year_total > 0
    AND (t_w_secyear.year_total / t_w_firstyear.year_total) > (t_s_secyear.year_total / t_s_firstyear.year_total)
ORDER BY 
    t_s_secyear.customer_id,
    t_s_secyear.customer_first_name,
    t_s_secyear.customer_last_name,
    t_s_secyear.customer_email_address
LIMIT 100;