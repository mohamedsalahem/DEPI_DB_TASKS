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

--7
SELECT top 15 SUBSTRING(phone,1,3) from sales.customers;

--8مش فاهم

--9
SELECT TOP 10 c.category_name,p.product_name FROM production.products p
inner join production.categories c
on c.category_id=p.category_id;

--10
SELECT TOP 10 concat(c.first_name,' ',c.last_name) as customer_name, o.order_date FROM sales.customers c
inner join sales.orders o
ON c.customer_id=o.customer_id;

--11
SELECT TOP 10 p.product_name,ISNULL(b.brand_name ,'No brand') FROM production.products p
INNER JOIN production.brands b
ON b.brand_id=p.brand_id;

--12
SELECT product_name,list_price FROM production.products
WHERE list_price>(SELECT AVG(list_price) FROM production.products);--error

--13
SELECT CONCAT(c.first_name,' ',c.last_name) as name,c.customer_id 
FROM sales.customers c inner join 
(SELECT o.customer_id FROM sales.orders o) t
ON c.customer_id=t.customer_id ;
