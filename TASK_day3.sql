use StoreDB

--1
SELECT COUNT(product_id) FROM production.products;

--2
SELECT AVG(list_price) avg_price,MIN(list_price) Min_price,MAX(list_price) Max_price
from production.products;

--3
SELECT category_id,COUNT(product_id) num_of_products FROM production.products
group by category_id
order by category_id

--4
SELECT store_id,COUNT(order_id) num_of_orders FROM sales.orders
GROUP BY store_id
ORDER BY num_of_orders;

--5 
SELECT top 10 upper(first_name),LOWER(last_name) FROM sales.customers;

--6
SELECT TOP 10 product_name,LEN(product_name) as name_lenght FROM production.products;