 create database ecommerce;
use ecommerce;

select * from order_table;
select * from order_details_table;
select * from customer_table;
select * from product_table;

-- find the duplicates from the tables

select order_id,count(*)as duplicates
from order_table
group by order_id
having count(*)>1;

select order_id,count(*)as duplicates
from order_details_table
group by order_id
having count(*)>1;

select customer_id,count(*) as duplicates
from customer_table
group by customer_id
having count(*)>1;

select product_id,count(*)as duplicates
from product_table
group by product_id
having count(*)>1;



-- describe the table
desc order_table;
desc order_details_table;
desc customer_table;
desc product_table;

-- Identify the top 3 cities with the highest number of customers to determine key markets for targeted marketing and logistic optimization.

select location,count(customer_id) as number_of_customers
from customer_table
group by location
order by number_of_customers desc
limit 3;

-- Determine the distribution of customers by the number of orders placed. 
-- This insight will help in segmenting customers into one-time buyers, 
-- occasional shoppers, and regular customers for tailored marketing strategies.

with helper_table as(
select customer_id,count(*) as numberoforders
from order_table
group by customer_id)
select numberoforders,count(*) as customercount
from helper_table
group by numberoforders
order by numberoforders asc;


select numberoforders,count(*) as customercount
from (select count(*) as numberoforders
from order_table
group by customer_id) as c
group by numberoforders
order by numberoforders asc;

SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));

-- Identify products where the average purchase quantity per order is 2 but with a high total revenue, suggesting premium product trends.

select product_id,avg(quantity)as avgquantity,sum(quantity*price_per_unit) as totalrevenue
from order_details_table
group by product_id
having avgquantity=2
order by totalrevenue desc;

-- For each product category, calculate the unique number of customers purchasing from it.
-- This will help understand which categories have wider appeal across the customer base.

select product_table.category as category,count(distinct customer_table.customer_id) as unique_customers
from product_table inner join order_details_table on product_table.product_id=order_details_table.product_id
inner join order_table on order_table.order_id=order_details_table.order_id
inner join customer_table on customer_table.customer_id=order_table.customer_id
group by product_table.category
order by unique_customers desc;

-- Analyze the month-on-month percentage change in total sales to identify growth trends.

with helper_table as(
select date_format(order_date,"%Y-%m")as month,sum(total_amount) as totalsales
from order_table
group by month),
helper_table2 as(
select month,totalsales,lag(totalsales) over(order by month) as previousmonthsales
from helper_table
group by month)
select month,totalsales,round((totalsales-previousmonthsales)/previousmonthsales*100) as percentchange
from helper_table2
group by month;

-- Examine how the average order value changes month-on-month. Insights can guide pricing and promotional strategies to enhance order value.

with helper_table as(
select date_format(order_date,"%Y-%m") as month,avg(total_amount) as avgordervalue
from order_table
group by month),
helper_table2 as(
select month,avgordervalue,lag(avgordervalue) over (order by month) as previousmonthavg
from helper_table
group by month)
select month,avgordervalue,round((avgordervalue-previousmonthavg)) as changeinvalue
from helper_table2
group by month;

-- Based on sales data, identify products with the fastest turnover rates, suggesting high demand and the need for frequent restocking.

select product_id,count(quantity) as salesfrequency
from order_details_table
group by product_id
order by salesfrequency desc
limit 5;

-- List products purchased by less than 40% of the customer base, indicating potential mismatches between inventory and customer interest.

select product_table.product_id ,product_table.name as name,count(distinct order_table.customer_id)as uniquecustomercount
from product_table join order_details_table on product_table.product_id=order_details_table.product_id
join order_table on order_table.order_id=order_details_table.order_id
group by product_table.product_id,product_table.name
having uniquecustomercount<(select 0.4 * count(distinct customer_id) from customer_table)


-- Evaluate the month-on-month growth rate in the customer base to understand the effectiveness of marketing campaigns and market expansion efforts.

with helper_table as(
select customer_id,date_format(min(order_date),"%Y-%m") as firstpurchasemonth
from order_table
group by customer_id)
select firstpurchasemonth,count(distinct customer_id) as totalnewcustomers
from helper_table
group by firstpurchasemonth
order by firstpurchasemonth asc;

select date_format(min(order_date),"%Y-%m") as firstpurchasemonth
from (select count(distinct customer_id)as totalnewcustomers
from order_table
group by customer_id) as xyz
group by firstpurchasemonth
order by firstpurchasemonth asc;

-- Identify the months with the highest sales volume, aiding in planning for stock levels,
-- marketing efforts, and staffing in anticipation of peak demand periods.

select date_format(order_date,"%Y-%m")as month,sum(total_amount)as totalsales
from order_table
group by month
order by totalsales desc
limit 3

--------------------------------------------------------------------------------------

select max(price) from product_table
where price<60000
limit 1;

select max(price) from product_table
where price<(select max(price) from product_table
where price<(select max(price) from product_table
limit 1));

select name,avg(price) from product_table
where price>(select avg(price) from product_table
where product_id <> 2 or product_id <> 3);

select name,avg(price) from product_table
where price>(select avg(price) from product_table
where product_id not in (select product_id from product_table where product_id=2 and product_id=3));   

select name,avg(price) from product_table
where product_id not in (select product_id from product_table where product_id=1 and product_id=2);

select name,avg(price) from product_table
where product_id <>1 or product_id<>2;


select order_details_table.quantity,product_table.product_id
from order_details_table inner join product_table on order_details_table.product_id=product_table.product_id
where order_details_table.quantity<2
group by product_id
limit 1;


----------------------------------------------- what did we achieved from the ecommerce case study

-- 1 we achived the top 3 cities-delhi,chennai and jaipur with the highest no of customers who buys our products,which help us to determine 
-- the key market
-- 2 secondly we determine the distribution of customer by the no of order placed,this insight helps us segmenting customers into one time buyers
-- and regular buyers and from this analysis we know that company experience occacional customer the most and 
-- no of orders increases and count of customers decreases
-- 3 premium product trend, products whose average purchase quantity >2 with highest total revenue-product id 1 and 8 has the heighest total
-- revenue with 1620000 nd 390000
-- 4 we calculated the unique no of customers for each product category,this insight helps us which category have wider appeal to customers,
-- electronics with 79 unique customers-wearable tech with 61 unique customers and photography with 45.and we need to focus on
-- electronic as it is in high demand among customers
-- 5we analyse the mom percent change in total sales-there is no such trend in this however we analyze that feb 2024 sales experience the 
-- largest decline with -75% and in on july 2023 sales experience the heighest with 147%
-- 6 we also analyse the avg order value changes mom- and april has the heighest change in avg order values
-- 7 which products has the heighest turnover rate-product id 7 has the heighest turnover rate and needs frequent restoking
-- 8 products which are purchased by <40% of the customers -and products are smartphone and wireless bud with only 36 and 38 unique customers
-- 9 we analysed the mom growth rate in customer base -it is downward trends which tells us marketing campaign are not much affective
-- 10 we identified the months with the heighest sales volume - sept 2023 has the heighest sales volume 2927000

