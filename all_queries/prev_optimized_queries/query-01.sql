with customer_total_return as (
	select sr_customer_sk as ctr_customer_sk,
		   sr_store_sk as ctr_store_sk,
		   sum(sr_return_amt_inc_tax) as ctr_total_return
	from store_returns,
			date_dim
	where sr_returned_date_sk = d_date_sk
		and d_year = 1999
	group by sr_customer_sk,
			 sr_store_sk
)

, average_cust_returns as (
	select
		ctr_store_sk as store_sk,
		avg(ctr_total_return) * 1.2 as ctr_avg_return
	from customer_total_return
	group by ctr_store_sk
)

select
	c_customer_id
from customer_total_return
inner join average_cust_returns
	on ctr_store_sk = store_sk
inner join store
	on ctr_store_sk = s_store_sk
inner join customer
	on ctr_customer_sk = c_customer_sk
where s_state = 'TN'
and ctr_total_return > ctr_avg_return
order by c_customer_id
limit 100;


