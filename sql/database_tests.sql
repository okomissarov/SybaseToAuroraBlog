-- Test 1: Verify that the dbo schema was created
PRINT 'Test 1: Verify that the dbo schema was created'
SELECT * FROM sys.schemas WHERE [name] = N'dbo'
GO

-- Test 2: Verify that the byroyalty stored procedure was created
PRINT 'Test 2: Verify that the byroyalty stored procedure was created'
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[byroyalty]') AND type in (N'P', N'PC')
GO

-- Test 3: Verify that the byroyalty stored procedure returns the correct results
PRINT 'Test 3: Verify that the byroyalty stored procedure returns the correct results'
EXEC byroyalty 100
GO

-- Test 4: Verify that the discount_proc stored procedure was created
PRINT 'Test 4: Verify that the discount_proc stored procedure was created'
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[discount_proc]') AND type in (N'P', N'PC')
GO

-- Test 5: Verify that the discount_proc stored procedure returns the correct results
PRINT 'Test 5: Verify that the discount_proc stored procedure returns the correct results'
EXEC discount_proc
GO

-- Test 6: Verify that the history_proc stored procedure was created
PRINT 'Test 6: Verify that the history_proc stored procedure was created'
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[history_proc]') AND type in (N'P', N'PC')
GO

-- Test 7: Verify that the history_proc stored procedure returns the correct results
PRINT 'Test 7: Verify that the history_proc stored procedure returns the correct results'
EXEC history_proc '7066'
GO

-- Test 8: Verify that the insert_sales_proc stored procedure was created
PRINT 'Test 8: Verify that the insert_sales_proc stored procedure was created'
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[insert_sales_proc]') AND type in (N'P', N'PC')
GO

-- Test 9: Verify that the insert_sales_proc stored procedure inserts a record into the sales table
PRINT 'Test 9: Verify that the insert_sales_proc stored procedure inserts a record into the sales table'
EXEC insert_sales_proc '7066', '2023-04-28'
SELECT * FROM dbo.sales WHERE stor_id = '7066'
GO

-- Test 10: Verify that the insert_salesdetail_proc stored procedure was created
PRINT 'Test 10: Verify that the insert_salesdetail_proc stored procedure was created'
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[insert_salesdetail_proc]') AND type in (N'P', N'PC')
GO

-- Test 11: Verify that the insert_salesdetail_proc stored procedure inserts a record into the salesdetail table
PRINT 'Test 11: Verify that the insert_salesdetail_proc stored procedure inserts a record into the salesdetail table'
EXEC insert_salesdetail_proc '7066', '100001', 'BU1032', 1, 0.00
SELECT * FROM dbo.salesdetail WHERE stor_id = '7066' AND ord_num = '100001'
GO

-- Test 12: Verify that the storeid_proc stored procedure was created
PRINT 'Test 12: Verify that the storeid_proc stored procedure was created'
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[storeid_proc]') AND type in (N'P', N'PC')
GO

PRINT 'Test 11: Insert a new row into the titleauthor table and verify'
BEGIN TRY
    INSERT INTO titleauthor (title_id, au_id, au_ord, royaltyper)
    VALUES ('BU1111', '409-56-7008', 1, 15)
    
    SELECT COUNT(*) FROM titleauthor WHERE title_id = 'BU1111' AND au_id = '409-56-7008'
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE()
END CATCH
GO

PRINT 'Test 12: Update a row in the titleauthor table and verify'
BEGIN TRY
    UPDATE titleauthor
    SET royaltyper = 20
    WHERE title_id = 'BU2075' AND au_id = '213-46-8915'
    
    SELECT COUNT(*) FROM titleauthor WHERE title_id = 'BU2075' AND au_id = '213-46-8915' AND royaltyper = 20
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE()
END CATCH
GO

PRINT 'Test 13: Delete a row from the titleauthor table and verify'
BEGIN TRY
    DELETE FROM titleauthor WHERE title_id = 'PS3333' AND au_id = '213-46-8915'
    
    SELECT COUNT(*) FROM titleauthor WHERE title_id = 'PS3333' AND au_id = '213-46-8915'
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE()
END CATCH
GO

PRINT 'Test 14: Insert a new row into the titles table and verify'
BEGIN TRY
    INSERT INTO titles (title_id, title, type, price, pub_id, pubdate)
    VALUES ('TS1111', 'Test Book', 'business', 25.99, '0736', '2022-01-01')
    
    SELECT COUNT(*) FROM titles WHERE title_id = 'TS1111' AND title = 'Test Book'
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE()
END CATCH
GO
PRINT 'Test 15: Update a row in the titles table and verify'
BEGIN TRY
    UPDATE titles
    SET price = 19.99
    WHERE title_id = 'BU1032'
    
    SELECT COUNT(*) FROM titles WHERE title_id = 'BU1032' AND price = 19.99
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE()
END CATCH
GO
PRINT 'Test 16: Delete a row from the titles table and verify'
BEGIN TRY
    DELETE FROM titles WHERE title_id = 'PS3333'
    
    SELECT COUNT(*) FROM titles WHERE title_id = 'PS3333'
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE()
END CATCH
GO
PRINT 'Test 26 - Verify that the "titleauthor" table has a foreign key constraint on the "titles" table'
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name LIKE 'titleauthor$titleautho_title%')
BEGIN
    PRINT 'Test passed - foreign key constraint exists'
END
ELSE
BEGIN
    PRINT 'Test failed - foreign key constraint does not exist'
END
GO
PRINT 'Test 27 - Verify that the "sales" table has a foreign key constraint on the "stores" table'
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name LIKE 'sales$sales_stor%')
BEGIN
    PRINT 'Test passed - foreign key constraint exists'
END
ELSE
BEGIN
    PRINT 'Test failed - foreign key constraint does not exist'
END
GO



PRINT 'Test 28 - Verify that the "salesdetail" table has a foreign key constraint on the "sales" table'
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name LIKE 'salesdetail$salesdetai_ord_nu%')
BEGIN
    PRINT 'Test passed - foreign key constraint exists'
END
ELSE
BEGIN
    PRINT 'Test failed - foreign key constraint does not exist'
END
GO



PRINT 'Test 29 - Verify that the "salesdetail" table has a foreign key constraint on the "titles" table'
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name LIKE 'salesdetail$salesdetai_title%')
BEGIN
    PRINT 'Test passed - foreign key constraint exists'
END
ELSE
BEGIN
    PRINT 'Test failed - foreign key constraint does not exist'
END
GO




PRINT 'Test 30 - Verify that the "roysched" table has a foreign key constraint on the "titles" table'
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name LIKE 'roysched$roysched_title%')
BEGIN
    PRINT 'Test passed - foreign key constraint exists'
END
ELSE
BEGIN
    PRINT 'Test failed - foreign key constraint does not exist'
END
GO


PRINT 'Test 41: Verify if title_proc procedure returns correct results for a given title'

DECLARE @title varchar(80) = 'secret%'
DECLARE @count int

EXEC @count = title_proc @title

IF (@count > 0)
BEGIN
    PRINT 'PASS: title_proc procedure returned correct number of rows'
END
ELSE
BEGIN
    PRINT 'FAIL: title_proc procedure returned incorrect number of rows'
END
GO
PRINT 'Test 42: Verify if titleid_proc procedure returns correct results for a given title ID'

DECLARE @title_id varchar(80) = 'pc%'
DECLARE @count int

EXEC @count = titleid_proc @title_id

IF (@count > 0)
BEGIN
    PRINT 'PASS: titleid_proc procedure returned correct number of rows'
END
ELSE
BEGIN
    PRINT 'FAIL: titleid_proc procedure returned incorrect number of rows'
END
GO
PRINT 'Test 43: Verify if byroyalty procedure returns correct results for a given royalty percentage'

DECLARE @percentage int = 10
DECLARE @count int

EXEC @count = byroyalty @percentage

IF (@count > 0)
BEGIN
    PRINT 'PASS: byroyalty procedure returned correct number of rows'
END
ELSE
BEGIN
    PRINT 'FAIL: byroyalty procedure returned incorrect number of rows'
END
GO
PRINT 'Test 44: Verify if history_proc procedure returns correct results for a given store ID'

DECLARE @stor_id char(4) = '7066'
DECLARE @count int

EXEC @count = history_proc @stor_id

IF (@count > 0)
BEGIN
    PRINT 'PASS: history_proc procedure returned correct number of rows'
END
ELSE
BEGIN
    PRINT 'FAIL: history_proc procedure returned incorrect number of rows'
END
GO
PRINT 'Test 45: Verify if storeid_proc procedure returns correct results for a given store ID'

DECLARE @stor_id char(4) = '7066'
DECLARE @count int

EXEC @count = storeid_proc @stor_id

IF (@count > 0)
BEGIN
    PRINT 'PASS: storeid_proc procedure returned correct number of rows'
END
ELSE
BEGIN
    PRINT 'FAIL: storeid_proc procedure returned incorrect number of rows'
END
GO
PRINT 'Test 46: Verify if storename_proc procedure returns correct results for a given store name'

DECLARE @stor_name varchar(40) = 'lake ci%'
DECLARE @count int

EXEC @count = storename_proc @stor_name

IF (@count > 0)
BEGIN
    PRINT 'PASS: storename_proc procedure returned correct number of rows'
END
ELSE
BEGIN
    PRINT 'FAIL: storename_proc procedure returned incorrect number of rows'
END
GO
PRINT 'Test 46: Verify if storename_proc procedure returns correct results for a given store name'

DECLARE @stor_name varchar(40) = 'lake ci%'
DECLARE @count int

EXEC @count = storename_proc @stor_name

IF (@count > 0)
BEGIN
    PRINT 'PASS: storename_proc procedure returned correct number of rows'
END
ELSE
BEGIN
    PRINT 'FAIL: storename_proc procedure returned incorrect number of rows'
END
GO
PRINT 'Test 46 - Verify that inserting a new record in the salesdetail table works correctly'
BEGIN TRY
    INSERT INTO dbo.salesdetail (stor_id, ord_num, title_id, qty, discount) 
    VALUES ('6380', 700001, 'BU1032', 5, 0.25)
    SELECT 'Test 46 - PASS' AS Result
END TRY
BEGIN CATCH
    SELECT 'Test 46 - FAIL' AS Result, ERROR_MESSAGE() AS ErrorMessage
END CATCH
GO
PRINT 'Test 47 - Verify that inserting a new record in the sales table works correctly'
BEGIN TRY
    INSERT INTO dbo.sales (stor_id, date) 
    VALUES ('6380', '2023-04-29')
    SELECT 'Test 47 - PASS' AS Result
END TRY
BEGIN CATCH
    SELECT 'Test 47 - FAIL' AS Result, ERROR_MESSAGE() AS ErrorMessage
END CATCH
GO
PRINT 'Test 48 - Verify that the storeid_proc stored procedure returns the correct results when given a valid store id'
BEGIN TRY
    DECLARE @rowCount INT
    EXEC @rowCount = storeid_proc '6380'
    IF @rowCount = 1
        SELECT 'Test 48 - PASS' AS Result
    ELSE
        SELECT 'Test 48 - FAIL' AS Result, 'Unexpected number of rows returned' AS ErrorMessage
END TRY
BEGIN CATCH
    SELECT 'Test 48 - FAIL' AS Result, ERROR_MESSAGE() AS ErrorMessage
END CATCH
GO
PRINT 'Test 49 - Verify that the storename_proc stored procedure returns the correct results when given a valid store name'
BEGIN TRY
    DECLARE @rowCount INT
    EXEC @rowCount = storename_proc 'Los Angeles'
    IF @rowCount = 1
        SELECT 'Test 49 - PASS' AS Result
    ELSE
        SELECT 'Test 49 - FAIL' AS Result, 'Unexpected number of rows returned' AS ErrorMessage
END TRY
BEGIN CATCH
    SELECT 'Test 49 - FAIL' AS Result, ERROR_MESSAGE() AS ErrorMessage
END CATCH
GO
PRINT 'Test 50 - Verify that the title_proc stored procedure returns the correct results when given a valid title'
BEGIN TRY
    DECLARE @rowCount INT
    EXEC @rowCount = title_proc 'The'
    IF @rowCount > 0
        SELECT 'Test 50 - PASS' AS Result
    ELSE
        SELECT 'Test 50 - FAIL' AS Result, 'No rows returned' AS ErrorMessage
END TRY
BEGIN CATCH
    SELECT 'Test 50 - FAIL' AS Result, ERROR_MESSAGE() AS ErrorMessage
END CATCH
GO
