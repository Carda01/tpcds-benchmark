WITH frequent_ss_items AS (
    -- Retrieve items sold more than 4 times across the relevant years
    SELECT substr(i_item_desc, 1, 30) AS itemdesc, i_item_sk AS item_sk, d_date AS solddate, COUNT(*) AS cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year IN (2000, 2001, 2002, 2003)
    GROUP BY substr(i.i_item_desc, 1, 30), i.i_item_sk, d.d_date
    HAVING COUNT(*) > 4
),
max_store_sales AS (
    -- Calculate the maximum total sales per customer
    SELECT MAX(csales) AS tpcds_cmax
    FROM (
        SELECT ss.ss_customer_sk, SUM(ss.ss_quantity * ss.ss_sales_price) AS csales
        FROM store_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_year IN (2000, 2001, 2002, 2003)
        GROUP BY ss.ss_customer_sk
    ) x
),
best_ss_customer AS (
    -- Identify the top customers who made more than 95% of the max sales
    SELECT ss.ss_customer_sk
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY ss.ss_customer_sk
    HAVING SUM(ss.ss_quantity * ss.ss_sales_price) > (95 / 100.0) * (SELECT tpcds_cmax FROM max_store_sales)
)
-- Main Query: Fetch sales from both catalog and web sales channels, filtered by frequent items and best customers
SELECT c.c_last_name, c.c_first_name, SUM(sales) AS total_sales
FROM (
    -- Catalog sales part
    SELECT cs.cs_bill_customer_sk AS customer_sk, cs.cs_quantity * cs.cs_list_price AS sales
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000 AND d.d_moy = 3
      AND cs.cs_item_sk IN (SELECT item_sk FROM frequent_ss_items)
      AND cs.cs_bill_customer_sk IN (SELECT ss_customer_sk FROM best_ss_customer)
    
    UNION ALL
    
    -- Web sales part
    SELECT ws.ws_bill_customer_sk AS customer_sk, ws.ws_quantity * ws.ws_list_price AS sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000 AND d.d_moy = 3
      AND ws.ws_item_sk IN (SELECT item_sk FROM frequent_ss_items)
      AND ws.ws_bill_customer_sk IN (SELECT ss_customer_sk FROM best_ss_customer)
) sales_data
JOIN customer c ON sales_data.customer_sk = c.c_customer_sk
GROUP BY c.c_last_name, c.c_first_name
ORDER BY c.c_last_name, c.c_first_name, total_sales
LIMIT 100;