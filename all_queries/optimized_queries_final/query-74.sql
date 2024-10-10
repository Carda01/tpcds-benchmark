with store_year_total as (
 select c_customer_id customer_id
       ,c_first_name customer_first_name
       ,c_last_name customer_last_name
       ,d_year as year
       ,stddev_samp(ss_net_paid) year_total
 from date_dim
     ,store_sales
     ,customer
 where d_date_sk = ss_sold_date_sk
	and ss_customer_sk = c_customer_sk
   and d_year in (2001,2001+1)
 group by c_customer_id
         ,c_first_name
         ,c_last_name
         ,d_year
)
		 
, web_year_total as (
 select c_customer_id customer_id
       ,c_first_name customer_first_name
       ,c_last_name customer_last_name
       ,d_year as year
       ,stddev_samp(ws_net_paid) year_total
 from date_dim
     ,web_sales
     ,customer
 where d_date_sk = ws_sold_date_sk
	and c_customer_sk = ws_bill_customer_sk
   and ws_sold_date_sk = d_date_sk
   and d_year in (2001,2001+1)
 group by c_customer_id
         ,c_first_name
         ,c_last_name
         ,d_year
)
		 
, t_s_firstyear as (
	select customer_id
       ,customer_first_name
       ,customer_last_name
       ,year_total
	from store_year_total
	where year = 2001
	and year_total  > 0
) 
		
, t_s_secyear as (
	select customer_id
       ,customer_first_name
       ,customer_last_name
       ,year_total
	from store_year_total
	where year = 2001+1
)
		
, t_w_firstyear as (
	select customer_id
       ,customer_first_name
       ,customer_last_name
       ,year_total
	from web_year_total
	where year = 2001
	and year_total  > 0
)
		
, t_w_secyear as (
	select customer_id
       ,customer_first_name
       ,customer_last_name
       ,year_total
	from web_year_total
	where year = 2001+1
)
		
select 
t_s_secyear.customer_id, t_s_secyear.customer_first_name, t_s_secyear.customer_last_name
 from t_s_firstyear
 inner join t_s_secyear
 	on t_s_firstyear.customer_id = t_s_secyear.customer_id
 inner join t_w_firstyear
 	on t_s_firstyear.customer_id = t_w_firstyear.customer_id
 inner join t_w_secyear
 	on t_w_firstyear.customer_id = t_w_secyear.customer_id	
where  
	(t_w_secyear.year_total / nullif(t_w_firstyear.year_total,0)) 
	> 
	(t_s_secyear.year_total / nullif(t_s_firstyear.year_total,0))
order by 
	 t_s_secyear.customer_last_name
	,t_s_secyear.customer_first_name
	,t_s_secyear.customer_id
limit 100;


