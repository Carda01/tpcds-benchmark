-- Use the same CTE but with explicit joins
WITH customer_total_return AS (
    SELECT 
        wr_returning_customer_sk AS ctr_customer_sk,
        ca_state AS ctr_state,
        SUM(wr_return_amt) AS ctr_total_return
    FROM 
        web_returns
    JOIN 
        date_dim ON wr_returned_date_sk = d_date_sk
    JOIN 
        customer_address ON wr_returning_addr_sk = ca_address_sk
    WHERE 
        d_year = 2000
    GROUP BY 
        wr_returning_customer_sk, ca_state
),
-- Create new CTE to avoid executing subquery once for every row
state_avg_return AS (
    SELECT 
        ctr_state,
        AVG(ctr_total_return) * 1.2 AS avg_return_threshold
    FROM 
        customer_total_return
    GROUP BY 
        ctr_state
)
-- Main query using explicit joins and filtering state average return from previous CTE
SELECT 
    c.c_customer_id,
    c.c_salutation,
    c.c_first_name,
    c.c_last_name,
    c.c_preferred_cust_flag,
    c.c_birth_day,
    c.c_birth_month,
    c.c_birth_year,
    c.c_birth_country,
    c.c_login,
    c.c_email_address,
    c.c_last_review_date,
    ctr.ctr_total_return
FROM 
    customer_total_return ctr
JOIN 
    state_avg_return sar ON ctr.ctr_state = sar.ctr_state
JOIN 
    customer c ON ctr.ctr_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ctr.ctr_total_return > sar.avg_return_threshold
    AND ca.ca_state = 'KS'
ORDER BY 
    c.c_customer_id, 
    c.c_salutation, 
    c.c_first_name, 
    c.c_last_name, 
    c.c_preferred_cust_flag,
    c.c_birth_day, 
    c.c_birth_month, 
    c.c_birth_year, 
    c.c_birth_country, 
    c.c_login, 
    c.c_email_address,
    c.c_last_review_date, 
    ctr.ctr_total_return
LIMIT 100;
