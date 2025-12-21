
select *, 
case
    when list_price<300 then 'Economy'
	when list_price between 300 and 999 then 'standard'
	when list_price between 1000 and 2499 then 'Premium'
	when list_price >2500  then 'Luxury'
	end as category
	from production.products
	order by list_price ;


select *, 
case
    when order_status=1 then 'order recieved'
	when order_status=2 then 'In Preparation'
	when order_status=3 then 'Order Cancelled'
	when order_status=4 then 'Order Delivered'
	end as category
	from sales.orders;

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

select isnull(phone,'no phone number')
from sales.customers;

select coalesce(phone,email,'no contact') as 'prefered contact'
from sales.customers;

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
