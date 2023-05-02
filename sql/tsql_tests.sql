--Test Name: Test GROUP BY TSQL feature
--Test Scope: pubs3 database

USE pubs3
GO

SELECT stor_id, SUM(qty) AS total_quantity_sold
FROM salesdetail
GROUP BY stor_id
GO

--Test Name: Test HAVING TSQL feature
--Test Scope: pubs3 database

USE pubs3
GO

SELECT stor_id, SUM(qty) AS total_quantity_sold
FROM salesdetail
GROUP BY stor_id
HAVING SUM(qty) > 1000
GO
--Test Name: Test INNER JOIN TSQL feature
--Test Scope: pubs3 database

USE pubs3
GO

SELECT sales.stor_id, stores.stor_name
FROM sales
INNER JOIN stores ON sales.stor_id = stores.stor_id
GO
--Test Name: Test OUTER JOIN TSQL feature
--Test Scope: pubs3 database

USE pubs3
GO

SELECT stores.stor_id, stores.stor_name, sales.stor_id, sales.ord_num
FROM stores
LEFT OUTER JOIN sales ON stores.stor_id = sales.stor_id
GO
--Test Name: Test SUBQUERY TSQL feature
--Test Scope: pubs3 database

USE pubs3
GO

SELECT *
FROM titleauthor
WHERE au_id IN (
   SELECT au_id
   FROM authors
   WHERE state = 'CA'
)
GO
--Test Name: Test EXISTS TSQL feature
--Test Scope: pubs3 database

USE pubs3
GO

SELECT *
FROM sales
WHERE EXISTS (
   SELECT *
   FROM stores
   WHERE stores.stor_id = sales.stor_id
)
GO
--Test Name: Test UNION TSQL feature
--Test Scope: pubs3 database

USE pubs3
GO

SELECT title AS book_title
FROM titles
WHERE price < 10
UNION
SELECT stor_name AS book_title
FROM stores
GO
--Test Name: Test UNION ALL TSQL feature
--Test Scope: pubs3 database

USE pubs3
GO

SELECT title AS book_title
FROM titles
WHERE price < 10
UNION ALL
SELECT stor_name AS book_title
FROM stores
GO
--Test Name: Test LIKE operator TSQL feature
--Test Scope: pubs3 database

USE pubs3
GO

SELECT *
FROM authors
WHERE au_fname LIKE 'A%'
GO
--Test Name: Test ORDER BY TSQL feature
--Test Scope: pubs3 database

USE pubs3
GO

SELECT *
FROM titles
ORDER BY price DESC
GO
--Test Name: Test CAST TSQL feature
--Test Scope: pubs3 database

USE pubs3
GO

SELECT CAST(1000 AS float)/CAST(200 AS float) AS result
GO

PRINT 'Test 7: Testing APPLY operator'

SELECT 
    a.title, 
    b.au_lname, 
    b.au_fname 
FROM dbo.titles AS a 
CROSS APPLY (
    SELECT 
        c.au_lname, 
        c.au_fname 
    FROM dbo.titleauthor AS b 
    JOIN dbo.authors AS c ON b.au_id = c.au_id 
    WHERE b.title_id = a.title_id 
) AS b;
GO
PRINT 'Test 8: Testing ROW_NUMBER() function'

SELECT 
    title, 
    price, 
    ROW_NUMBER() OVER (ORDER BY price DESC) AS 'row_num' 
FROM dbo.titles;
GO

PRINT 'Test 10: Testing STRING_AGG() function'

SELECT 
    stor_id, 
    STRING_AGG(title, ', ') AS title_list 
FROM dbo.salesdetail 
JOIN dbo.titles ON dbo.salesdetail.title_id = dbo.titles.title_id 
GROUP BY stor_id;
GO
-- This test demonstrates the use of GROUP BY and HAVING clauses to aggregate and filter data.

PRINT 'Test 15 - GROUP BY and HAVING'
GO


SELECT
t.type,
AVG(s.qty) AS avg_qty
FROM
salesdetail s
JOIN titles t ON s.title_id = t.title_id
GROUP BY
t.type
HAVING
AVG(s.qty) > 25
ORDER BY
t.type
GO

-- This test demonstrates the use of a Common Table Expression (CTE) to simplify a complex query.

PRINT 'Test 16 - Common Table Expressions (CTE)'
GO

WITH top_authors AS (
SELECT TOP 5
au_id,
SUM(qty * (1 - discount / 100) * price) AS total_sales
FROM
salesdetail sd
JOIN titles t ON sd.title_id = t.title_id
JOIN titleauthor ta ON t.title_id = ta.title_id
GROUP BY
au_id
ORDER BY
total_sales DESC
)
SELECT
au.au_fname,
au.au_lname,
ta.au_ord,
ta.royaltyper,
ta.title_id,
t.title,
ts.total_sales
FROM
top_authors ts
JOIN authors au ON ts.au_id = au.au_id
JOIN titleauthor ta ON ts.au_id = ta.au_id
JOIN titles t ON ta.title_id = t.title_id
ORDER BY
ts.total_sales DESC
GO

-- This test demonstrates the use of Window Functions to calculate running totals.

PRINT 'Test 17 - Window Functions'
GO

SELECT
title,
price,
SUM(price) OVER (ORDER BY price ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM
titles
ORDER BY
price DESC
GO

-- This test demonstrates the use of the OFFSET and FETCH clauses to implement paging.

PRINT 'Test 18 - OFFSET and FETCH clauses'
GO

SELECT
title_id,
title,
price
FROM
titles
ORDER BY
price DESC
OFFSET 10 ROWS
FETCH NEXT 5 ROWS ONLY
GO


-- Test: JSON_VALUE()
-- Description: Verify that the JSON_VALUE function works correctly.

DECLARE @json nvarchar(max) = '{ "name": "John Smith", "age": 30, "isMarried": false, "address": { "city": "New York", "state": "NY" } }'

SELECT 
    JSON_VALUE(@json, '$.name') AS name,
    JSON_VALUE(@json, '$.age') AS age,
    JSON_VALUE(@json, '$.isMarried') AS isMarried,
    JSON_VALUE(@json, '$.address.city') AS city,
    JSON_VALUE(@json, '$.address.state') AS state
GO

-- Test: STRING_AGG
-- Description: Verify that the STRING_AGG function concatenates strings correctly.

SELECT 
    au_id, 
    STRING_AGG(CONCAT(au_lname, ', ', au_fname), ', ') AS author_names
FROM authors
GROUP BY au_id
GO


-- Test Name: CursorTest
-- Scope: Tests that a cursor can be created, fetched and closed.

DECLARE @au_id char(11), @royaltyper int
DECLARE curAuthors CURSOR FOR
    SELECT au_id, royaltyper FROM titleauthor ORDER BY au_id
OPEN curAuthors
FETCH NEXT FROM curAuthors INTO @au_id, @royaltyper
WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Author ID: ' + @au_id + ', Royalty Percentage: ' + CAST(@royaltyper AS varchar(10))
    FETCH NEXT FROM curAuthors INTO @au_id, @royaltyper
END
CLOSE curAuthors
DEALLOCATE curAuthors
GO


-- Test Name: DynamicSQLTest
-- Scope: Tests that dynamic SQL can be executed.

DECLARE @TableName varchar(50) = 'authors'
DECLARE @SQL nvarchar(max) = 'SELECT * FROM ' + @TableName
EXEC sp_executesql @SQL
GO


-- Test Name: TransactionTest
-- Scope: Tests that a transaction can be used to execute multiple statements as an atomic unit.

BEGIN TRANSACTION

INSERT INTO dbo.authors (au_id, au_lname, au_fname)
VALUES ('111-11-1111', 'Smith', 'John')

INSERT INTO dbo.titleauthor (au_id, title_id, au_ord, royaltyper)
VALUES ('111-11-1111', 'BU1032', 1, 50)

IF @@ERROR <> 0
BEGIN
    ROLLBACK TRANSACTION
    PRINT 'Transaction Failed!'
END
ELSE
BEGIN
    COMMIT TRANSACTION
    PRINT 'Transaction Succeeded!'
END
GO


