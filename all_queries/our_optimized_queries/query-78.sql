-- Filtering year in the CTE to take advantage of the partitioned tables
-- Also instead of joining table the returns tables in each CTE
-- used not exists with subquery
WITH ws AS
(SELECT d_year AS ws_sold_year,
  		ws_item_sk,
    	ws_bill_customer_sk ws_customer_sk,
    	SUM(ws_quantity) ws_qty,
    	SUM(ws_wholesale_cost) ws_wc,
    	SUM(ws_sales_price) ws_sp
   FROM web_sales_partitioned ws
   JOIN date_dim ON ws_sold_date_sk = d_date_sk AND d_year=2001
   WHERE NOT EXISTS (
      SELECT 1
      FROM web_returns wr
      WHERE wr.wr_order_number = ws.ws_order_number 
        AND wr.wr_item_sk = ws.ws_item_sk
    )
   GROUP BY d_year, ws_item_sk, ws_bill_customer_sk
),
cs AS
(SELECT d_year AS cs_sold_year,
  	cs_item_sk,
    cs_bill_customer_sk cs_customer_sk,
    SUM(cs_quantity) cs_qty,
    SUM(cs_wholesale_cost) cs_wc,
    SUM(cs_sales_price) cs_sp
   FROM catalog_sales_partitioned cs
   JOIN date_dim ON cs_sold_date_sk = d_date_sk AND d_year=2001
   WHERE NOT EXISTS (
      SELECT 1
      FROM catalog_returns cr
      WHERE cr.cr_order_number = cs.cs_order_number 
        AND cr.cr_item_sk = cs.cs_item_sk
    )
   GROUP BY d_year, cs_item_sk, cs_bill_customer_sk
),
ss AS
(SELECT d_year AS ss_sold_year,
  	ss_item_sk,
    ss_customer_sk,
    SUM(ss_quantity) ss_qty,
    SUM(ss_wholesale_cost) ss_wc,
    SUM(ss_sales_price) ss_sp
   FROM store_sales_partitioned ss
   JOIN date_dim ON ss_sold_date_sk = d_date_sk AND d_year=2001
   WHERE NOT EXISTS (
      SELECT 1
      FROM store_returns sr
      WHERE sr.sr_ticket_number = ss.ss_ticket_number 
        AND sr.sr_item_sk = ss.ss_item_sk
    )
   GROUP BY d_year, ss_item_sk, ss_customer_sk
)
-- Removed condition of the year inside join since CTEs are already filtered by year
SELECT ss_customer_sk,
	round(ss_qty/(COALESCE(ws_qty,0)+COALESCE(cs_qty,0)),2) ratio,
	ss_qty store_qty, ss_wc store_wholesale_cost, ss_sp store_sales_price,
	COALESCE(ws_qty,0) + COALESCE(cs_qty,0) other_chan_qty,
	COALESCE(ws_wc,0 )+ COALESCE(cs_wc,0) other_chan_wholesale_cost,
	COALESCE(ws_sp,0) + COALESCE(cs_sp,0) other_chan_sales_price
FROM ss
LEFT JOIN ws ON ws_item_sk=ss_item_sk AND ws_customer_sk=ss_customer_sk
LEFT JOIN cs ON cs_item_sk=ss_item_sk AND cs_customer_sk=ss_customer_sk
WHERE (COALESCE(ws_qty,0)>0 OR COALESCE(cs_qty, 0)>0)
ORDER BY 
  ss_customer_sk,
  ss_qty DESC,
  ss_wc DESC,
  ss_sp DESC,
  other_chan_qty,
  other_chan_wholesale_cost,
  other_chan_sales_price,
  ratio
LIMIT 100;