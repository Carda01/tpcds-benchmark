-- Creating CTE using partitioned table store_sales and filter the year to take advantage
-- of partitions and to avoid grouping by for every year
WITH ss AS
 (SELECT ca_county,
 		d_qoy,
		d_year,
		SUM(ss_ext_sales_price) as store_sales
 FROM store_sales_partitioned
 JOIN date_dim ON ss_sold_date_sk = d_date_sk AND d_year=1999
 JOIN customer_address ON ss_addr_sk=ca_address_sk
 GROUP BY ca_county,
 	d_qoy,
	d_year
),
-- Creating CTE using partitioned table web_sales and filter the year to take advantage of
-- partitions and to avoid grouping by for every year
ws AS
 (SELECT ca_county,
 		d_qoy,
		d_year,
		SUM(ws_ext_sales_price) AS web_sales
 FROM web_sales_partitioned
 JOIN date_dim ON ws_sold_date_sk = d_date_sk AND d_year=1999
 JOIN customer_address ON ws_bill_addr_sk=ca_address_sk
 GROUP BY ca_county,d_qoy, d_year)
 -- Executing main query using Explicit Joins
SELECT ss1.ca_county,
     	ss1.d_year,
        ws2.web_sales/ws1.web_sales web_q1_q2_increase,
        ss2.store_sales/ss1.store_sales store_q1_q2_increase,
        ws3.web_sales/ws2.web_sales web_q2_q3_increase,
        ss3.store_sales/ss2.store_sales store_q2_q3_increase
FROM ss ss1
JOIN ss ss2 ON ss1.d_qoy = 1 AND ss1.ca_county = ss2.ca_county AND ss2.d_qoy = 2
JOIN ss ss3 ON ss2.ca_county = ss3.ca_county AND ss3.d_qoy = 3
JOIN ws ws1 ON ss1.ca_county = ws1.ca_county AND ws1.d_qoy = 1
JOIN ws ws2 ON ws1.ca_county = ws2.ca_county AND ws2.d_qoy = 2
JOIN ws ws3 ON ws1.ca_county = ws3.ca_county AND ws3.d_qoy = 3
WHERE (CASE WHEN ws1.web_sales > 0 THEN ws2.web_sales/ws1.web_sales ELSE NULL END)
       > (CASE WHEN ss1.store_sales > 0 THEN ss2.store_sales/ss1.store_sales ELSE NULL END)
    AND (CASE WHEN ws2.web_sales > 0 THEN ws3.web_sales/ws2.web_sales ELSE NULL END)
       > (CASE WHEN ss2.store_sales > 0 THEN ss3.store_sales/ss2.store_sales ELSE NULL END)
ORDER BY ss1.ca_county;