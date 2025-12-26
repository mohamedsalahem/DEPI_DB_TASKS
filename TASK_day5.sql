USE StoreDB;

--1
DECLARE @customer_id INT = 1;
DECLARE @total_spent DECIMAL(10,2);

SELECT @total_spent = SUM(oi.quantity * oi.list_price * (1 - oi.discount))
FROM sales.orders o
JOIN sales.order_items oi ON o.order_id = oi.order_id
WHERE o.customer_id = @customer_id;

IF @total_spent > 5000
    PRINT 'Customer ' + CAST(@customer_id AS VARCHAR) + ' is a VIP customer';
ELSE
    PRINT 'Customer ' + CAST(@customer_id AS VARCHAR) + ' is a Regular customer';



--2
DECLARE @threshold DECIMAL(10,2) = 1500;
DECLARE @count INT;

SELECT @count = COUNT(*)
FROM production.products
WHERE list_price > @threshold;

PRINT 'Number of products over $' + CAST(@threshold AS VARCHAR) + ': ' + CAST(@count AS VARCHAR);

--3
DECLARE @staff_id INT = 2;
DECLARE @year INT = 2017;
DECLARE @total_sales DECIMAL(10,2);

SELECT @total_sales = SUM(oi.quantity * oi.list_price * (1 - oi.discount))
FROM sales.orders o
JOIN sales.order_items oi ON o.order_id = oi.order_id
WHERE o.staff_id = @staff_id
  AND YEAR(o.order_date) = @year;

PRINT 'Total sales for staff ' + CAST(@staff_id AS VARCHAR) + ' in ' + CAST(@year AS VARCHAR) + ': $' + CAST(@total_sales AS VARCHAR);


--4
SELECT @@SERVERNAME AS ServerName,
       @@VERSION AS SQLServerVersion,
       @@ROWCOUNT AS RowsAffected;


--5
DECLARE @store_id INT = 1;
DECLARE @product_id INT = 1;
DECLARE @quantity INT;

SELECT @quantity = quantity
FROM production.stocks
WHERE store_id = @store_id AND product_id = @product_id;

IF @quantity > 20
    PRINT 'Well stocked';
ELSE IF @quantity BETWEEN 10 AND 20
    PRINT 'Moderate stock';
ELSE
    PRINT 'Low stock - reorder needed';



--6
DECLARE @counter INT = 0;

WHILE EXISTS (SELECT 1 FROM production.stocks WHERE quantity < 5)
BEGIN
    UPDATE TOP (3) production.stocks
    SET quantity = quantity + 10
    OUTPUT INSERTED.store_id, INSERTED.product_id, INSERTED.quantity
    WHERE quantity < 5;

    SET @counter = @counter + 1;
    PRINT CONCAT('Batch ', @counter, ' updated.');
END
PRINT 'Updated product ID ' + CAST(@product_id AS VARCHAR) + ' | Total updated: ' + CAST(@counter AS VARCHAR);

        FETCH NEXT FROM cur_products INTO @product_id;
    END

    CLOSE cur_products;
    DEALLOCATE cur_products;
END



--7
SELECT 
    product_id,
    product_name,
    list_price,
    CASE 
        WHEN list_price < 300 THEN 'Budget'
        WHEN list_price BETWEEN 300 AND 800 THEN 'Mid-Range'
        WHEN list_price BETWEEN 801 AND 2000 THEN 'Premium'
        ELSE 'Luxury'
    END AS price_category
FROM production.products;


--8
DECLARE @customer_id INT = 5;
DECLARE @order_count INT;

IF EXISTS (SELECT 1 FROM sales.customers WHERE customer_id = @customer_id)
BEGIN
    SELECT @order_count = COUNT(*) 
    FROM sales.orders 
    WHERE customer_id = @customer_id;

    PRINT CONCAT('Customer ', @customer_id, ' has ', @order_count, ' orders.');
END
ELSE
    PRINT CONCAT('Customer ', @customer_id, ' does not exist.');



--9
CREATE FUNCTION dbo.CalculateShipping (@order_total DECIMAL(10,2))
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @shipping DECIMAL(10,2);

    IF @order_total > 100
        SET @shipping = 0;
    ELSE IF @order_total BETWEEN 50 AND 99.99
        SET @shipping = 5.99;
    ELSE
        SET @shipping = 12.99;

    RETURN @shipping;
END



--10
CREATE FUNCTION dbo.GetProductsByPriceRange (@min_price DECIMAL(10,2), @max_price DECIMAL(10,2))
RETURNS TABLE
AS
RETURN
(
    SELECT 
        p.product_id,
        p.product_name,
        p.list_price,
        b.brand_name,
        c.category_name
    FROM production.products p
    JOIN production.brands b ON p.brand_id = b.brand_id
    JOIN production.categories c ON p.category_id = c.category_id
    WHERE p.list_price BETWEEN @min_price AND @max_price
);



--11
CREATE FUNCTION dbo.GetCustomerYearlySummary (@customer_id INT)
RETURNS @result TABLE
(
    order_year INT,
    total_orders INT,
    total_spent DECIMAL(10,2),
    avg_order_value DECIMAL(10,2)
)
AS
BEGIN
    INSERT INTO @result
    SELECT 
        YEAR(o.order_date) AS order_year,
        COUNT(o.order_id) AS total_orders,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_spent,
        AVG(oi.quantity * oi.list_price * (1 - oi.discount)) AS avg_order_value
    FROM sales.orders o
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    WHERE o.customer_id = @customer_id
    GROUP BY YEAR(o.order_date);

    RETURN;
END




--12
CREATE FUNCTION dbo.CalculateBulkDiscount (@quantity INT)
RETURNS DECIMAL(5,2)
AS
BEGIN
    DECLARE @discount DECIMAL(5,2);

    IF @quantity BETWEEN 1 AND 2
        SET @discount = 0;
    ELSE IF @quantity BETWEEN 3 AND 5
        SET @discount = 0.05;
    ELSE IF @quantity BETWEEN 6 AND 9
        SET @discount = 0.10;
    ELSE
        SET @discount = 0.15;

    RETURN @discount;
END



--13
CREATE PROCEDURE dbo.sp_GetCustomerOrderHistory
    @customer_id INT,
    @start_date DATE = NULL,
    @end_date DATE = NULL
AS
BEGIN
    SELECT 
        o.order_id,
        o.order_date,
        o.required_date,
        o.shipped_date,
        o.order_status,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS order_total
    FROM sales.orders o
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    WHERE o.customer_id = @customer_id
      AND (@start_date IS NULL OR o.order_date >= @start_date)
      AND (@end_date IS NULL OR o.order_date <= @end_date)
    GROUP BY o.order_id, o.order_date, o.required_date, o.shipped_date, o.order_status
    ORDER BY o.order_date;
END




--14
CREATE PROCEDURE dbo.sp_RestockProduct
    @store_id INT,
    @product_id INT,
    @restock_qty INT,
    @old_qty INT OUTPUT,
    @new_qty INT OUTPUT,
    @success BIT OUTPUT
AS
BEGIN
    SELECT @old_qty = quantity
    FROM production.stocks
    WHERE store_id = @store_id AND product_id = @product_id;

    IF @old_qty IS NULL
    BEGIN
        SET @success = 0;
        RETURN;
    END

    UPDATE production.stocks
    SET quantity = quantity + @restock_qty
    WHERE store_id = @store_id AND product_id = @product_id;

    SELECT @new_qty = quantity
    FROM production.stocks
    WHERE store_id = @store_id AND product_id = @product_id;

    SET @success = 1;
END




--15
CREATE PROCEDURE dbo.sp_ProcessNewOrder
    @customer_id INT,
    @product_id INT,
    @quantity INT,
    @store_id INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @staff_id INT;
        SELECT TOP 1 @staff_id = staff_id 
        FROM sales.staffs 
        WHERE store_id = @store_id AND active = 1
        ORDER BY staff_id;

        INSERT INTO sales.orders (customer_id, order_status, order_date, required_date, store_id, staff_id)
        VALUES (@customer_id, 1, GETDATE(), DATEADD(DAY, 7, GETDATE()), @store_id, @staff_id);

        DECLARE @order_id INT = SCOPE_IDENTITY();

        DECLARE @unit_price DECIMAL(10,2);
        SELECT @unit_price = list_price FROM production.products WHERE product_id = @product_id;

        INSERT INTO sales.order_items (order_id, item_id, product_id, quantity, list_price)
        VALUES (@order_id, 1, @product_id, @quantity, @unit_price);

        UPDATE production.stocks
        SET quantity = quantity - @quantity
        WHERE store_id = @store_id AND product_id = @product_id;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END



--16
CREATE PROCEDURE dbo.sp_SearchProducts
    @product_name VARCHAR(255) = NULL,
    @category_id INT = NULL,
    @min_price DECIMAL(10,2) = NULL,
    @max_price DECIMAL(10,2) = NULL,
    @sort_column NVARCHAR(50) = 'product_name'
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX) = '
        SELECT p.product_id, p.product_name, p.list_price, b.brand_name, c.category_name
        FROM production.products p
        JOIN production.brands b ON p.brand_id = b.brand_id
        JOIN production.categories c ON p.category_id = c.category_id
        WHERE 1=1 ';

    IF @product_name IS NOT NULL
        SET @sql += ' AND p.product_name LIKE ''%' + @product_name + '%''';

    IF @category_id IS NOT NULL
        SET @sql += ' AND p.category_id = ' + CAST(@category_id AS NVARCHAR);

    IF @min_price IS NOT NULL
        SET @sql += ' AND p.list_price >= ' + CAST(@min_price AS NVARCHAR);

    IF @max_price IS NOT NULL
        SET @sql += ' AND p.list_price <= ' + CAST(@max_price AS NVARCHAR);

    SET @sql += ' ORDER BY ' + @sort_column;

    EXEC sp_executesql @sql;
END



--17
DECLARE @start_date DATE = '2025-10-01';
DECLARE @end_date DATE = '2025-12-31';
DECLARE @bonus_rate DECIMAL(5,2);

SELECT s.staff_id, s.first_name, s.last_name,
       SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_sales,
       CASE 
           WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) >= 20000 THEN 0.10
           WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) >= 10000 THEN 0.05
           ELSE 0.02
       END AS bonus_rate,
       SUM(oi.quantity * oi.list_price * (1 - oi.discount)) *
       CASE 
           WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) >= 20000 THEN 0.10
           WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) >= 10000 THEN 0.05
           ELSE 0.02
       END AS bonus_amount
FROM sales.staffs s
JOIN sales.orders o ON s.staff_id = o.staff_id
JOIN sales.order_items oi ON o.order_id = oi.order_id
WHERE o.order_date BETWEEN @start_date AND @end_date
GROUP BY s.staff_id, s.first_name, s.last_name;



--18
UPDATE production.stocks
SET quantity = quantity +
    CASE 
        WHEN quantity < 5 THEN 20
        WHEN quantity BETWEEN 5 AND 10 THEN 10
        ELSE 0
    END
OUTPUT inserted.store_id, inserted.product_id, deleted.quantity AS old_quantity, inserted.quantity AS new_quantity;



--19
SELECT c.customer_id, c.first_name, c.last_name,
       ISNULL(SUM(oi.quantity * oi.list_price * (1 - oi.discount)),0) AS total_spent,
       CASE 
           WHEN ISNULL(SUM(oi.quantity * oi.list_price * (1 - oi.discount)),0) >= 5000 THEN 'Gold'
           WHEN ISNULL(SUM(oi.quantity * oi.list_price * (1 - oi.discount)),0) >= 2000 THEN 'Silver'
           ELSE 'Regular'
       END AS loyalty_tier
FROM sales.customers c
LEFT JOIN sales.orders o ON c.customer_id = o.customer_id
LEFT JOIN sales.order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.first_name, c.last_name;


--20
CREATE PROCEDURE dbo.sp_DiscontinueProduct
    @product_id INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM sales.order_items WHERE product_id = @product_id)
    BEGIN
        PRINT 'Product has pending orders, cannot discontinue immediately.';
    END
    ELSE
    BEGIN
        DELETE FROM production.stocks WHERE product_id = @product_id;
        DELETE FROM production.products WHERE product_id = @product_id;
        PRINT 'Product discontinued and inventory cleared.';
    END
END


