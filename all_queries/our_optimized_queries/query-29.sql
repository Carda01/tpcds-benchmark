-- Similar to optimization of query 17,
-- Created two CTEs to avoid joining the two large fact tables store_sales and store_returns
-- & filtering them afterwards in the main query
-- Each CTE contains one of the fact tables with the relative filters. Also, one 
-- CTE use partitioned tables (the store_sales) allowing better scaling
-- Last, explicit joins are used in all CTEs and query

--Filter store sales taking advantage of the partitioned table
WITH filtered_store_sales AS (
    SELECT *
    FROM store_sales_partitioned ss
    JOIN date_dim d1 ON ss.ss_sold_date_sk = d1.d_date_sk
    WHERE d1.d_moy = 4
      AND d1.d_year = 1999
),
filtered_store_returns AS (
    SELECT *
    FROM store_returns sr
    JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
    WHERE d2.d_moy BETWEEN 4 AND 4 + 3
      AND d2.d_year = 1999
),
-- Filter catalog sales taking advantage of the partitioned table
filtered_catalog_sales AS (
    SELECT *
    FROM catalog_sales_partitioned cs
    JOIN date_dim d3 ON cs.cs_sold_date_sk = d3.d_date_sk
    WHERE d3.d_year IN (1999, 2000, 2001)
)
SELECT   
     i.i_item_id,
     i.i_item_desc,
     s.s_store_id,
     s.s_store_name,
     stddev_samp(fss.ss_quantity)        AS store_sales_quantity,
     stddev_samp(fsr.sr_return_quantity) AS store_returns_quantity,
     stddev_samp(fcs.cs_quantity)        AS catalog_sales_quantity
FROM filtered_store_sales fss
JOIN filtered_store_returns fsr
    ON fss.ss_customer_sk = fsr.sr_customer_sk
   AND fss.ss_item_sk = fsr.sr_item_sk
   AND fss.ss_ticket_number = fsr.sr_ticket_number
JOIN filtered_catalog_sales fcs
    ON fsr.sr_customer_sk = fcs.cs_bill_customer_sk
   AND fsr.sr_item_sk = fcs.cs_item_sk
JOIN store s
    ON s.s_store_sk = fss.ss_store_sk
JOIN item i
    ON i.i_item_sk = fss.ss_item_sk
GROUP BY
     i.i_item_id,
     i.i_item_desc,
     s.s_store_id,
     s.s_store_name
ORDER BY
     i.i_item_id,
     i.i_item_desc,
     s.s_store_id,
     s.s_store_name
LIMIT 100;