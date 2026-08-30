USE parch_and_posey;
GO


--  1. ALTER TABLE - ADD COLUMN

ALTER TABLE dbo.accounts
ADD customer_type VARCHAR(50);
GO


--  2. ALTER TABLE - ALTER COLUMN

ALTER TABLE dbo.accounts
ALTER COLUMN customer_type VARCHAR(100);
GO


--  3. ALTER TABLE - DROP COLUMN

ALTER TABLE dbo.accounts
DROP COLUMN customer_type;
GO


--  4. INSERT - INSERT MULTIPLE ROWS

BEGIN TRAN;

INSERT INTO dbo.accounts (id, name, website, lat, [long], primary_poc, sales_rep_id) VALUES
(9999, 'Tesla', 'www.tesla.com', 30.2672, -97.7431, 'Daniel Brooks', 321500),
(9998, 'Netflix', 'www.netflix.com', 37.7749, -122.4194, 'Jessica Morgan', 321510),
(9997, 'Adobe', 'www.adobe.com', 37.3382, -121.8863, 'Michael Carter', 321520);

SELECT *
FROM dbo.accounts
WHERE id IN (9999, 9998, 9997);

ROLLBACK;
GO


--  5. INSERT - INSERT MULTIPLE ROWS

BEGIN TRAN;

INSERT INTO dbo.accounts (id, name, website, lat, [long], primary_poc, sales_rep_id) VALUES
(9996, 'Microsoft', 'www.microsoft.com', 47.6740, -122.1215, 'Sarah Williams', 321530),
(9995, 'Nike', 'www.nike.com', 45.5152, -122.6784, 'Christopher Davis', 321540),
(9994, 'Coca-Cola', 'www.coca-cola.com', 33.7490, -84.3880, 'Emily Johnson', 321550);

SELECT *
FROM dbo.accounts
WHERE id IN (9996, 9995, 9994);

ROLLBACK;
GO


--  6. UPDATE - UPDATE ONE ROW

BEGIN TRAN;

UPDATE dbo.accounts
SET website = 'www.walmart-new.com'
WHERE id = 1001;

SELECT *
FROM dbo.accounts
WHERE id = 1001;

ROLLBACK;
GO


--  7. UPDATE - UPDATE MULTIPLE COLUMNS

BEGIN TRAN;

UPDATE dbo.accounts
SET website = 'www.apple-new.com',
    primary_poc = 'Robert Anderson'
WHERE name = 'Apple';

SELECT *
FROM dbo.accounts
WHERE name = 'Apple';

ROLLBACK;
GO


--  8. UPDATE - UPDATE MULTIPLE ROWS

BEGIN TRAN;

UPDATE dbo.accounts
SET primary_poc = 'Updated Contact'
WHERE sales_rep_id = 321500;

SELECT *
FROM dbo.accounts
WHERE sales_rep_id = 321500;

ROLLBACK;
GO


--  9. DELETE - DELETE ONE ROW

BEGIN TRAN;

DELETE FROM dbo.accounts
WHERE name = 'Apple';

SELECT *
FROM dbo.accounts
WHERE name = 'Apple';

ROLLBACK;
GO


--  10. DELETE - DELETE MULTIPLE ROWS

BEGIN TRAN;

DELETE FROM dbo.accounts
WHERE sales_rep_id = 321500;

SELECT *
FROM dbo.accounts
WHERE sales_rep_id = 321500;

ROLLBACK;
GO


--  11. TRANSACTION - COMMIT

BEGIN TRAN;

INSERT INTO dbo.accounts (id, name, website, lat, [long], primary_poc, sales_rep_id) VALUES
(9993, 'Amazon', 'www.amazon.com', 47.6062, -122.3321, 'Lauren Mitchell', 321560),
(9992, 'JPMorgan Chase', 'www.jpmorganchase.com', 40.7128, -74.0060, 'Andrew Thompson', 321570),
(9991, 'McDonald''s', 'www.mcdonalds.com', 41.8781, -87.6298, 'Rachel Wilson', 321580);

SELECT *
FROM dbo.accounts
WHERE id IN (9993, 9992, 9991);

COMMIT;
GO


--  12. CLEAN UP COMMITTED RECORDS

DELETE FROM dbo.accounts
WHERE id IN (9993, 9992, 9991);
GO







-- Other Exassmples:

EXEC sp_rename
    'dbo.accounts.customer_type',
    'account_type',
    'COLUMN';
GO
