-- 1.  Provide the list of markets in which customer  "Atliq  Exclusive"  operates its 
-- business in the  APAC  region. 

select distinct market from dim_customer
where customer = "Atliq Exclusive" and region = "APAC";

--   What is the percentage of unique product increase in 2021 vs. 2020?

WITH cte AS (SELECT 
	COUNT(DISTINCT product_code) AS count_2020
FROM fact_sales_monthly
WHERE fiscal_year = 2020),
cte1 AS (SELECT 
	COUNT(DISTINCT product_code) AS count_2021
FROM fact_sales_monthly
WHERE fiscal_year = 2021)
SELECT 
	cte.count_2020,
    cte1.count_2021,
ROUND(
	((cte1.count_2021- cte.count_2020)*100/ cte.count_2020),2) 
    AS percentage_chg
FROM cte,cte1;

--  Provide a report with all the unique product counts for each  segment  and 
-- sort them in descending order of product counts. 

select segment,
		count(distinct product_code) as unique_product
from dim_product 
group by segment 
order by unique_product desc ;

-- .  Follow-up: Which segment had the most increase in unique products in 
-- 2021 vs 2020?

WITH cte AS (
	SELECT p.segment,s.fiscal_year,COUNT(DISTINCT s.product_code) AS product_count_20
    FROM fact_sales_monthly s 
    join dim_product p 
    on p.product_code = s.product_code
    WHERE 
		s.fiscal_year=2020
	GROUP BY p.segment,s.fiscal_year),
 cte1 as (SELECT p.segment,s.fiscal_year,COUNT(DISTINCT s.product_code) AS product_count_21
    FROM fact_sales_monthly s 
    join dim_product p 
    on p.product_code = s.product_code
    WHERE 
		s.fiscal_year=2021
	GROUP BY p.segment,s.fiscal_year)
SELECT cte1.segment,
		cte.product_count_20,
        cte1.product_count_21,
        ABS(cte1.product_count_21-cte.product_count_20) AS abs_difference,
        ROUND(((ABS(cte1.product_count_21-cte.product_count_20))*100/ABS( cte.product_count_20)),2)
        AS abs_percentage_chg
	FROM cte join cte1
    on cte.segment = cte1.segment
    ORDER BY abs_difference DESC ;

 
 --  Get the products that have the highest and lowest manufacturing costs. 
 
 select p.product,m.manufacturing_cost
 from dim_product p 
 join fact_manufacturing_cost m 
 on p.product_code = m.product_code
 where m.manufacturing_cost=(select max(m.manufacturing_cost) from  dim_product p 
 join fact_manufacturing_cost m 
 on p.product_code = m.product_code)
 union 
 select p.product,m.manufacturing_cost
 from dim_product p 
 join fact_manufacturing_cost m 
 on p.product_code = m.product_code
 where m.manufacturing_cost=(select min(m.manufacturing_cost) from  dim_product p 
 join fact_manufacturing_cost m 
 on p.product_code = m.product_code);
 
 --  Generate a report which contains the top 5 customers who received an 
-- average high  pre_invoice_discount_pct  for the  fiscal  year 2021  and in the 
-- Indian  market. 

select c.customer,c.customer_code,
round(avg(pre_invoice_discount_pct)*100,2) as avg_pre_invoice 
from dim_customer c 
join fact_pre_invoice_deductions i 
on c.customer_code = i.customer_code
where i.fiscal_year = 2021 and market = "India"
group by c.customer,c.customer_code
order by avg_pre_invoice desc
 limit 5 ;

 --  Get the complete report of the Gross sales amount for the customer  “Atliq 
-- Exclusive”  for each month  .  This analysis helps to  get an idea of low and 
-- high-performing months and take strategic decisions. 

select date_format(s.date,"%Y-%m") as month_name, 
sum(g.gross_price*s.sold_quantity) as total_gross_price
from dim_customer c 
join fact_sales_monthly s
on c.customer_code = s.customer_code
join fact_gross_price g 
on s.product_code = g.product_code and s.fiscal_year = g.fiscal_year
where c.customer = "Atliq Exclusive"
group by date_format(s.date,"%Y-%m")
order by month_name ;

-- In which quarter of 2020, got the maximum total_sold_quantity? 

select 
	case
		when month(date) in (9,10,11) then concat("Q",1)
        when month(date) in (12,1,2) then concat("Q",2)
		when month(date) in (3,4,5) then concat("Q",3)
        else concat("Q",4) 
	end as quarter_num,
sum(sold_quantity) as total_sold_quantity
from fact_sales_monthly
where fiscal_year = 2020
group by quarter_num
order by quarter_num;

--  Which channel helped to bring more gross sales in the fiscal year 2021 
-- and the percentage of contribution? 

with cte as (select c.channel,
round(sum((g.gross_price*s.sold_quantity)/1000000),2) as gross_sales_mln
from dim_customer c 
join fact_sales_monthly s 
on c.customer_code = s.customer_code
join fact_gross_price g 
on g.product_code = s.product_code
where s.fiscal_year = 2021
group by c.channel)
select channel,
		concat(gross_sales_mln,'M') AS gross_sale_mln,
	round((gross_sales_mln/sum(gross_sales_mln) over()) * 100,2) pct_contribution 
from cte
order by concat(gross_sales_mln,'M');

 -- Get the Top 3 products in each division that have a high 
-- total_sold_quantity in the fiscal_year 2021? 

with cte as (select p.division , p.product_code,p.product,
sum(s.sold_quantity) as total_sold_quantity,
dense_rank() over (partition by division order by sum(s.sold_quantity) desc ) as rnk 
from dim_product p 
join fact_sales_monthly s
on p.product_code = s.product_code
where fiscal_year = 2021
group by p.division , p.product,p.product_code)
select division,product_code,product,total_sold_quantity
from cte
where rnk<=3
order by total_sold_quantity desc;




