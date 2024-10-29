-- Creation of CTEs in order to avoid using subqueries with 'in'
-- This way we avoid checking the filter 'in' condition for each separate row
-- Distinct is used in order to keep the same number of rows when using join
-- Without the distinct filter, using left join would result in more rows
-- (effectively "duplicating" the row from the left table for each match to the right table)
WITH ws_wh AS (
    SELECT DISTINCT ws1.ws_order_number
    FROM web_sales_partitioned ws1
    JOIN web_sales_partitioned ws2 ON ws1.ws_order_number = ws2.ws_order_number
    WHERE ws1.ws_warehouse_sk <> ws2.ws_warehouse_sk
),
-- CTE containing the join of web_returns with ws_wh
wr_ws_wh AS(
	SELECT DISTINCT wr_order_number
	FROM web_returns, ws_wh
    WHERE wr_order_number = ws_wh.ws_order_number
)
SELECT  
    COUNT(DISTINCT ws1.ws_order_number) AS "order count",
    SUM(ws1.ws_ext_ship_cost) AS "total shipping cost",
    SUM(ws1.ws_net_profit) AS "total net profit"
FROM web_sales_partitioned ws1
JOIN date_dim ON ws1.ws_ship_date_sk = date_dim.d_date_sk
JOIN customer_address ON ws1.ws_ship_addr_sk = customer_address.ca_address_sk
JOIN web_site ON ws1.ws_web_site_sk = web_site.web_site_sk
-- Replaced the filtering 'in' operator and subqueries with explicit joins
-- More efficient way of filtering
JOIN ws_wh ON ws1.ws_order_number = ws_wh.ws_order_number
JOIN wr_ws_wh wr ON ws1.ws_order_number = wr.wr_order_number
WHERE date_dim.d_date BETWEEN '2002-05-01' AND (DATE '2002-05-01' + INTERVAL '60 days')
  AND customer_address.ca_state = 'MA'
  AND web_site.web_company_name = 'pri'
ORDER BY COUNT(DISTINCT ws1.ws_order_number)
LIMIT 100;