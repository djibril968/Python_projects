
use Olist_Portfolio_Project
go

----Q1 total revenue and change over the years
create view Total_Rev as 
select round(sum(payment_value),2) as total_rev
from olist_order_payments;


create view total_rev_by_years as
select round(sum(op.payment_value), 2) as total_rev, oo.order_purchase_year, oo.order_purchase_quarter
from olist_order_payments op
join olist_orders oo on oo.order_id = op.order_id
group by oo.order_purchase_year, oo.order_purchase_quarter
order by 2 desc, 1 desc, 3 desc

-------Q2 How many orders were placed on Olist, and how does this vary by month or season?
create view total_orders as
select count(oo.order_id) as total_orders
from olist_orders oo
join olist_order_payments op on oo.order_id = op.order_id;

-----order changes by quarter
create view order_changes_by_season as
select count(oo.order_id) as total_orders, oo.order_purchase_year, oo.order_purchase_quarter, oo.order_purchase_month
from olist_orders oo
join olist_order_payments op on oo.order_id = op.order_id
group by oo.order_purchase_year,oo.order_purchase_quarter, oo.order_purchase_month
order by 2 desc, 1 desc



----Q3 What are the most popular product categories on Olist, and how do their sales volumes compare to each other?

create view popular_catt as
select p.product_category_name, oo.order_purchase_year, count(distinct oi.product_id) as product_count, 
			count(oo.order_id) as sales_volume, round(sum(op.payment_value), 2) as total_rev
from olist_orders oo
join olist_order_payments op on op.order_id = oo.order_id
join olist_order_items oi on oo.order_id = oi.order_id
join olist_products p on oi.product_id = p.product_id
group by p.product_category_name, oo.order_purchase_year
order by 2 desc, 3 desc

------Q4 What is the average order value (AOV) on Olist, and how does this vary by product category or payment method?
create view aov as
with aov_cte (orders, total_rev) 
as
(
	select (oo.order_id) as order_count, round(sum(op.payment_value), 2) as total_rev
	from olist_orders oo
	join olist_order_payments op on op.order_id = oo.order_id
	group by oo.order_id
	
	------order by 2 desc, 3 desc
)
select  round(sum(total_rev)/(select count(orders) from aov_cte), 2) as aov
from aov_cte

create view aov2 as
with aov_cte2 (orders, total_rev, year_) 
as
(
	select (oo.order_id) as order_count, round(sum(op.payment_value), 2) as total_rev, oo.order_purchase_year
	from olist_orders oo
	join olist_order_payments op on op.order_id = oo.order_id
	group by oo.order_id, oo.order_purchase_year
	
	------order by 2 desc, 3 desc
)
select  sum(total_rev)/(select count(orders) from aov_cte2) as aov, year_
from aov_cte2
group by year_


------4b how aov varies by product category
create view aov_product_cat as
	select p.product_category_name,  (round(sum(op.payment_value), 2)/count(oo.order_id)) as aov
	from olist_orders oo
	join olist_order_payments op on op.order_id = oo.order_id
	join olist_order_items oi on oo.order_id = oo.order_id
	join olist_products p on oi.product_id = p.product_id
	group by p.product_category_name
	order by 2 desc

---by payment method----method 2

create view aov_pymt_meth as
select sum(op.payment_value)/count(oc.order_id) as rev, op.payment_type, oo.order_purchase_year
from olist_order_payments op
join olist_orders oc
on op.order_id = oc.order_id
join olist_orders oo on op.order_id = oo.order_id
group by op.payment_type, oo.order_purchase_year  
order by 1 desc


	----Q5 How many sellers are active on Olist, and how does this number change over time?
---total number of sellers on olist
create view seller_no as
select distinct count (seller_id) as total_seller_count
from olist_sellers

select min(order_purchase_timestamp) as Order_start_date, max(order_purchase_timestamp) as order_end_date ---, DATEDIFF(month, min(order_purchase_timestamp), max(order_purchase_timestamp))
from olist_orders

-----we look at active sellers within a the entire duration duration
create view Q5B_sellers as
select  count(distinct s.seller_id) as seller_count, count(distinct oi.product_id) as total_products,  count(distinct op.order_id) as total_orders, 
			min(oo.order_purchase_timestamp) as Order_start_date, max(oo.order_purchase_timestamp) as order_end_date---, oo.order_purchase_year
from olist_sellers s
join olist_order_items oi
on s.seller_id = oi.seller_id
join olist_order_payments op on oi.order_id = op.order_id
join olist_orders oo on oo.order_id = op.order_id
---group by oo.order_purchase_year

create view Q5B_sellers_3m as
-----using cte to get the number of sellers who sold products on olist within at least three months after signup
with seller_cte(seller_count, total_Products, total_orders, order_start_date, order_end_date, date_diff)
as
(
select   s.seller_id, count(distinct oi.product_id) as total_products,  count(distinct op.order_id) as total_orders
				,min(oo.order_purchase_timestamp) as Order_start_date, max(oo.order_purchase_timestamp) as order_end_date
				,datediff(month, min(oo.order_purchase_timestamp), max(oo.order_purchase_timestamp)) as date_diff
from olist_sellers s
join olist_order_items oi
on s.seller_id = oi.seller_id
join olist_order_payments op on oi.order_id = op.order_id
join olist_orders oo on oo.order_id = op.order_id
where oo.order_status <> 'canceled' 
group by s.seller_id
having  datediff(month, min(oo.order_purchase_timestamp), max(oo.order_purchase_timestamp)) <=3
)
select count(seller_Count) as total_sellers  
from seller_cte
---where date_diff <=3

-----getting number of active sellers within a three month duration

-----looking at active sellers for a three month period
create view Q5B1_active_sellers_3m as
with act3_cte(seller_id, total_products_listed, total_orders_completed, Earliest_sales_date, Lastest_sales_date, date_diff)
as
(
select   s.seller_id, count(distinct oi.product_id) as total_products,  count(distinct op.order_id) as total_orders
				,min(oo.order_purchase_timestamp) as Earliest_sales_date, max(oo.order_purchase_timestamp) as Lastest_sales_date
				,datediff(month, min(oo.order_purchase_date), max(oo.order_purchase_date)) as date_diff
from olist_sellers s
join olist_order_items oi
on s.seller_id = oi.seller_id
join olist_order_payments op on oi.order_id = op.order_id
join olist_orders oo on oo.order_id = op.order_id
where oo.order_status <> 'canceled' 
group by s.seller_id
having  min(oo.order_purchase_date) >= '2018-07-01' and  max(oo.order_purchase_date) <= '2018-09-30'
---order by Lastest_sales_date desc
)

select count(seller_id) as Total_active_sellers
from act3_cte


-----looking at active sellers for a six month period
create view Q5B1_active_sellers_6m as
with act6_cte(seller_id, total_products_listed, total_orders_completed, Earliest_sales_date, Lastest_sales_date, date_diff)
as
(
select   s.seller_id, count(distinct oi.product_id) as total_products,  count(distinct op.order_id) as total_orders
				,min(oo.order_purchase_timestamp) as Earliest_sales_date, max(oo.order_purchase_timestamp) as Last_sales_date
				,datediff(month, min(oo.order_purchase_date), max(oo.order_purchase_date)) as date_diff
from olist_sellers s
join olist_order_items oi
on s.seller_id = oi.seller_id
join olist_order_payments op on oi.order_id = op.order_id
join olist_orders oo on oo.order_id = op.order_id
where oo.order_status <> 'canceled' 
group by s.seller_id
having  min(oo.order_purchase_date) >= '2018-04-01' and  max(oo.order_purchase_date) <= '2018-09-30'
---order by Last_sales_date desc
)

select count(seller_id) as Total_active_sellers
from act6_cte


-----looking at active sellers on quarterly basis for each year
create view Q5_active_sellers_quarterly as
with quart_cte(seller_id, total_products_listed, total_orders_completed, Year_, quarter_, Earliest_sales_date, Lastest_sales_date, date_diff)
as
(
select   s.seller_id, count(distinct oi.product_id) as total_products,  count(distinct op.order_id) as total_orders
				,max(oo.order_purchase_year), max(oo.order_purchase_quarter) 
				,min(oo.order_purchase_date) as Earliest_sales_date, max(oo.order_purchase_date) as Last_sales_date
				,datediff(month, min(oo.order_purchase_date), max(oo.order_purchase_date)) as date_diff
from olist_sellers s
join olist_order_items oi
on s.seller_id = oi.seller_id
join olist_order_payments op on oi.order_id = op.order_id
join olist_orders oo on oo.order_id = op.order_id
where oo.order_status <> 'canceled' 
group by s.seller_id
--order by 4
)
select count(seller_id) seller_Count, Year_, Quarter_
from quart_cte
group by Year_ , Quarter_
order by 2 desc

------Q6 What is the distribution of seller ratings on Olist, and how does this impact sales performance?
create view Q6B_sellers_rating as
with ratings_cte(seller_count, total_products, total_product_sold, total_rev_gen, ratings, quarter_, year_)
as
(
select s.seller_id, count( oi.product_id), count(oi.order_id), sum(op.payment_value), avg(cast(orr.review_score as int)), oo.order_purchase_quarter, oo.order_purchase_year
from olist_sellers s
join olist_order_items oi on s.seller_id = oi.seller_id
join olist_order_payments op on op.order_id = oi.order_id
join olist_orders oo on op.order_id = oo.order_id
join Olist_reviews orr on oo.order_id = orr.order_id
where oo.order_status <> 'canceled'
group by s.seller_id, oo.order_purchase_quarter, oo.order_purchase_year
--order by 4 desc
)

select ratings, case when ratings = 5 then 'excellent'
						when ratings = 4 then 'very good'
						when ratings = 3 then 'good'
						when ratings = 2 then 'fair'
						when ratings <=1 then 'poor'
						end as ratings_cat 
					,count(seller_count) as sellers, sum(total_product_sold) as total_products_sold, sum(total_rev_gen) as total_revenue
					,quarter_, year_
from ratings_cte
group by ratings, quarter_, year_
order by ratings desc

-----Q7 repeat customers
create view rep_cus as
select distinct oc.customer_unique_id, count(oo.order_id) as no_of_purchases ----over(partition by oc.customer_unique_id) 
from olist_orders oo
join olist_customers oc on oc.customer_id = oo.customer_id
join olist_order_payments op on op.order_id = oo.order_id
group by oc.customer_unique_id, oo.order_id
having count(oo.order_id) >1
order by 2 desc

----Q7b percentage of sales they represent
create view return_cus_sales_percent as
with repeat_cus(customer_id, orders_count, prices, year_)
as
(
select oc.customer_unique_id, count(oo.order_id) as no_of_purchases, sum(op.payment_value) as prices, oo.order_purchase_year
from olist_orders oo
join olist_customers oc on oc.customer_id = oo.customer_id
join olist_order_payments op on op.order_id = oo.order_id
group by oc.customer_unique_id, oo.order_id, oo.order_purchase_year
having count(oo.order_id) >1

)

select count(customer_id) as return_cus_count, sum(orders_count) as no_of_purchases, sum(prices) as rev_gen 
				, sum(prices)/(select sum(payment_value) from olist_order_payments) *100 as sales_percent, Year_ ----(select sum(payment_value) from olist_order_payments)
from repeat_cus
group by Year_;

-------overall repeat customer syntax
with rep_cuss
as
(
select oc.customer_unique_id, count(oo.order_id) as no_of_purchases, sum(op.payment_value) as tot_rev
from olist_orders oo
join olist_customers oc on oo.customer_id = oc.customer_id
--join olist_order_items oi on oo.order_id = oi.order_id
join olist_order_payments op on oo.order_id = op.order_id
where oo.order_status <> 'canceled'
group by oc.customer_unique_id
having count(oo.order_id) >1
---order by 2 desc
)
select (sum(tot_rev)/(select sum(payment_value) from olist_order_payments)) *100 as percent_rev
from rep_cuss

----Q8 What is the average customer rating for products sold on Olist, and how does this impact sales performance?

create view cus_rating as
select product_category_name, round(avg(cast(orr.review_score as float)), 1) as Product_ratings, sum(op.payment_value) as rev_gen
from olist_customers oc
join olist_orders oo on oc.customer_id = oo.customer_id
join olist_order_items oi on oo.order_id = oi.order_id
join olist_reviews orr on oi.order_id = orr.order_id
join olist_order_payments op on op.order_id = oo.order_id
join olist_products pc on oi.product_id = pc.product_id
where oo.order_status <> 'canceled' and oo.order_approved_at != ' '
group by product_category_name ---, pc.product_category_name
order by 2 desc

create view customer_rating_II as
with prod_rating 
as
(
select product_category_name, round(avg(cast(orr.review_score as float)), 1) as Product_ratings, sum(op.payment_value) as rev_gen,
					(oo.order_purchase_year) as year_
from olist_customers oc
join olist_orders oo on oc.customer_id = oo.customer_id
join olist_order_items oi on oo.order_id = oi.order_id
join olist_reviews orr on oi.order_id = orr.order_id
join olist_order_payments op on op.order_id = oo.order_id
join olist_products pc on oi.product_id = pc.product_id
where oo.order_status <> 'canceled' and oo.order_approved_at != ' '
group by product_category_name , oo.order_purchase_year
---order by 2 desc
)

select avg(product_ratings) as avg_rating, year_ , sum(rev_gen) as rev_gen, product_category_name
from prod_rating
group by year_, product_category_name


drop view customer_rating_II as
with prod_rating 
as
(
select product_category_name, round(avg(cast(orr.review_score as float)), 1) as Product_ratings, sum(op.payment_value) as rev_gen,
					(oo.order_purchase_year) as year_
from olist_customers oc
join olist_orders oo on oc.customer_id = oo.customer_id
join olist_order_items oi on oo.order_id = oi.order_id
join olist_reviews orr on oi.order_id = orr.order_id
join olist_order_payments op on op.order_id = oo.order_id
join olist_products pc on oi.product_id = pc.product_id
where oo.order_status <> 'canceled' and oo.order_approved_at != ' '
group by product_category_name , oo.order_purchase_year
---order by 2 desc
)

select product_ratings, year_ , sum(rev_gen) as rev_gen, product_category_name
from prod_rating
group by product_ratings, year_, product_category_name


------Q9 What is the average order cancellation rate on Olist, and how does this impact seller performance?.
create view canc_rate as
with order_canc(order_status,  order_status_count)
as
(
select distinct order_status, count(order_status) 
from olist_orders
group by order_status
) 
select order_status,(cast(order_status_count as float)/(select sum(order_status_count) from order_canc)) *100 as order_cancellation_rate
from order_canc
where order_status = 'canceled'
----group by order_status, order_status_count

create view canc_by_year as
with order_canc(order_status,  order_status_count, year_)
as
(
select distinct order_status, count(order_status), order_purchase_year 
from olist_orders
group by order_status, order_purchase_year 
) 
select order_status,(cast(order_status_count as float)/(select sum(order_status_count) from order_canc)) *100 as order_cancellation_rate, year_
from order_canc
----where order_status = 'canceled'
group by order_status, year_, order_status_count


------Q10 What are the top-selling products on Olist, and how have their sales trends changed over time?

----overall top 10 selling products
create view top_selling as
select top 10 pp.product_category_name, count(oi.order_id) as total_item_sold, sum(op.payment_value) as total_rev_gen---, (oo.order_purchase_year)
from olist_products pp
join olist_order_items oi on pp.product_id = oi.product_id
join olist_order_payments op on op.order_id = oi.order_id
join olist_orders oo on oo.order_id = oi.order_id
where oo.order_status <> 'canceled'
group by pp.product_category_name
order by 3 desc, 2 desc
 
---part b 
create view top_sellingB as
select  pp.product_category_name, count(oi.order_id) as total_item_sold, sum(op.payment_value) as total_rev_gen, (oo.order_purchase_year)
from olist_products pp
join olist_order_items oi on pp.product_id = oi.product_id
join olist_order_payments op on op.order_id = oi.order_id
join olist_orders oo on oo.order_id = oi.order_id
where oo.order_status <> 'canceled'
group by pp.product_category_name, oo.order_purchase_year 
order by 2 desc, 3 desc
----to see how their sales have changed over time


-----Q11 Which payment methods are most commonly used by Olist customers, and how does this vary by product category or geographic region?

-----most commonly used payment method
create view Q11pymt_meth as
select op.payment_type, count(oo.order_id) as use_count, sum(op.payment_value) as rev_gen
from olist_order_payments op
join olist_orders oo on oo.order_id = op.order_id
where oo.order_status <> 'canceled'
group by op.payment_type
order by 2 desc

----how payment methods vary by product category
create view q11B as
select op.payment_type, count(op.payment_type) as use_count, pp.product_category_name, sum(op.payment_value) as rev_gen
from olist_order_payments op
join olist_orders oo on oo.order_id = op.order_id
join olist_order_items oi on op.order_id = oi.order_id
join olist_products pp on pp.product_id = oi.product_id
where oo.order_status <> 'canceled'
group by op.payment_type, pp.product_category_name
order by 2 desc, 3 desc

----how payment methods vary by geographic region
create view Q11c as
select op.payment_type, count(op.payment_type) as use_count, oc.customer_state, sum(op.payment_value) as rev_gen, oo.order_purchase_year
from olist_order_payments op
join olist_orders oo on oo.order_id = op.order_id
join olist_order_items oi on op.order_id = oi.order_id
join olist_customers oc on oc.customer_id = oo.customer_id
where oo.order_status <> 'canceled'
group by op.payment_type, oc.customer_state, oo.order_purchase_year 
order by 1 asc, 2 desc

create view Q11cc as
select op.payment_type, count(op.payment_type) as use_count, oc.cus_state,  
			sum(op.payment_value) as rev_gen, pp.product_category_name,	oo.order_purchase_year
from olist_order_payments op
join olist_orders oo on oo.order_id = op.order_id
join olist_order_items oi on op.order_id = oi.order_id
join olist_customers oc on oc.customer_id = oo.customer_id
join olist_products pp on pp.product_id = oi.product_id
join olist_geolocation og on og.geolocation_zip_code_prefix = oc.customer_zip_code_prefix
where oo.order_status <> 'canceled' and pp.product_category_name != ' '
group by op.payment_type, oc.cus_state, pp.product_category_name, oo.order_purchase_year
order by 1 asc, 2 desc


------Q12 How do customer reviews and ratings affect sales and product performance on Olist?
create view Q12 as
with sales_perf(product_cat, ratings, sales_num, rev_gen, avg_rev_gen)

as
(

select pp.product_category_name , round(avg(cast(orr.review_score as int)), 1) as avg_ratings, count(oi.order_item_id) as sales_num, sum(op.payment_value) as rev_gen ,avg(op.payment_value)
from olist_reviews orr
join olist_orders oo on orr.order_id = oo.order_id
join olist_order_items oi on oo.order_id = oi.order_id
join olist_products pp on pp.product_id = oi.product_id
join olist_customers oc on oo.customer_id = oc.customer_id
join olist_order_payments op on oo.order_id = op.order_id
where oo.order_status <> 'canceled'
group by pp.product_category_name
---order by 2 desc, 1 asc
)

select product_cat, ratings , cast(sales_num as float) * 100/(select sum(sales_num) from sales_perf) as sales_percent 
						,(rev_gen) * 100/(select sum(rev_gen) from sales_perf) as rev_percent
from sales_perf
group by product_cat, ratings, sales_num, rev_gen
order by 3 desc, 2 desc

create view Q12B as
select avg(cast(orr.review_score as int)) as avg_ratings, count(oo.order_id) as cus_rating_count, count(oi.order_item_id) as order_rating_count ,pp.product_category_name
from olist_reviews orr
join olist_orders oo on orr.order_id = oo.order_id
join olist_order_items oi on oo.order_id = oi.order_id
join olist_products pp on pp.product_id = oi.product_id
group by pp.product_category_name
order by 1 desc

------Q13 Which product categories have the highest profit margins on Olist, and how can the company increase profitability across different categories?
--select sum(op.payment_value) as total_rev, sum(cast(oi.price as float)) as total_price, sum(cast(oi.freight_value as float)) as tot_fv 
	--		,sum(cast(oi.price as float) + cast(oi.freight_value as float))
--from olist_order_items oi
--join olist_order_payments op on oi.order_id = op.order_id

create view Q14 as
with prof_marg(product_cat, total_rev, price, freight_value, total_sales_price, year_)
as
(
select pp.product_category_name, sum(op.payment_value) as total_rev, sum(cast(oi.price as float)) as total_price, sum(cast(oi.freight_value as float)) as tot_fv 
			,sum(cast(oi.price as float) + cast(oi.freight_value as float)) as total_sales_price, oo.order_purchase_year 
		---	,(sum(op.payment_value)-sum(cast(oi.price as float) + cast(oi.freight_value as float)))/sum(op.payment_value) *100
from olist_order_items oi
join olist_order_payments op on oi.order_id = op.order_id
join olist_products pp on pp.product_id = oi.product_id

group by pp.product_category_name
----order by 6 desc
)

select product_cat, sum(total_sales_price) as total_sales_price, total_rev, sum(total_rev) - sum(total_sales_price) as profit, 
			(sum(total_rev) - sum(total_sales_price))/sum(total_rev)*100 as proit_percent
					
from prof_marg
group by product_cat, total_rev
order by 5 desc



create view Q14B as
with prof_marg(product_cat, total_rev, Listed_price, freight_value, Listed_sales_price, year_)
as
(
select pp.product_category_name, sum(op.payment_value) as total_rev, sum(cast(oi.price as float)) as original_price, sum(cast(oi.freight_value as float)) as tot_fv 
			,sum(cast(oi.price as float) + cast(oi.freight_value as float)) as Listed_sales_price, oo.order_purchase_year 
		---	,(sum(op.payment_value)-sum(cast(oi.price as float) + cast(oi.freight_value as float)))/sum(op.payment_value) *100
from olist_order_items oi
join olist_order_payments op on oi.order_id = op.order_id
join olist_products pp on pp.product_id = oi.product_id
join olist_orders oo on oo.order_id = oi.order_id
group by pp.product_category_name, oo.order_purchase_year
----order by 6 desc
)

select product_cat, sum(Listed_sales_price) as total_sales_price, total_rev, sum(total_rev) - sum(Listed_sales_price) as profit, 
			(sum(total_rev) - sum(Listed_sales_price))/sum(total_rev)*100 as proit_percent, year_
					
from prof_marg
group by product_cat, total_rev, year_
order by 1 desc


-----Q15 Geolocation having high customer density. Calculate customer retention rate according to geolocations.
---a. 
-----location with high customer density
create view Q15BB as
select oc.cus_state, count(distinct oc.customer_unique_id) as cus_count, count(oo.order_id) as no_of_purchases, oo.order_purchase_year
from olist_orders oo
join olist_customers oc on oo.customer_id = oc.customer_id
join olist_order_payments op on oo.order_id = op.order_id
group by oc.cus_state, oo.order_purchase_year
order by 2 desc

---b customer retention rate across the states
create view Q15B as
with cus_den as (
select og.geo_state, count(distinct oc.customer_unique_id) as cus_count
from olist_orders oo
join olist_customers oc on oo.customer_id = oc.customer_id
join olist_order_payments op on oo.order_id = op.order_id
join olist_geolocation og on og.geolocation_zip_code_prefix = oc.customer_zip_code_prefix
group by og.geo_state
having count(distinct oc.customer_unique_id) >=10
), rep_cus as (
				select oc.cus_state, count(distinct oc.customer_unique_id) as rc
				from olist_customers oc
				join olist_orders oo on oo.customer_id = oc.customer_id
				join olist_order_payments op on oo.order_id = op.order_id
				where oc.customer_unique_id in 
								(select customer_unique_id
								from(	select oc.customer_unique_id, count(oo.order_id) as purchase_count
										from olist_orders oo
										join olist_customers oc on oo.customer_id = oc.customer_id
										join olist_order_payments op on oo.order_id = op.order_id
										group by oc.customer_unique_id
										having count(oo.order_id) >1)sub)
						group by oc.cus_state),
	tot_cus as (
				select cus_state, count(distinct customer_id) as tot_customer
				from olist_customers
				group by cus_state
				)
	select cd.geo_state, round(cast(rc.rc as float)/cast(tc.tot_customer as float) * 100, 2) as percent_rep
	from cus_den cd
	join tot_cus tc on cd.geo_state  = tc.cus_state
	join rep_cus rc on cd.geo_state = rc.cus_state
	order by 2 desc

