###📊Customer Sales Data Analysis with SQL
##📝 Project Overview
#This project involves the creation and analysis of a customer sales database using SQL. The primary objectives are:
- Data Modeling: Designing a relational database to store customer sales information.
- Data Cleaning: Identifying and handling missing or null values.
- Data Analysis: Extracting meaningful insights related to sales performance, customer behavior, and product popularity.
- Advanced SQL Techniques: Utilizing Common Table Expressions (CTEs), window functions, and aggregate functions for complex queries.\
#Table Creation Script:
'''sql
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
'''
#🧹 Data Cleaning
To ensure data integrity, we checked for null values across all columns:
'''sql
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
'''
No null values were found, indicating a clean dataset.
##📈 Data Analysis
