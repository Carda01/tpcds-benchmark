-- CTE containing all customer keys with store purchases in specific time range
WITH customer_sales_from_stores AS (
    SELECT ss_customer_sk AS customer_sk
    FROM store_sales_partitioned ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
		AND d.d_moy BETWEEN 3 AND 6
),
-- CTE containing all customer keys with either web or catalog purchases in specific time range
customer_sales_from_web_catalog AS(
    SELECT ws_bill_customer_sk AS customer_sk
    FROM web_sales_partitioned ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
		AND d.d_moy BETWEEN 3 AND 6
    UNION ALL
    SELECT cs_ship_customer_sk AS customer_sk
    FROM catalog_sales_partitioned cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
		AND d.d_moy BETWEEN 3 AND 6
)
-- Main query filtering results using ctes
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(*) AS cnt1,
    cd.cd_purchase_estimate,
    COUNT(*) AS cnt2,
    cd.cd_credit_rating,
    COUNT(*) AS cnt3,
    cd.cd_dep_count,
    COUNT(*) AS cnt4,
    cd.cd_dep_employed_count,
    COUNT(*) AS cnt5,
    cd.cd_dep_college_count,
    COUNT(*) AS cnt6
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE ca.ca_county IN ('Clinton County', 'Platte County','Franklin County',
						'Louisa County', 'Harmon County'
)
	AND EXISTS (
      SELECT 1 
      FROM customer_sales_from_stores st 
      WHERE st.customer_sk = c.c_customer_sk
	)
	AND EXISTS (
	  SELECT 1 
      FROM customer_sales_from_web_catalog wc 
      WHERE wc.customer_sk = c.c_customer_sk
	)
GROUP BY 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    cd.cd_credit_rating,
    cd.cd_dep_count,
    cd.cd_dep_employed_count,
    cd.cd_dep_college_count
ORDER BY 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    cd.cd_credit_rating,
    cd.cd_dep_count,
    cd.cd_dep_employed_count,
    cd.cd_dep_college_count
LIMIT 100;