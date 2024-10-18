with customer_total_return as (
	select 
		cr_returning_customer_sk as ctr_customer_sk ,
		ca_state as ctr_state,
		sum(cr_return_amt_inc_tax) as ctr_total_return
	from 
		catalog_returns
		inner join date_dim on cr_returned_date_sk = d_date_sk
		inner join customer_address on cr_returning_addr_sk = ca_address_sk
		where 
			d_year = 1998
		group by 
			cr_returning_customer_sk
			,ca_state)			
			
, cust_average_return as (
	select 
		ctr_state as ctr_state
	,avg(ctr_total_return) * 1.2 as ctr_avg_return
	from customer_total_return ctr1
	group by ctr_state
	)
	
select c_customer_id,
	c_salutation,
	c_first_name,
	c_last_name,
	ca_street_number,
	ca_street_name ,
	ca_street_type,
	ca_suite_number,
	ca_city,
	ca_county,
	ca_state,
	ca_zip,
	ca_country,
	ca_gmt_offset ,
	ca_location_type,
	ctr_total_return
from customer_total_return ctr1
	inner join cust_average_return ctr2 on ctr1.ctr_state = ctr2.ctr_state
	inner join customer on ctr_customer_sk = c_customer_sk
	inner join customer_address on c_current_addr_sk = ca_address_sk
where 
	ctr1.ctr_total_return > ctr2.ctr_avg_return
	and ca_state = 'TX'
order by c_customer_id,
	c_salutation,
	c_first_name,
	c_last_name,
	ca_street_number,
	ca_street_name ,
	ca_street_type,
	ca_suite_number,
	ca_city,
	ca_county,
	ca_state,
	ca_zip,
	ca_country,
	ca_gmt_offset ,
	ca_location_type,
	ctr_total_return
limit 100;