with average_item_price as (
	select
		i_category as category,
		avg(i_current_price) * 1.2 as avg_item_price
	from item
	group by i_category
)

select  a.ca_state state, count(*) cnt
from customer_address a
inner join customer c
	on  a.ca_address_sk = c.c_current_addr_sk
inner join store_sales s
	on c.c_customer_sk = s.ss_customer_sk
inner join date_dim d
	on s.ss_sold_date_sk = d.d_date_sk
inner join item i
	on s.ss_item_sk = i.i_item_sk
inner join average_item_price aip
	on i.i_category = aip.category
where 
	d.d_year = 1998
 	and d.d_moy = 3
	and i.i_current_price > aip.avg_item_price
group by a.ca_state
having count(*) >= 10
order by cnt, a.ca_state 
limit 100;