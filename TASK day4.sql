USE StoreDB;

--1
select *, 
case
    when list_price<300 then 'Economy'
	when list_price between 300 and 999 then 'standard'
	when list_price between 1000 and 2499 then 'Premium'
	when list_price >2500  then 'Luxury'
	end as category
	from production.products
	order by list_price ;

--2
select *, 
case
    when order_status=1 then 'order recieved'
	when order_status=2 then 'In Preparation'
	when order_status=3 then 'Order Cancelled'
	when order_status=4 then 'Order Delivered'
	end as category
	from sales.orders;

--3
select *
        ,case
             when [orders handeled] =0 then 'new employee'
			 when [orders handeled] between 1 and 10 then 'junior employee'
			 when [orders handeled] between 11 and 25 then 'senior employee'
			 when [orders handeled] >26 then 'expert employee'
			 end as em_Status
from(
select o.staff_id ,isnull(count(o.staff_id),0) as [orders handeled] from sales.orders o inner join sales.staffs s 
on s.staff_id=o.staff_id
group by o.staff_id) t

--4
select isnull(phone,'no phone number')
from sales.customers;

select coalesce(phone,email,'no contact') as 'prefered contact'
from sales.customers;


--5
select product_name,p.product_id,
      case 
	      when s.quantity between 1 and 10 then 'low stock'
		  when s.quantity=0 then 'finished'
		  else 'in stock'
		  end 'stock status'
from   
production.products p inner join production.stocks s
on s.product_id=p.product_id
inner join sales.stores store
on s.store_id=store.store_id
where store.store_id=1

--6
SELECT CONCAT(COALESCE(street,''),' ',COALESCE(city,''),' ',COALESCE(state,''),' ',COALESCE(zip_code,'')) AS Full_address
from sales.customers;

--7


with total_sum as(
select o.order_id,SUM(oi.quantity*oi.list_price*(1-oi.discount)) as total_per_order
from sales.order_items oi inner join sales.orders o
on o.order_id=oi.order_id
group by o.order_id
)
SELECT c.customer_id ,concat(c.first_name,' ',c.last_name) cust_name ,o.order_id,t.total_per_order
from sales.customers c inner join sales.orders o
on c.customer_id=o.customer_id
inner join total_sum t
on o.order_id=t.order_id;

