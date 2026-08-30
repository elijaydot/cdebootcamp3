--  1. CREATE DATABASE

IF DB_ID('parch_and_posey') IS NULL
BEGIN
    CREATE DATABASE parch_and_posey;
END
GO


--  2. USE DATABASE

USE parch_and_posey;
GO


--  3. DROP EXISTING TABLES

DROP TABLE IF EXISTS dbo.web_events;
GO

DROP TABLE IF EXISTS dbo.orders;
GO

DROP TABLE IF EXISTS dbo.accounts;
GO

DROP TABLE IF EXISTS dbo.sales_reps;
GO

DROP TABLE IF EXISTS dbo.region;
GO


--  4. CREATE REGION TABLE

CREATE TABLE dbo.region
(
    id   INT NOT NULL,
    name VARCHAR(50) NOT NULL,

    CONSTRAINT PK_region
        PRIMARY KEY (id)
);
GO


--  5. CREATE SALES_REPS TABLE

CREATE TABLE dbo.sales_reps
(
    id        INT NOT NULL,
    name      VARCHAR(100) NOT NULL,
    region_id INT NOT NULL,

    CONSTRAINT PK_sales_reps
        PRIMARY KEY (id),

    CONSTRAINT FK_sales_reps_region
        FOREIGN KEY (region_id)
        REFERENCES dbo.region(id)
);
GO


--  6. CREATE ACCOUNTS TABLE

CREATE TABLE dbo.accounts
(
    id           INT NOT NULL,
    name         VARCHAR(200) NOT NULL,
    website      VARCHAR(500) NOT NULL,
    lat          DECIMAL(12,8) NULL,
    [long]       DECIMAL(12,8) NULL,
    primary_poc  VARCHAR(200) NULL,
    sales_rep_id INT NOT NULL,

    CONSTRAINT PK_accounts
        PRIMARY KEY (id),

    CONSTRAINT FK_accounts_sales_reps
        FOREIGN KEY (sales_rep_id)
        REFERENCES dbo.sales_reps(id)
);
GO


--  7. CREATE ORDERS TABLE

CREATE TABLE dbo.orders
(
    id               INT NOT NULL,
    account_id       INT NOT NULL,
    occurred_at      DATETIMEOFFSET(3) NULL,
    standard_qty     INT NULL,
    gloss_qty        INT NULL,
    poster_qty       INT NULL,
    total            INT NULL,
    standard_amt_usd DECIMAL(18,2) NULL,
    gloss_amt_usd    DECIMAL(18,2) NULL,
    poster_amt_usd   DECIMAL(18,2) NULL,
    total_amt_usd    DECIMAL(18,2) NULL,

    CONSTRAINT PK_orders
        PRIMARY KEY (id),

    CONSTRAINT FK_orders_accounts
        FOREIGN KEY (account_id)
        REFERENCES dbo.accounts(id)
);
GO


--  8. CREATE WEB_EVENTS TABLE

CREATE TABLE dbo.web_events
(
    id          INT NOT NULL,
    account_id  INT NOT NULL,
    occurred_at DATETIMEOFFSET(3) NULL,
    channel     VARCHAR(50) NULL,

    CONSTRAINT PK_web_events
        PRIMARY KEY (id),

    CONSTRAINT FK_web_events_accounts
        FOREIGN KEY (account_id)
        REFERENCES dbo.accounts(id)
);
GO