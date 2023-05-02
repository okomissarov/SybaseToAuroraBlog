
-- Unsupported Commands in Babelfish
-- Expected result: Error: 'BACKUP' is not supported in this version of SQL Server. (Line 4)
PRINT 'Unsupported Command Test: BACKUP'
GO
BACKUP DATABASE pubs3 TO DISK = 'C:\pubs3.bak'
GO


-- Unsupported Syntax in Babelfish
-- Expected result: Error: Incorrect syntax near 'UNPIVOT'. (Line 4)
PRINT 'Unsupported Syntax Test: UNPIVOT'
GO
SELECT *
FROM (
    SELECT empid, firstname, lastname, city, state
    FROM employees
) AS emp
UNPIVOT (contact FOR contact_type IN (firstname, lastname)) AS unpvt
GO
PRINT 'Test 6: Testing MERGE statement'

MERGE INTO dbo.authors AS target
USING (
    VALUES 
    ('172-32-1176', 'NewFirst1', 'NewLast1', 'updated', 'new'),
    ('899-46-2035', 'NewFirst2', 'NewLast2', 'updated', 'new')
) AS source (au_id, au_fname, au_lname, phone, address)
ON (target.au_id = source.au_id)
WHEN MATCHED THEN 
    UPDATE SET 
        target.au_fname = source.au_fname,
        target.au_lname = source.au_lname,
        target.phone = source.phone,
        target.address = source.address,
        target.contract = 'new contract'
WHEN NOT MATCHED THEN 
    INSERT (au_id, au_fname, au_lname, phone, address, contract)
    VALUES (source.au_id, source.au_fname, source.au_lname, source.phone, source.address, 'new contract');

SELECT * FROM dbo.authors WHERE au_id IN ('172-32-1176', '899-46-2035');
GO

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

PRINT 'Test 9: Testing PIVOT operator'

SELECT * 
FROM (
    SELECT 
        title, 
        price, 
        type 
    FROM dbo.titles
) AS t 
PIVOT (
    AVG(price) 
    FOR type IN ([popular_comp], [psychology], [mod_cook], [business])
) AS p;
GO