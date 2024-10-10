-- create index

create index if not exists idx_cs_cus_sk 
on public.catalog_sales 
using hash (cs_bill_customer_sk);

create index if not exists idx_cs_sold_date_sk 
on public.catalog_sales 
using hash (cs_sold_date_sk);

create index if not exists idx_cust_cust_id 
on public.customer 
using btree (c_customer_id);

create index if not exists idx_date_dyear 
on public.date_dim 
using btree (d_year);

create index if not exists idx_ss_cus_sk 
on public.store_sales 
using hash (ss_customer_sk);

create index if not exists idx_ss_sold_date_sk 
on public.store_sales 
using hash (ss_sold_date_sk);

create index if not exists idx_ws_cus_sk 
on public.web_sales 
using hash (ws_bill_customer_sk);

create index if not exists idx_ws_sold_date_sk 
on public.web_sales 
using hash (ws_sold_date_sk);