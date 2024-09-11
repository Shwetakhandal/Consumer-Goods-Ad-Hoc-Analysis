use gdb023;
Select * from dim_customer;
select * from fact_sales_monthly;
select * from fact_gross_price;
#Request1.:Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
Select distinct market 
from dim_customer
where customer = 'Atliq Exclusive'
and region = 'APAC';

#Request2. What is the percentage of unique product increase in 2021 vs. 2020? 
#The final output contains these fields,unique_products_2020,unique_products_2021,percentage_chg

with t1 as 
(Select count(distinct product_code) as unique_product_2020 
from fact_sales_monthly 
where fiscal_year = 2020),
t2 as 
(Select count(distinct product_code) as unique_product_2021 
from fact_sales_monthly 
where fiscal_year = 2021)
Select t1.unique_product_2020, 
       t2.unique_product_2021, 
       round(((t2.unique_product_2021 - t1.unique_product_2020)/ t1.unique_product_2020)*100,2) as percentage_chg
       from t1,t2;

#Request3: Provide a report with all the unique product counts for each segment and sort them in descending order of 
#product counts. The final output contains 2 fields, segment,product_count
Select segment, 
       count(distinct product_code) as product_count 
from dim_product
group by segment
order by product_count desc;

#Request4-Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
#The final output contains these fields,segment,product_count_2020,product_count_2021,difference

with t1 as 
(Select dp.segment,
		dp.product_code,
		fgp.fiscal_year 
		from dim_product dp
        join fact_gross_price fgp on dp.product_code = fgp.product_code),
t2 as 
(Select segment, 
        count(distinct product_code) as product_count_2020 
        from t1
        where fiscal_year = 2020
        group by segment),
t3 as 
(Select segment, 
        count(distinct product_code) as product_count_2021 
        from t1
		where fiscal_year = 2021
        group by segment)
Select t2.segment,
		t2.product_count_2020,
		t3.product_count_2021,
		(t3.product_count_2021-t2.product_count_2020) as difference
from t2
join t3 on t2.segment = t3.segment
group by segment;

#Request5: Get the products that have the highest and lowest manufacturing costs.
#The final output should contain these fields,product_code,product,manufacturing_cost.

Select dp.product_code, 
	   dp.product, 
	   fmc.manufacturing_cost 
from dim_product dp
join fact_manufacturing_cost fmc on dp.product_code = fmc.product_code 
where manufacturing_cost in 
			(Select max(manufacturing_cost) from fact_manufacturing_cost
			union
			Select min(manufacturing_cost) from fact_manufacturing_cost)
order by manufacturing_cost desc;

#Request6: Generate a report which contains the top 5 customers who received an average 
#high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. 
#The final output contains these fields,customer_code ,customer,average_discount_percentage

Select dp.customer_code,
		dp.customer, 
		round(avg(fp.pre_invoice_discount_pct)*100,2) as average_discount_percentage
from dim_customer dp
join fact_pre_invoice_deductions fp on dp.customer_code = fp.customer_code
where market = 'India' and fiscal_year = 2021
group by customer_code
order by average_discount_percentage desc
limit 5;
#Request7: Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. 
#This analysis helps to get an idea of low and high-performing months and take strategic decisions.
#The final report contains these columns: Month,Year,Gross sales Amount

Select monthname(fsm.date) as month,
       year(fsm.date) as year, 
       sum(fgp.gross_price*fsm.sold_quantity) as Gross_sales_Amount
from fact_sales_monthly fsm
join fact_gross_price as fgp on fsm.product_code = fgp.product_code
join dim_customer dc on fsm.customer_code = dc.customer_code
where customer = 'Atliq Exclusive'
group by month,year
order by year;

#Request8: In which quarter of 2020, got the maximum total_sold_quantity? 
#The final output contains these fields sorted by the total_sold_quantity,Quarter,total_sold_quantity

SELECT 
 case 
	when month(date) in ( 9,10,11) then "Q1"
    when month(date) in (12,1,2) then "Q2"
    when month(date) in (3,4,5) then "Q3"
    when month(date) in (6,7,8) then "Q4"
    end as Quater,
    round(sum(sold_quantity)/1000000,2) as total_sold_quantity_mln
from fact_sales_monthly
where fiscal_year=2020
group by Quater;
#9 Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
#The final output contains these fields,channel,gross_sales_mln,percentage

with t as 
(Select dc.channel,
        round(sum(fcm.sold_quantity*g.gross_price)/1000000,2) as gross_sales_mln
from dim_customer dc
join fact_sales_monthly fcm on dc.customer_code = fcm.customer_code
join  fact_gross_price g on fcm.product_code=g.product_code
where fcm.fiscal_year = 2021
group by channel),
t1 as 
(Select sum(gross_sales_mln) as total_sales from t)
Select t.channel, t.gross_sales_mln,round((t.gross_sales_mln/t1.total_Sales)*100,2) as per from t, t1
group by channel
order by per desc;

#Request10: Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
#The final output contains these fields,division, product_code,product,total_sold_quantity,rank_order

with t as (Select dp.division, dp.product_code, dp.product, sum(fsm.sold_quantity) as total_sold_quantity,
rank() over(partition by division order by sum(sold_quantity) desc) as rank_order
from dim_product dp
join fact_sales_monthly fsm on dp.product_code = fsm.product_code
group by division,product_code)
Select division, product_code, product, total_sold_quantity,rank_order
from t 
where rank_order < 4;
