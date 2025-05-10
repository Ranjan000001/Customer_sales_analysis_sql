CREATE DATABASE `customer_sales` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
-- creat tabels
create table customer_sales.customer_sales_data 
( 
customer_id	varchar(20),
product  varchar(50),
amount	float,
mode_of_payment varchar(40),
category	varchar(20),
feedback	varchar(20),
order_datetime	datetime,
delivery_datetime datetime

)
-- see tabe
select * from  customer_sales_data;
-- see null cells
select *
from customer_sales_data
where 
customer_id is null 
or
product is null
or   
amount is null 
or
mode_of_payment is null
or
category is null
or
feedback is null
or
order_datetime is null 
or
delivery_datetime is null;  
-- no null rows are there
-- count of tabel
select count(*) from customer_sales_data;
-- total data column add with int type
alter table customer_sales_data
add total_date int;
-- addind primery key 
alter table customer_sales_data
add column id int not null auto_increment primary key;
-- update the values of new column
set sql_safe_updates=0;
update customer_sales_data
set total_date = timestampdiff(day, order_datetime,delivery_datetime)
where total_date is null and id is not null;
set sql_safe_updates=1;
-- 1) total sale based on products
select 
product as product,
round(sum(amount), 2) as total_sale
from  customer_sales_data
group by 1;
-- 2) average date for delivery oder with average amount
select 
round(avg(total_date),2) as average_day,
round(avg(amount),2) as avg_total
from customer_sales_data;
-- 3) find the most positive reviews product and most negative review product
select
(select 
product
from customer_sales_data
where feedback = 'Positive'
group by 1
order by count(*) desc
limit 1) as positive_review,            

(select product
from customer_sales_data
where feedback = 'Negative'
group by 1
order by count(*) desc
limit 1) as negative_review;
-- 4) most populare product and category. regularly used mode_od_payment
select 
(select
product
from customer_sales_data
group by 1
order by count(*) desc
limit 1
) as most_product,
(select
category
from customer_sales_data
group by 1
order by count(*) desc
limit 1
) as most_popular_category,
(select
mode_of_payment
from customer_sales_data
group by 1
order by count(*) desc
limit 1
) as most_used_payment;
-- 5) top 5 most used categorey with products and average amount of that product
-- topcategory table contain top 5 category
with topcategory as (
select
category
from customer_sales_data
group by 1
order by count(*) desc
limit 5
),
-- categoryproducts table contain category with there top products with avg amount and product count 
categoryproducts as(
select
t.category,
t.product,
count(*) as product_count,
round(avg(t.amount), 2) as avg_amount,
row_number() over (partition by t.category order by count(*) desc) as rn
from customer_sales_data t
join topcategory tc on t.category = tc.category
group by t.category, t.product
)
-- top 5 category with each category have 5 products , product count and there avg amount
select category, product, product_count, avg_amount
from categoryproducts
where rn <= 5
order by category, product_count desc;

-- 6) bottom 5 least used categorey with products and average amount of that product
-- bottomcategory table contain 5 bottom categorys
with rank_category as (
select 
category, 
count(*) as order_count,
rank() over (order by count(*) asc) as rnk
from customer_sales_data
group by category

),
bottomcategory as (
select
 category
 from rank_category
 where rnk <= 5
),
-- categoryproduct  table contain category with bottom products , product count and avg amount
categoryproducts as (
select
t.category,
t.product,
count(*) as product_count,
row_number() over (partition by t.category order by count(*) desc) as rn,
round(avg(t.amount), 2) as avg_amount
from customer_sales_data t
join bottomcategory bc on t.category = bc.category
group by t.category, t.product
)
-- bottom 5 category with each have 5 product, product_count and avg_amount
select category, product, product_count, avg_amount
from categoryproducts
where rn <= 5
order by category, product_count desc;
-- 7) product with most negative feedback by particular customer_id repatedly

-- new
WITH neg_customer AS (
    SELECT
        customer_id,
        COUNT(*) AS total_neg_count
    FROM customer_sales_data
    WHERE feedback = 'Negative'
    GROUP BY customer_id
),
customer_rank AS (
    SELECT
        customer_id,
        total_neg_count,
        ROW_NUMBER() OVER (ORDER BY total_neg_count DESC, customer_id ASC) AS rn
    FROM neg_customer
),
top_product AS (
    SELECT
        customer_id,
        product,
        COUNT(*) AS product_count
    FROM customer_sales_data
    WHERE feedback = 'Negative'
      AND customer_id = (SELECT customer_id FROM customer_rank WHERE rn = 1)
    GROUP BY customer_id, product
    ORDER BY product_count DESC, product ASC
    LIMIT 1
)
SELECT 
    cr.customer_id,
    tp.product AS most_negative_review, 
    cr.total_neg_count,
    tp.product_count
FROM customer_rank cr
LEFT JOIN top_product tp ON cr.customer_id = tp.customer_id
WHERE cr.rn = 1;



-- 8) product with most positive feedback by particular customer_id repartley
WITH positive_customer AS (
    SELECT
        customer_id,
        COUNT(*) AS total_pos_count
    FROM customer_sales_data
    WHERE feedback = 'Positive'
    GROUP BY customer_id
),
customer_rank AS (
    SELECT
        customer_id,
        total_pos_count,
        ROW_NUMBER() OVER (ORDER BY total_pos_count DESC, customer_id ASC) AS rn
    FROM  positive_customer
),
top_product AS (
    SELECT
        customer_id,
        product,
        COUNT(*) AS product_count
    FROM customer_sales_data
    WHERE feedback = 'Positive'
      AND customer_id = (SELECT customer_id FROM customer_rank WHERE rn = 1)
    GROUP BY customer_id, product
    ORDER BY product_count DESC, product ASC
    LIMIT 1
)
SELECT 
    cr.customer_id,
    tp.product AS most_negative_review, 
    cr.total_pos_count,
    tp.product_count
FROM customer_rank cr
LEFT JOIN top_product tp ON cr.customer_id = tp.customer_id
WHERE cr.rn = 1;

-- 9)most sale based on month and most no. of order 
select 
extract(year from order_datetime) as year,
extract(month from order_datetime) as month,
count(*) as order_count,
round(sum(amount), 2) as total_sale
from customer_sales_data
group by 
year, month
order by 
order_count desc, total_sale desc
limit 1;
-- 10) all detals of customer_id like no. of oders , product perchase and total amount spend
select
customer_id,
category,
round(sum(amount), 2) as total_spend,
count(*) as order_count
from customer_sales_data
where customer_id = 'CUST00277'
group by category
order by 
category desc, total_spend desc, order_count;
-- here if we replace category by product then it show tabel of data on product base