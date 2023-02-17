/*1. Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.*/
select distinct market as Markets_List from dim_customer
where region = 'APAC' and customer= 'Atliq Exclusive';

/*2. What is the percentage of unique product increase in 2021 vs. 2020?*/
with cte1 as (
select count(distinct p.product_code) as unique_product_count_2021 from dim_product p
join fact_sales_monthly f
on p.product_code=f.product_code
where f.fiscal_year=2021
),
cte2 as (
select count(distinct p.product_code) as unique_product_count_2020 from dim_product p
join fact_sales_monthly f
on p.product_code=f.product_code
where f.fiscal_year=2020
)
select unique_product_count_2021,unique_product_count_2020,
round(((unique_product_count_2021-unique_product_count_2020)/unique_product_count_2020)*100,2) as percentage_chg
from cte1,cte2;

/*3. Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts.*/
select p.segment,count(distinct p.product_code) as unique_product_count from dim_product p
join fact_sales_monthly f
on p.product_code=f.product_code
group by p.segment
order by unique_product_count desc;

/*4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020?*/
with y2020 as
(select segment, count(distinct(p.product_code)) as unique_product_2020
from dim_product p
join fact_sales_monthly f on f.product_code=p.product_code
where fiscal_year=2020
group by segment),
y2021 as
(select segment,count(distinct(p.product_code)) as unique_product_2021
from dim_product p
join fact_sales_monthly f on f.product_code=p.product_code
where fiscal_year=2021
group by segment)
select y2020.segment, unique_product_2020, unique_product_2021,
(unique_product_2021-unique_product_2020) as Diff from y2020
join y2021 on y2020.segment=y2021.segment
order by diff desc;

/*5. Get the products that have the highest and lowest manufacturing costs.*/
with cte1 as(
select m.product_code,p.product,m.manufacturing_cost,
rank() over(order by manufacturing_cost) as rnk
from fact_manufacturing_cost m
join dim_product p
on m.product_code=p.product_code
)

select product_code,product,manufacturing_cost from cte1
where rnk=1 or rnk=(select count(rnk) from cte1);

/*6. Generate a report which contains the top 5 customers who received an     0.23361627
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market.*/
select m.customer_code,d.customer,round((avg(pre_invoice_discount_pct)*100)) as average_discount_percentage from fact_pre_invoice_deductions m
join dim_customer d
on m.customer_code=d.customer_code
where m.fiscal_year=2021 and d.market='India'
group by m.customer_code,d.customer
order by average_discount_percentage desc
limit 5;

/*7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month.This analysis helps to get an idea of low and
high-performing months and take strategic decisions.*/
select extract(month from m.date) as Month,m.fiscal_year as Year,round(sum(sold_quantity*gross_price),0) as Gross_sales_Amount from dim_customer d
join fact_sales_monthly m
on d.customer_code=m.customer_code
join fact_gross_price g
on m.product_code=g.product_code
where d.customer='Atliq Exclusive'
group by Month,Year
order by Year,Month;

/*8. In which quarter of 2020, got the maximum total_sold_quantity?*/
select e.quarters,sum(e.sold_quantity) as total_sold_quantity from
(select *,
case when month(date) in ( 09,10,11) then 'Q1'
	 when month(date) in (12,1,2) then 'Q2'
     when month(date) in (3,4,5) then 'Q3'
     else 'Q4'
end as quarters
from fact_sales_monthly) as e
where fiscal_year=2020
group by e.quarters
order by total_sold_quantity desc;

/*9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution?*/
with temp as (
select channel,(sum(sold_quantity*gross_price))/1000000 as gross_sales_mln
from fact_gross_price f
join fact_sales_monthly d
on f.product_code=d.product_code
join dim_customer c
on d.customer_code=c.customer_code
where f.fiscal_year=2021
group by channel
order by gross_sales_mln desc
)
select *, round(100.0*gross_sales_mln/ (select sum(gross_sales_mln) from temp),2) as
percentage from temp
group by 1, 2, 3;

/*10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021?
division
product_code
product
total_sold_quantity
rank_order*/
select * from
(select p.division,s.product_code,p.product,sum(s.sold_quantity) as total_sold_quantity,
rank() over(partition by p.division order by sum(s.sold_quantity) desc) as rank_order from fact_sales_monthly s
join dim_product p
on s.product_code=p.product_code
where s.fiscal_year=2021
group by p.division,s.product_code,p.product)e
where rank_order<=3;