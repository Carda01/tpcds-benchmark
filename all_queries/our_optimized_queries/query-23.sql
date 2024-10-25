--deletes the temp tables if they already exist
DROP TABLE if exists frequent_ss_items;
DROP TABLE if exists max_store_sales;
DROP TABLE if exists best_ss_customer;

-- Creation of temp tables to avoid executing twice the same CTE
-- Retrieve items sold more than 4 times across the relevant years
-- Also use partitioned tables with d_year filtering
CREATE TEMP TABLE frequent_ss_items AS 
(
    SELECT 
        substr(i_item_desc, 1, 30) AS itemdesc, 
        i_item_sk AS item_sk, 
        d_date AS solddate, 
        COUNT(*) AS cnt
    FROM 
        store_sales_partitioned
    JOIN 
        date_dim ON ss_sold_date_sk = d_date_sk AND d_year IN (2000, 2000 + 1, 2000 + 2, 2000 + 3)
    JOIN 
        item ON ss_item_sk = i_item_sk
    GROUP BY 
        substr(i_item_desc, 1, 30), i_item_sk, d_date
    HAVING 
        COUNT(*) > 4
);

-- Calculate the maximum total sales per customer with use of partitioned tables with d_year filtering
CREATE TEMP TABLE max_store_sales AS
(
    SELECT 
        MAX(csales) AS tpcds_cmax 
    FROM 
        (
            SELECT 
                c_customer_sk, 
                SUM(ss_quantity * ss_sales_price) AS csales
            FROM 
                store_sales_partitioned
            JOIN 
                customer ON ss_customer_sk = c_customer_sk
            JOIN 
                date_dim ON ss_sold_date_sk = d_date_sk AND d_year IN (2000, 2000 + 1, 2000 + 2, 2000 + 3)      
            GROUP BY 
                c_customer_sk
        ) x
);

-- Identify the top customers who made more than 95% of the max sales
CREATE TEMP TABLE best_ss_customer AS
(
    SELECT 
        c_customer_sk, 
        SUM(ss_quantity * ss_sales_price) AS ssales
    FROM 
        store_sales
    JOIN 
        customer ON ss_customer_sk = c_customer_sk
    GROUP BY 
        c_customer_sk
    HAVING 
        SUM(ss_quantity * ss_sales_price) > (95 / 100.0) * (SELECT * FROM max_store_sales)
);

-- Calculate the total sales from catalog and web sales for a specific month and year
--filtered by frequent items and best customers and using partitioned tables with early
-- year filtering to take advantage of partitions
SELECT SUM(sales)
FROM (
    SELECT cs_quantity * cs_list_price AS sales
    FROM catalog_sales_partitioned
    JOIN date_dim ON cs_sold_date_sk = d_date_sk AND d_year = 2000
    WHERE d_moy = 3
      AND cs_item_sk IN (SELECT item_sk FROM frequent_ss_items)
      AND cs_bill_customer_sk IN (SELECT c_customer_sk FROM best_ss_customer)
    
    UNION ALL
    
    SELECT ws_quantity * ws_list_price AS sales
    FROM web_sales_partitioned
    JOIN date_dim ON ws_sold_date_sk = d_date_sk AND d_year = 2000 
    WHERE d_moy = 3
      AND ws_item_sk IN (SELECT item_sk FROM frequent_ss_items)
      AND ws_bill_customer_sk IN (SELECT c_customer_sk FROM best_ss_customer)
) x
LIMIT 100;

-- Get sales from both catalog and web sales channels, filtered by frequent items and best customers
SELECT c_last_name, c_first_name, sales
FROM (
    SELECT 
        c_last_name,
        c_first_name,
        SUM(cs_quantity * cs_list_price) AS sales
    FROM 
        catalog_sales_partitioned
	JOIN 
        date_dim ON cs_sold_date_sk = d_date_sk AND d_year = 2000
    JOIN 
        customer ON cs_bill_customer_sk = c_customer_sk
    WHERE d_moy = 3
        AND cs_item_sk IN (SELECT item_sk FROM frequent_ss_items)
        AND cs_bill_customer_sk IN (SELECT c_customer_sk FROM best_ss_customer)
    GROUP BY 
        c_last_name, c_first_name

    UNION ALL

    SELECT 
        c_last_name,
        c_first_name,
        SUM(ws_quantity * ws_list_price) AS sales
    FROM 
        web_sales_partitioned
	JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk AND d_year = 2000
    JOIN 
        customer ON ws_bill_customer_sk = c_customer_sk
    WHERE d_moy = 3
        AND ws_item_sk IN (SELECT item_sk FROM frequent_ss_items)
        AND ws_bill_customer_sk IN (SELECT c_customer_sk FROM best_ss_customer)
    GROUP BY 
        c_last_name, c_first_name
) x
ORDER BY 
    c_last_name, c_first_name, sales
LIMIT 100;