# 📊Customer Sales Data Analysis with SQL

## 📝 Project Overview

This project involves the creation and analysis of a customer sales database using SQL. The primary objectives are:
- **Data Modeling**: Designing a relational database to store customer sales information.
- **Data Cleaning**: Identifying and handling missing or null values.
- **Data Analysis**: Extracting meaningful insights related to sales performance, customer behavior, and product popularity.
- **Advanced SQL Techniques**: Utilizing Common Table Expressions (CTEs), window functions, and aggregate functions for complex queries.\
## Table Creation Script:
```mysql

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
);

```
## 🧹 Data Cleaning
To ensure data integrity, we checked for null values across all columns:
```mysql
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
```
**Result:** No null values were found, indicating a clean dataset.

Adding new column total_data
```mysql
alter table customer_sales_data
add total_date int;
```
Adding primery key
```mysql
alter table customer_sales_data
add column id int not null auto_increment primary key;
```
Uptodate column 
```mysql
set sql_safe_updates=0;
update customer_sales_data
set total_date = timestampdiff(day, order_datetime,delivery_datetime)
where total_date is null and id is not null;
set sql_safe_updates=1;
```
## 📈 Data Analysis
### 1. Total Sales by Product
Calculates the total sales amount for each product:
```mysql
select 
product as product,
round(sum(amount), 2) as total_sale
from  customer_sales_data
group by 1;
```
## 2. Average Delivery Duration and Amount
Determines the average delivery time and average purchase amount:
```mysql
select 
round(avg(total_date),2) as average_day,
round(avg(amount),2) as avg_total
from customer_sales_data;
```
## 3. Products with Most Positive and Negative Reviews

Identifies the products with the highest number of positive and negative feedbacks:

```mysql
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
```
## 4. Most Popular Product, Category, and Payment Mode

Finds the most frequently purchased product, category, and commonly used payment method:

```mysql
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
```
## 5. Top 5 Categories with Their Top 5 Products

Analyzes the top 5 categories and their respective top 5 products based on sales count and average amount:

```mysql
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

```

## 6. Bottom 5 Categories with Their Top 5 Products

Similar to the previous analysis but focuses on the least popular categories:

```mysql

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

select category, product, product_count, avg_amount
from categoryproducts
where rn <= 5
order by category, product_count desc;
```
## 7. Customer with Most Negative Feedback and Their Most Criticized Product

Identifies the customer who gave the most negative feedback and the product they criticized the most:

```mysql
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

```

## 8. Customer with Most Positive Feedback and Their Favorite Product

Identifies the customer who gave the most positive feedback and their most praised product:

```mysql
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
```

## 9. Month with Highest Sales and Order Count

Determines the month with the highest total sales and the highest number of orders:

```mysql
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
```
## 10. Detailed Customer Purchase Analysis

Provides detailed insights into a specific customer's purchasing behavior:

```mysql
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
```
**Note:** Replace 'CUST00277' with the desired customer_id.

## 🛠️ Technologies Used
Database: MySQL

- SQL Concepts:

- Data Definition Language (DDL)

- Data Manipulation Language (DML)

- Aggregate Functions

- Window Functions

- Common Table Expressions (CTEs)

Subqueries

## 📌 Conclusion

This project demonstrates the application of SQL for comprehensive data analysis, from data modeling and cleaning to extracting actionable business insights. The use of advanced SQL techniques like CTEs and 

window functions enables efficient and readable queries, facilitating deeper understanding of customer behavior and sales trends.
