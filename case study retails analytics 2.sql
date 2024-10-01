use retails;

select * from product_inventory;
select * from sales_transaction;
select * from customer_profiles;

-- identifying duplicates values and replacing it with unique values

select transactionid,count(*) as duplicates
from sales_transaction
group by transactionid
having duplicates>1;

select *,transactionid,count(*) as duplicates
from sales_transaction
group by transactionid
having count(*)>1;

select * from sales_transaction
where transactionid in (select transactionid from sales_transaction
group by transactionid
having count(*)>1)

create table sales_transaction_noduplicates as
select distinct * from sales_transaction;

drop table sales_transaction;

alter table sales_transaction_noduplicates
rename to sales_transaction;

SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));

select productid,count(*)as dupicates
from product_inventory
group by productid
having count(*)>1;

select customerid,count(*) as duplicates
from customer_profiles
group by customerid
having count(*)>1;


-- identifying price discrepencies from sales and product table and updating the discrepencies to match the value in both
-- the table

select product_inventory.productid,product_inventory.price,sales_transaction.transactionid,sales_transaction.price
from product_inventory inner join sales_transaction on product_inventory.productid=sales_transaction.productid
where product_inventory.price<>sales_transaction.price;

update sales_transaction
join product_inventory on sales_transaction.productid=product_inventory.productid
set sales_transaction.price=product_inventory.price
where sales_transaction.price<>product_inventory.price;

set sql_safe_updates =0

-- identify the null values in the data set and replace them with unknown

select sum(case when productid="" then 1 else 0 end )as null_id,
sum(case when productname="" then 1 else 0 end) as null_productname,
sum(case when category="" then 1 else 0 end )as null_category,
sum(case when stocklevel="" then 1 else 0 end) as null_stocklevel,
sum(case when price ="" then 1 else 0 end) as null_price
from product_inventory;

select * from product_inventory
where stocklevel="";

update product_inventory
set stocklevel=0
where stocklevel="";

desc product_inventory;

select sum(case when transactionid="" then 1 else 0 end) as null_id,
sum(case when customerid="" then 1 else 0 end )as null_customer_id,
sum(case when productid="" then 1 else 0 end) as null_product_id,
sum(case when quantitypurchased="" then 1 else 0 end) as null_quantity,
sum(case when transactiondate="" then 1 else 0 end) as null_transaciondate,
sum(case when price ="" then 1 else 0 end) as null_price
from sales_transaction;

select sum(case when customerid="" then 1 else 0 end) as null_customer_id,
sum(case when age="" then 1 else 0 end) as null_age,
sum(case when gender="" then 1 else 0 end) as null_gender,
sum(case when location="" then 1 else 0 end) as null_location,
sum(case when joindate="" then 1 else 0 end )as null_joindate
from customer_profiles;

update customer_profiles
set location="unknown"
where location="";


-- write sql query to clean date column

select str_to_date(joindate,"%d/%m/%Y")
from customer_profiles;

select * ,cast(joindate as date) as joindateupdated from customer_profiles;

select str_to_date(transactiondate,"%d-%m-%Y")
from sales_transaction

select *,cast(transactiondate as date)from sales_transaction;

-- Write a SQL query to summarize the total sales and quantities sold per product by the company.

select productid,sum(quantitypurchased)as totalunitssold,sum(quantitypurchased*price)as totalsales
from sales_transaction
group by productid
order by totalsales desc;

-- Write a SQL query to count the number of transactions per customer to understand purchase frequency.

select customerid,count(*)as numberoftransactions
from sales_transaction
group by customerid
order by numberoftransactions desc;

-- Write a SQL query to evaluate the performance of the product categories based on the total
-- sales which help us understand the product categories which needs to be promoted in the marketing campaigns.

select product_inventory.category,count(sales_transaction.quantitypurchased) as totalunitssold,
sum(sales_transaction.quantitypurchased*sales_transaction.price)as totalsales
from sales_transaction join product_inventory on sales_transaction.productid=product_inventory.productid
group by product_inventory.category
order by totalsales desc;

-- Write a SQL query to find the top 10 products with the highest total sales revenue from the
-- sales transactions. This will help the company to identify the High sales products which needs 
-- to be focused to increase the revenue of the company.

select productid,sum(quantitypurchased*price)as totalrevenue
from sales_transaction
group by productid
order by totalrevenue desc
limit 10;

-- Write a SQL query to find the ten products with the least amount of units sold from 
-- the sales transactions, provided that at least one unit was sold for those products.

select productid,sum(quantitypurchased)as totalunitssold
from sales_transaction
group by productid
order by totalunitssold asc
limit 10;

-- Write a SQL query to identify the sales trend to understand the revenue pattern of the company.

select str_to_date(transactiondate,"%d-%m-%Y")as datetrans,count(quantitypurchased)as transactioncount,
sum(quantitypurchased)as totalunitssold,sum(quantitypurchased*price)as totalsales
from sales_transaction
group by datetrans
order by datetrans desc;

-- Write a SQL query to understand the month on month growth rate of sales of the
-- company which will help understand the growth trend of the company.

with helper_table as(
select extract(month from str_to_date(transactiondate,"%d-%m-%Y"))  as month,sum(quantitypurchased*price)as total_sales
from sales_transaction
group by month),
helper_table2 as(
select month,total_sales,lag(total_sales) over(order by month)as previousmonthsales
from helper_table
group by month)
select month,total_sales,previousmonthsales,(total_sales-previousmonthsales)/previousmonthsales*100 as mom_growth_percent
from helper_table2
group by month
order by month; 

SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));

-- Write a SQL query that describes the number of transaction along with the total
-- amount spent by each customer which are on the higher side and will help us 
-- understand the customers who are the high frequency purchase customers in the company.

select customerid,sum(quantitypurchased*price)as totalspent,count(*)as nooftransaction
from sales_transaction
group by customerid
having nooftransaction>10 and totalspent>1000
order by totalspent desc

-- Write a SQL query that describes the number of transaction along with the total amount 
-- spent by each customer, which will help us understand the customers who are occasional 
-- customers or have low purchase frequency in the company.

SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));

select customerid,count(*)as numberoftransaction,sum(quantitypurchased*price)as totalamountspent
from sales_transaction
group by customerid
having numberoftransaction<=2
order by numberoftransaction asc , totalamountspent desc;

-- Write a SQL query that describes the total number of purchases made by each customer
-- against each productID to understand the repeat customers in the company.

select customerid,productid,count(quantitypurchased)as timespurchased
from sales_transaction
group by customerid,productid
having timespurchased>1
order by timespurchased desc;

-- Write a SQL query that describes the duration between the first 
-- and the last purchase of the customer in that particular company to understand the loyalty of the customer.

with helper_table as(
select customerid,str_to_date(min(transactiondate),"%d-%m-%Y")as firstpurchase,str_to_date(max(transactiondate),"%d-%m-%Y")as lastpurchase
from sales_transaction
group by customerid)
select customerid,firstpurchase,lastpurchase,datediff(lastpurchase,firstpurchase)as daysbetweenpurchase
from helper_table
group by customerid
having firstpurchase and lastpurchase>0
order by daysbetweenpurchase desc;

-- Write a SQL query that segments customers based on the total quantity of products they 
-- have purchased. Also, count the number of customers in each segment which
-- will help us target a particular segment for marketing.

create table customer_segment as
select case when total_quantity between 1 and 10 then "low"
when total_quantity <=30 then "mid"
else "high value" end as customer_segment,count(*)
from(select customer_profiles.customerid,sum(sales_transaction.quantitypurchased) as total_quantity
from customer_profiles join sales_transaction on customer_profiles.customerid=sales_transaction.customerid
group by customer_profiles.customerid) as c
group by customer_segment
order by customer_segment;

create table customer_segment2 as
select case when total_quantity between 1 and 10 then "low"
when total_quantity <=30 then "mid"
else "high value" end as customer_segment,count(*)
from(select customerid,sum(quantitypurchased) as total_quantity
from sales_transaction
group by customerid) as c
group by customer_segment
order by customer_segment;

select * from customer_segment2;
select * from customer_segment;



-------------------------------------------------------------------------- insights from the case study retail analytics


-- 1 we identified the duplictes values and price discrepencies in sales and product table and identified the nullvalues and 
-- replace them with unknown
-- 2 we analyse the total sales and product sold per product by the company- the heighest sales-9450 and units sold-100  for product id 17
-- 3 we analyse the purchase frequency but counting the no of transaction per customers.this analyses helps us to 
-- understand which customer has the highest no of transactions - customer id 664 has the heighest transaction-14
-- 4 we analyse the performance of the product category , this analysis help us understand which product need to promoted in 
-- marketing campaigns - home and kitchen with highest no of unit sold and total sales with aprox 21lack
-- clothing and beauty needs to be promoted in the marketing campaigns to increase the sales
-- 5 we found out the products with least amount of units sold - product id 142 with 27 units sold 
-- 6 we identified the sales trends to understand the revenue pattern of the company
-- 7 we analysed the mom growth rate of the company - it is mostly downward trend as the month increases sales decreases 
-- 8 we analysed the no of transaction and totalspent by each customers-18 customers with transaction>10 and spent >1000
-- this analysis helps us understand high frequency customers
-- 9 and also analyse the customers with least no of transaction and sales with <2 transaction
-- 10 we analyse the loyalty of the customers by calculating the first an last date of purchase 
-- 11 we segment the customers by total no of orders they place by high med and low-high with 689 customers and low with 77 customers
-- this analysis help us target the particular segment.


