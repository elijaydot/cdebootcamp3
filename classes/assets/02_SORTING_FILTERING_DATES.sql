USE parch_and_posey;
GO


--  1. ORDER BY
--  Question: Display orders from the earliest order to the latest order.

SELECT id, account_id, occurred_at, total_amt_usd
FROM dbo.orders
ORDER BY occurred_at ASC;
GO


--  2. ORDER BY DESC
--  Question: Display the most recent orders first.

SELECT id, account_id, occurred_at, total_amt_usd
FROM dbo.orders
ORDER BY occurred_at DESC;
GO


--  3. MULTIPLE SORT COLUMNS
--  Question: Sort orders by account ID ascending and order value descending within each account.

SELECT id, account_id, total_amt_usd
FROM dbo.orders
ORDER BY account_id ASC, total_amt_usd DESC;
GO


--  4. TOP
--  Question: Return the 10 largest orders by total dollar amount.

SELECT TOP 10 id, account_id, total_amt_usd
FROM dbo.orders
ORDER BY total_amt_usd DESC;
GO


--  5. TOP WITH TIES
--  Question: Return the top 10 order values, including ties at the tenth position.

SELECT TOP 10 WITH TIES id, account_id, total_amt_usd
FROM dbo.orders
ORDER BY total_amt_usd DESC;
GO


--  6. YEAR / MONTH / DAY
--  Question: Extract the year, month, and day from each order timestamp.

SELECT id,
       occurred_at,
       YEAR(occurred_at) AS order_year,
       MONTH(occurred_at) AS order_month,
       DAY(occurred_at) AS order_day
FROM dbo.orders;
GO


--  7. DATEPART
--  Question: Count how many orders were placed in each year.

SELECT DATEPART(year, occurred_at) AS order_year,
       COUNT(*) AS order_count
FROM dbo.orders
GROUP BY DATEPART(year, occurred_at)
ORDER BY order_year;
GO


--  8. DATE FILTERING
--  Question: Find all orders placed during 2015.

SELECT id, account_id, occurred_at, total_amt_usd
FROM dbo.orders
WHERE occurred_at >= '2015-01-01'
  AND occurred_at < '2016-01-01'
ORDER BY occurred_at;
GO


--  9. DATEADD
--  Question: Show the date 30 days after each order.

SELECT id,
       occurred_at,
       DATEADD(day, 30, occurred_at) AS thirty_days_later
FROM dbo.orders;
GO


--  10. DATEDIFF
--  Question: Calculate how many days have passed between each order and today.

SELECT id,
       occurred_at,
       DATEDIFF(day, occurred_at, GETDATE()) AS days_since_order
FROM dbo.orders;
GO


--  11. DATEDIFF BETWEEN ORDERS
--  Question: Calculate the number of days from each order to January 1, 2017.

SELECT id,
       occurred_at,
       DATEDIFF(day, occurred_at, '2017-01-01') AS days_to_2017
FROM dbo.orders;
GO


--  12. DATE TRUNCATION CONCEPT
--  Question: Group orders by month and calculate monthly revenue.

SELECT DATEFROMPARTS(YEAR(occurred_at), MONTH(occurred_at), 1) AS order_month,
       SUM(total_amt_usd) AS monthly_revenue
FROM dbo.orders
GROUP BY DATEFROMPARTS(YEAR(occurred_at), MONTH(occurred_at), 1)
ORDER BY order_month;
GO


--  13. DATE TRUNCATION BY YEAR
--  Question: Group orders by year and calculate annual revenue.

SELECT DATEFROMPARTS(YEAR(occurred_at), 1, 1) AS order_year,
       SUM(total_amt_usd) AS annual_revenue
FROM dbo.orders
GROUP BY DATEFROMPARTS(YEAR(occurred_at), 1, 1)
ORDER BY order_year;
GO


--  14. EOMONTH
--  Question: Show the last day of the month in which each order occurred.

SELECT id,
       occurred_at,
       EOMONTH(occurred_at) AS month_end
FROM dbo.orders;
GO
