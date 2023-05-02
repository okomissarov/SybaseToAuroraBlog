
USE pubs3
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'dbo')      
     EXEC (N'CREATE SCHEMA dbo')                                   
 GO                                                               

USE pubs3
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'byroyalty'  AND sc.name=N'dbo'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [dbo].[byroyalty]
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE byroyalty  
   @percentage int
AS 
   SELECT dbo.titleauthor.au_id AS au_id
   FROM dbo.titleauthor
   WHERE dbo.titleauthor.royaltyper = @percentage
GO
GO

USE pubs3
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'discount_proc'  AND sc.name=N'dbo'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [dbo].[discount_proc]
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE discount_proc
AS 
   SELECT 
      dbo.discounts.discounttype AS discounttype, 
      dbo.discounts.stor_id AS stor_id, 
      dbo.discounts.lowqty AS lowqty, 
      dbo.discounts.highqty AS highqty, 
      dbo.discounts.discount AS discount
   FROM dbo.discounts
GO
GO

USE pubs3
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'history_proc'  AND sc.name=N'dbo'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [dbo].[history_proc]
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
/* create procs for use by APT Sales Example*/
CREATE PROCEDURE history_proc  
   @stor_id char(4)
AS 
   SELECT 
      dbo.sales.date AS date, 
      dbo.sales.ord_num AS ord_num, 
      dbo.salesdetail.qty AS qty, 
      dbo.salesdetail.title_id AS title_id, 
      dbo.salesdetail.discount AS discount, 
      dbo.titles.price AS price, 
      dbo.salesdetail.qty * dbo.titles.price * (1 - dbo.salesdetail.discount / 100) AS total
   FROM dbo.sales, dbo.salesdetail, dbo.titles
   WHERE 
      dbo.sales.stor_id = @stor_id AND 
      dbo.sales.ord_num = dbo.salesdetail.ord_num AND 
      dbo.titles.title_id = dbo.salesdetail.title_id
   ORDER BY dbo.sales.date DESC, dbo.sales.ord_num
GO
GO

USE pubs3
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'insert_sales_proc'  AND sc.name=N'dbo'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [dbo].[insert_sales_proc]
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE insert_sales_proc  
   @stor_id char(4),
   @orderdate varchar(40)
AS 
   INSERT dbo.sales(stor_id, date)
      VALUES (@stor_id, @orderdate)
GO
GO

USE pubs3
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'insert_salesdetail_proc'  AND sc.name=N'dbo'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [dbo].[insert_salesdetail_proc]
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE insert_salesdetail_proc  
   @stor_id char(4),
   @ord_num numeric(6, 0),
   @title_id char(6),
   @qty smallint,
   @discount float(53)
AS 
   INSERT dbo.salesdetail(
      stor_id, 
      ord_num, 
      title_id, 
      qty, 
      discount)
      VALUES (
         @stor_id, 
         @ord_num, 
         @title_id, 
         @qty, 
         @discount)
GO
GO

USE pubs3
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'storeid_proc'  AND sc.name=N'dbo'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [dbo].[storeid_proc]
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE storeid_proc  
   @stor_id char(4)
AS 
   SELECT 
      dbo.stores.stor_name AS stor_name, 
      dbo.stores.stor_id AS stor_id, 
      dbo.stores.stor_address AS stor_address, 
      dbo.stores.city AS city, 
      dbo.stores.state AS state, 
      dbo.stores.postalcode AS postalcode, 
      dbo.stores.country AS country
   FROM dbo.stores
   WHERE dbo.stores.stor_id = @stor_id
   RETURN @@ROWCOUNT
GO
GO

USE pubs3
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'storename_proc'  AND sc.name=N'dbo'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [dbo].[storename_proc]
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE storename_proc  
   @stor_name varchar(40)
AS 
   DECLARE
      @lowered_name varchar(40)
   SELECT @lowered_name = lower(@stor_name) + '%'
   /*
   *   SSMA warning messages:
   *   S2SS0064: Possibility of mismatch in LIKE operator behavior.
   */

   SELECT 
      dbo.stores.stor_name AS stor_name, 
      dbo.stores.stor_id AS stor_id, 
      dbo.stores.stor_address AS stor_address, 
      dbo.stores.city AS city, 
      dbo.stores.state AS state, 
      dbo.stores.postalcode AS postalcode, 
      dbo.stores.country AS country
   FROM dbo.stores
   WHERE lower(dbo.stores.stor_name) LIKE rtrim(@lowered_name)
   RETURN @@ROWCOUNT
GO
GO

USE pubs3
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'title_proc'  AND sc.name=N'dbo'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [dbo].[title_proc]
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE title_proc  
   @title varchar(80)
AS 
   SELECT @title = lower(@title) + '%'
   /*
   *   SSMA warning messages:
   *   S2SS0064: Possibility of mismatch in LIKE operator behavior.
   */

   SELECT dbo.titles.title AS title, dbo.titles.title_id AS title_id, dbo.titles.price AS price
   FROM dbo.titles
   WHERE lower(dbo.titles.title) LIKE rtrim(@title)
   RETURN @@ROWCOUNT
GO
GO

USE pubs3
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'titleid_proc'  AND sc.name=N'dbo'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [dbo].[titleid_proc]
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE titleid_proc  
   @title_id varchar(80)
AS 
   SELECT @title_id = lower(@title_id) + '%'
   SELECT dbo.titles.title AS title, dbo.titles.title_id AS title_id, dbo.titles.price AS price
   FROM dbo.titles
   WHERE lower(dbo.titles.title_id) LIKE rtrim(@title_id)
   RETURN @@ROWCOUNT
GO
GO
