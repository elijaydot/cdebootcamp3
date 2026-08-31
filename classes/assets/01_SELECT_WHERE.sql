USE parch_and_posey;
GO


--  1. SELECT
--  Question: Return the date, account ID, and channel for web events.

SELECT occurred_at, account_id, channel
FROM dbo.web_events;
GO


--  2. SELECT SPECIFIC COLUMNS
--  Question: Display the account name, website, and primary point of contact for each account.

SELECT name, website, primary_poc
FROM dbo.accounts;
GO


--  3. DISTINCT
--  Question: What are the different channels used in web events?

SELECT DISTINCT channel
FROM dbo.web_events;
GO


--  4. COLUMN ALIASES
--  Question: Display the account ID, company name, and primary contact using clearer column names.

SELECT id AS account_id, name AS company_name, primary_poc AS primary_contact
FROM dbo.accounts;
GO


--  5. WHERE
--  Question: Find the company, website, and primary contact for Exxon Mobil.

SELECT name, website, primary_poc
FROM dbo.accounts
WHERE name = 'Exxon Mobil';
GO


--  6. COMPARISON OPERATORS
--  Question: Find orders where the total dollar amount is at least $1,000.

SELECT id, account_id, total_amt_usd
FROM dbo.orders
WHERE total_amt_usd >= 1000;
GO


--  7. AND / OR / NOT
--  Question: Find orders where standard quantity is greater than 1,000 and either gloss or poster quantity is zero.

SELECT id, account_id, standard_qty, gloss_qty, poster_qty
FROM dbo.orders
WHERE standard_qty > 1000
  AND (gloss_qty = 0 OR poster_qty = 0);
GO


--  8. IN
--  Question: Find the account name, primary contact, and sales rep ID for Walmart, Target, and Nordstrom.

SELECT name, primary_poc, sales_rep_id
FROM dbo.accounts
WHERE name IN ('Walmart', 'Target', 'Nordstrom');
GO


--  9. NOT IN
--  Question: Find accounts other than Walmart, Target, and Nordstrom.

SELECT name, primary_poc, sales_rep_id
FROM dbo.accounts
WHERE name NOT IN ('Walmart', 'Target', 'Nordstrom');
GO


--  10. BETWEEN
--  Question: Find orders where gloss quantity is between 24 and 29, including the endpoints.

SELECT id, occurred_at, gloss_qty
FROM dbo.orders
WHERE gloss_qty BETWEEN 24 AND 29;
GO


--  11. LIKE
--  Question: Find all companies whose names start with the letter C.

SELECT name
FROM dbo.accounts
WHERE name LIKE 'C%';
GO


--  12. LIKE WITH WILDCARDS
--  Question: Find companies whose names contain the word "one" anywhere in the name.

SELECT name
FROM dbo.accounts
WHERE name LIKE '%one%';
GO


--  13. IS NULL
--  Question: Find orders where the total dollar amount is missing.

SELECT id, account_id, total_amt_usd
FROM dbo.orders
WHERE total_amt_usd IS NULL;
GO


--  14. NOT LIKE
--  Question: Find companies whose names do not start with C.

SELECT name
FROM dbo.accounts
WHERE name NOT LIKE 'C%';
GO


--  15. COMBINING FILTERS
--  Question: Find web events from organic or adwords channels that occurred during 2016.

SELECT occurred_at, account_id, channel
FROM dbo.web_events
WHERE channel IN ('organic', 'adwords')
  AND occurred_at >= '2016-01-01'
  AND occurred_at < '2017-01-01'
ORDER BY occurred_at DESC;
GO
