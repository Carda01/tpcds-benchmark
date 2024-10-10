with store_year_total as (
 select c_customer_id customer_id
       ,c_first_name customer_first_name
       ,c_last_name customer_last_name
       ,c_preferred_cust_flag customer_preferred_cust_flag
       ,c_birth_country customer_birth_country
       ,c_login customer_login
       ,c_email_address customer_email_address
       ,d_year dyear
       ,sum(((ss_ext_list_price-ss_ext_wholesale_cost-ss_ext_discount_amt)+ss_ext_sales_price)/2) year_total
 from customer
     ,store_sales
     ,date_dim
 where c_customer_sk = ss_customer_sk
   and ss_sold_date_sk = d_date_sk
 group by c_customer_id
         ,c_first_name
         ,c_last_name
         ,c_preferred_cust_flag
         ,c_birth_country
         ,c_login
         ,c_email_address
         ,d_year
)

, catalog_year_total as (
 select c_customer_id customer_id
       ,c_first_name customer_first_name
       ,c_last_name customer_last_name
       ,c_preferred_cust_flag customer_preferred_cust_flag
       ,c_birth_country customer_birth_country
       ,c_login customer_login
       ,c_email_address customer_email_address
       ,d_year dyear
       ,sum((((cs_ext_list_price-cs_ext_wholesale_cost-cs_ext_discount_amt)+cs_ext_sales_price)/2) ) year_total
 from customer
     ,catalog_sales
     ,date_dim
 where c_customer_sk = cs_bill_customer_sk
   and cs_sold_date_sk = d_date_sk
 group by c_customer_id
         ,c_first_name
         ,c_last_name
         ,c_preferred_cust_flag
         ,c_birth_country
         ,c_login
         ,c_email_address
         ,d_year
)

, web_year_total as (
 select c_customer_id customer_id
       ,c_first_name customer_first_name
       ,c_last_name customer_last_name
       ,c_preferred_cust_flag customer_preferred_cust_flag
       ,c_birth_country customer_birth_country
       ,c_login customer_login
       ,c_email_address customer_email_address
       ,d_year dyear
       ,sum((((ws_ext_list_price-ws_ext_wholesale_cost-ws_ext_discount_amt)+ws_ext_sales_price)/2) ) year_total
 from customer
     ,web_sales
     ,date_dim
 where c_customer_sk = ws_bill_customer_sk
   and ws_sold_date_sk = d_date_sk
 group by c_customer_id
         ,c_first_name
         ,c_last_name
         ,c_preferred_cust_flag
         ,c_birth_country
         ,c_login
         ,c_email_address
         ,d_year
)

, t_s_firstyear as (
	select customer_id
       ,customer_first_name
       ,customer_last_name
	   ,customer_email_address
       ,year_total
	from store_year_total
	where dyear = 2001
	and year_total  > 0
) 
		
, t_s_secyear as (
	select customer_id
       ,customer_first_name
       ,customer_last_name
	   ,customer_email_address
       ,year_total
	from store_year_total
	where dyear = 2001+1
)

, t_c_firstyear as (
	select customer_id
       ,customer_first_name
       ,customer_last_name
	   ,customer_email_address
       ,year_total
	from catalog_year_total
	where dyear = 2001
	and year_total  > 0
) 
		
, t_c_secyear as (
	select customer_id
       ,customer_first_name
       ,customer_last_name
	   ,customer_email_address
       ,year_total
	from catalog_year_total
	where dyear = 2001+1
)
		
, t_w_firstyear as (
	select customer_id
       ,customer_first_name
       ,customer_last_name
	   ,customer_email_address
       ,year_total
	from web_year_total
	where dyear = 2001
	and year_total  > 0
)
		
, t_w_secyear as (
	select customer_id
       ,customer_first_name
       ,customer_last_name
	   ,customer_email_address
       ,year_total
	from web_year_total
	where dyear = 2001+1
)

select 
	t_s_secyear.customer_id
	,t_s_secyear.customer_first_name
	,t_s_secyear.customer_last_name
	,t_s_secyear.customer_email_address
 from t_s_firstyear
 inner join t_s_secyear
 	on t_s_firstyear.customer_id = t_s_secyear.customer_id
 inner join t_w_firstyear
 	on t_s_firstyear.customer_id = t_w_firstyear.customer_id
 inner join t_w_secyear
 	on t_w_firstyear.customer_id = t_w_secyear.customer_id	
 inner join t_c_firstyear
 	on t_s_firstyear.customer_id = t_c_firstyear.customer_id
 inner join t_c_secyear
 	on t_s_firstyear.customer_id = t_c_secyear.customer_id
where  
	(t_c_secyear.year_total / nullif(t_c_firstyear.year_total, 0)) 
	> 
	(t_s_secyear.year_total / nullif(t_s_firstyear.year_total, 0))
	and
	(t_c_secyear.year_total / nullif(t_c_firstyear.year_total, 0)) 
	> 
	(t_w_secyear.year_total / nullif(t_w_firstyear.year_total, 0))
order by t_s_secyear.customer_id
         ,t_s_secyear.customer_first_name
         ,t_s_secyear.customer_last_name
         ,t_s_secyear.customer_email_address
limit 100;