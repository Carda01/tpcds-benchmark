-- CTE containing the yearly sample standard deviation of net paid for store sales 
-- for each customer for two specific years
WITH store_year_total AS (
 SELECT c_customer_id customer_id,
 		c_first_name customer_first_name,
       	c_last_name customer_last_name,
       	d_year as year,
       	stddev_samp(ss_net_paid) year_total
 FROM customer
 JOIN store_sales_partitioned ON c_customer_sk = ss_customer_sk
 JOIN date_dim ON ss_sold_date_sk = d_date_sk AND d_year IN (2001,2001+1)
 GROUP BY c_customer_id,
          c_first_name,
          c_last_name,
          d_year
),
-- CTE containing the yearly sample standard deviation of net paid for web sales 
-- for each customer for two specific years
web_year_total AS (
 SELECT c_customer_id customer_id,
        c_first_name customer_first_name,
        c_last_name customer_last_name,
        d_year as year,
        stddev_samp(ws_net_paid) year_total
 FROM customer
 JOIN web_sales_partitioned ON c_customer_sk = ws_bill_customer_sk
 JOIN date_dim ON ws_sold_date_sk = d_date_sk
   AND d_year IN (2001,2001+1)
 GROUP BY c_customer_id,
          c_first_name,
          c_last_name,
          d_year
)
-- Find all the customers with positive standard deviation of net paid for the first year (2001) in 
-- the interested channels of web sales and store sales
-- and for which the proportion of web standard deviation of net paid in 2002 relative to 2001 is greater than
-- the proportion of store standard deviation of net paid in 2002 relative to 2001 
SELECT t_s_secyear.customer_id,
		t_s_secyear.customer_first_name,
		t_s_secyear.customer_last_name
FROM store_year_total t_s_firstyear
JOIN store_year_total t_s_secyear ON t_s_secyear.customer_id = t_s_firstyear.customer_id
	AND t_s_firstyear.year = 2001 AND t_s_secyear.year = 2001+1
JOIN web_year_total t_w_firstyear ON t_s_firstyear.customer_id = t_w_firstyear.customer_id
	AND t_w_firstyear.year = 2001
JOIN web_year_total t_w_secyear ON t_s_firstyear.customer_id = t_w_secyear.customer_id
	AND t_w_secyear.year = 2001+1
WHERE t_s_firstyear.year_total > 0
	AND t_w_firstyear.year_total > 0
	AND t_w_secyear.year_total / t_w_firstyear.year_total > t_s_secyear.year_total / t_s_firstyear.year_total
ORDER BY 3,2,1
LIMIT 100;