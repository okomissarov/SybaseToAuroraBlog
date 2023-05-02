USE pubs3
GO
IF EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'authors$authors_5920021092'  AND sc.name = N'dbo'  AND type in (N'UQ'))
ALTER TABLE [dbo].[authors] DROP CONSTRAINT [authors$authors_5920021092]
 GO



ALTER TABLE [dbo].[authors]
 ADD CONSTRAINT [authors$authors_5920021092]
 UNIQUE 
   NONCLUSTERED ([au_id] ASC)

GO


USE pubs3
GO
IF EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'publishers$publishers_6400022802'  AND sc.name = N'dbo'  AND type in (N'UQ'))
ALTER TABLE [dbo].[publishers] DROP CONSTRAINT [publishers$publishers_6400022802]
 GO



ALTER TABLE [dbo].[publishers]
 ADD CONSTRAINT [publishers$publishers_6400022802]
 UNIQUE 
   NONCLUSTERED ([pub_id] ASC)

GO


USE pubs3
GO
IF EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'sales$sales_8480030212'  AND sc.name = N'dbo'  AND type in (N'UQ'))
ALTER TABLE [dbo].[sales] DROP CONSTRAINT [sales$sales_8480030212]
 GO



ALTER TABLE [dbo].[sales]
 ADD CONSTRAINT [sales$sales_8480030212]
 UNIQUE 
   NONCLUSTERED ([ord_num] ASC)

GO


USE pubs3
GO
IF EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'store_employees$store_empl_9120032492'  AND sc.name = N'dbo'  AND type in (N'UQ'))
ALTER TABLE [dbo].[store_employees] DROP CONSTRAINT [store_employees$store_empl_9120032492]
 GO



ALTER TABLE [dbo].[store_employees]
 ADD CONSTRAINT [store_employees$store_empl_9120032492]
 UNIQUE 
   NONCLUSTERED ([emp_id] ASC)

GO


USE pubs3
GO
IF EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'stores$stores_8000028502'  AND sc.name = N'dbo'  AND type in (N'UQ'))
ALTER TABLE [dbo].[stores] DROP CONSTRAINT [stores$stores_8000028502]
 GO



ALTER TABLE [dbo].[stores]
 ADD CONSTRAINT [stores$stores_8000028502]
 UNIQUE 
   NONCLUSTERED ([stor_id] ASC)

GO


USE pubs3
GO
IF EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'titles$titles_6880024512'  AND sc.name = N'dbo'  AND type in (N'UQ'))
ALTER TABLE [dbo].[titles] DROP CONSTRAINT [titles$titles_6880024512]
 GO



ALTER TABLE [dbo].[titles]
 ADD CONSTRAINT [titles$titles_6880024512]
 UNIQUE 
   NONCLUSTERED ([title_id] ASC)

GO


USE pubs3
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc on so.schema_id = sc.schema_id WHERE so.name = N'deltitle'  AND sc.name=N'dbo'  AND type in (N'TR'))
 DROP TRIGGER [dbo].[deltitle]
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER dbo.deltitle
   ON dbo.titles
    FOR DELETE
   AS 
      IF 
         (
            SELECT count(*)
            FROM deleted, dbo.salesdetail
            WHERE dbo.salesdetail.title_id = deleted.title_id
         ) > 0
         BEGIN

            IF @@TRANCOUNT > 0
               ROLLBACK TRANSACTION 

            PRINT 'You can''t delete a title with sales.'

         END
GO
GO

USE pubs3
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc on so.schema_id = sc.schema_id WHERE so.name = N'totalsales_trig'  AND sc.name=N'dbo'  AND type in (N'TR'))
 DROP TRIGGER [dbo].[totalsales_trig]
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER dbo.totalsales_trig
   ON dbo.salesdetail
    FOR INSERT,  UPDATE,  DELETE
   AS 
      /* Save processing:  return if there are no rows affected*/
      IF @@ROWCOUNT = 0
         BEGIN
            RETURN 
         END
      
      /*
      *    add all the new values
      *    use isnull:  a null value in the titles table means 
      *   **              "no sales yet" not "sales unknown"
      *
      */
      UPDATE dbo.titles
         SET 
            num_sold = isnull(dbo.titles.num_sold, 0) + 
               (
                  SELECT sum(inserted.qty)
                  FROM inserted
                  WHERE dbo.titles.title_id = inserted.title_id
               )
      /* remove all values being deleted or updated*/
      UPDATE dbo.titles
         SET 
            num_sold = isnull(dbo.titles.num_sold, 0) - 
               (
                  SELECT sum(deleted.qty)
                  FROM deleted
                  WHERE dbo.titles.title_id = deleted.title_id
               )
GO
GO

USE pubs3
GO
IF EXISTS (
       SELECT * FROM sys.objects  so JOIN sys.indexes si
       ON so.object_id = si.object_id
       JOIN sys.schemas sc
       ON so.schema_id = sc.schema_id
       WHERE so.name = N'titleauthor'  AND sc.name = N'dbo'  AND si.name = N'auidind' AND so.type in (N'U'))
   DROP INDEX [auidind] ON [titleauthor] 
GO
CREATE NONCLUSTERED INDEX [auidind] ON [dbo].[titleauthor]
(
   [au_id] ASC
)
WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY] 
GO
GO

USE pubs3
GO
IF EXISTS (
       SELECT * FROM sys.objects  so JOIN sys.indexes si
       ON so.object_id = si.object_id
       JOIN sys.schemas sc
       ON so.schema_id = sc.schema_id
       WHERE so.name = N'authors'  AND sc.name = N'dbo'  AND si.name = N'aunmind' AND so.type in (N'U'))
   DROP INDEX [aunmind] ON [authors] 
GO
CREATE NONCLUSTERED INDEX [aunmind] ON [dbo].[authors]
(
   [au_lname] ASC,
   [au_fname] ASC
)
WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY] 
GO
GO

USE pubs3
GO
IF EXISTS (
       SELECT * FROM sys.objects  so JOIN sys.indexes si
       ON so.object_id = si.object_id
       JOIN sys.schemas sc
       ON so.schema_id = sc.schema_id
       WHERE so.name = N'salesdetail'  AND sc.name = N'dbo'  AND si.name = N'salesdetailind' AND so.type in (N'U'))
   DROP INDEX [salesdetailind] ON [salesdetail] 
GO
CREATE NONCLUSTERED INDEX [salesdetailind] ON [dbo].[salesdetail]
(
   [stor_id] ASC
)
WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY] 
GO
GO

USE pubs3
GO
IF EXISTS (
       SELECT * FROM sys.objects  so JOIN sys.indexes si
       ON so.object_id = si.object_id
       JOIN sys.schemas sc
       ON so.schema_id = sc.schema_id
       WHERE so.name = N'roysched'  AND sc.name = N'dbo'  AND si.name = N'titleidind' AND so.type in (N'U'))
   DROP INDEX [titleidind] ON [roysched] 
GO
CREATE NONCLUSTERED INDEX [titleidind] ON [dbo].[roysched]
(
   [title_id] ASC
)
WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY] 
GO
GO

USE pubs3
GO
IF EXISTS (
       SELECT * FROM sys.objects  so JOIN sys.indexes si
       ON so.object_id = si.object_id
       JOIN sys.schemas sc
       ON so.schema_id = sc.schema_id
       WHERE so.name = N'titleauthor'  AND sc.name = N'dbo'  AND si.name = N'titleidind' AND so.type in (N'U'))
   DROP INDEX [titleidind] ON [titleauthor] 
GO
CREATE NONCLUSTERED INDEX [titleidind] ON [dbo].[titleauthor]
(
   [title_id] ASC
)
WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY] 
GO
GO

USE pubs3
GO
IF EXISTS (
       SELECT * FROM sys.objects  so JOIN sys.indexes si
       ON so.object_id = si.object_id
       JOIN sys.schemas sc
       ON so.schema_id = sc.schema_id
       WHERE so.name = N'salesdetail'  AND sc.name = N'dbo'  AND si.name = N'titleidind' AND so.type in (N'U'))
   DROP INDEX [titleidind] ON [salesdetail] 
GO
CREATE NONCLUSTERED INDEX [titleidind] ON [dbo].[salesdetail]
(
   [title_id] ASC
)
WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY] 
GO
GO

USE pubs3
GO
IF EXISTS (
       SELECT * FROM sys.objects  so JOIN sys.indexes si
       ON so.object_id = si.object_id
       JOIN sys.schemas sc
       ON so.schema_id = sc.schema_id
       WHERE so.name = N'titles'  AND sc.name = N'dbo'  AND si.name = N'titleind' AND so.type in (N'U'))
   DROP INDEX [titleind] ON [titles] 
GO
CREATE NONCLUSTERED INDEX [titleind] ON [dbo].[titles]
(
   [title] ASC
)
WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY] 
GO
GO

USE pubs3
GO
IF EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'blurbs$blurbs_au_id_1200004275'  AND sc.name = N'dbo'  AND type in (N'F'))
ALTER TABLE [dbo].[blurbs] DROP CONSTRAINT [blurbs$blurbs_au_id_1200004275]
 GO



ALTER TABLE [dbo].[blurbs]
 ADD CONSTRAINT [blurbs$blurbs_au_id_1200004275]
 FOREIGN KEY 
   ([au_id])
 REFERENCES 
   [pubs3].[dbo].[authors]     ([au_id])
    ON DELETE NO ACTION
    ON UPDATE NO ACTION

GO


USE pubs3
GO
IF EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'discounts$discounts_stor_i_1152004104'  AND sc.name = N'dbo'  AND type in (N'F'))
ALTER TABLE [dbo].[discounts] DROP CONSTRAINT [discounts$discounts_stor_i_1152004104]
 GO



ALTER TABLE [dbo].[discounts]
 ADD CONSTRAINT [discounts$discounts_stor_i_1152004104]
 FOREIGN KEY 
   ([stor_id])
 REFERENCES 
   [pubs3].[dbo].[stores]     ([stor_id])
    ON DELETE NO ACTION
    ON UPDATE NO ACTION

GO


USE pubs3
GO
IF EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'roysched$roysched_title__768002736'  AND sc.name = N'dbo'  AND type in (N'F'))
ALTER TABLE [dbo].[roysched] DROP CONSTRAINT [roysched$roysched_title__768002736]
 GO



ALTER TABLE [dbo].[roysched]
 ADD CONSTRAINT [roysched$roysched_title__768002736]
 FOREIGN KEY 
   ([title_id])
 REFERENCES 
   [pubs3].[dbo].[titles]     ([title_id])
    ON DELETE NO ACTION
    ON UPDATE NO ACTION

GO


USE pubs3
GO
IF EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'sales$sales_stor_i_880003135'  AND sc.name = N'dbo'  AND type in (N'F'))
ALTER TABLE [dbo].[sales] DROP CONSTRAINT [sales$sales_stor_i_880003135]
 GO



ALTER TABLE [dbo].[sales]
 ADD CONSTRAINT [sales$sales_stor_i_880003135]
 FOREIGN KEY 
   ([stor_id])
 REFERENCES 
   [pubs3].[dbo].[stores]     ([stor_id])
    ON DELETE NO ACTION
    ON UPDATE NO ACTION

GO


USE pubs3
GO
IF EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'salesdetail$salesdetai_ord_nu_1024003648'  AND sc.name = N'dbo'  AND type in (N'F'))
ALTER TABLE [dbo].[salesdetail] DROP CONSTRAINT [salesdetail$salesdetai_ord_nu_1024003648]
 GO



ALTER TABLE [dbo].[salesdetail]
 ADD CONSTRAINT [salesdetail$salesdetai_ord_nu_1024003648]
 FOREIGN KEY 
   ([ord_num])
 REFERENCES 
   [pubs3].[dbo].[sales]     ([ord_num])
    ON DELETE NO ACTION
    ON UPDATE NO ACTION

GO

IF EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'salesdetail$salesdetai_stor_i_1008003591'  AND sc.name = N'dbo'  AND type in (N'F'))
ALTER TABLE [dbo].[salesdetail] DROP CONSTRAINT [salesdetail$salesdetai_stor_i_1008003591]
 GO



ALTER TABLE [dbo].[salesdetail]
 ADD CONSTRAINT [salesdetail$salesdetai_stor_i_1008003591]
 FOREIGN KEY 
   ([stor_id])
 REFERENCES 
   [pubs3].[dbo].[stores]     ([stor_id])
    ON DELETE NO ACTION
    ON UPDATE NO ACTION

GO

IF EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'salesdetail$salesdetai_title__1040003705'  AND sc.name = N'dbo'  AND type in (N'F'))
ALTER TABLE [dbo].[salesdetail] DROP CONSTRAINT [salesdetail$salesdetai_title__1040003705]
 GO



ALTER TABLE [dbo].[salesdetail]
 ADD CONSTRAINT [salesdetail$salesdetai_title__1040003705]
 FOREIGN KEY 
   ([title_id])
 REFERENCES 
   [pubs3].[dbo].[titles]     ([title_id])
    ON DELETE NO ACTION
    ON UPDATE NO ACTION

GO


USE pubs3
GO
IF EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'store_employees$store_empl_mgr_id_960003420'  AND sc.name = N'dbo'  AND type in (N'F'))
ALTER TABLE [dbo].[store_employees] DROP CONSTRAINT [store_employees$store_empl_mgr_id_960003420]
 GO



ALTER TABLE [dbo].[store_employees]
 ADD CONSTRAINT [store_employees$store_empl_mgr_id_960003420]
 FOREIGN KEY 
   ([mgr_id])
 REFERENCES 
   [pubs3].[dbo].[store_employees]     ([emp_id])
    ON DELETE NO ACTION
    ON UPDATE NO ACTION

GO

IF EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'store_employees$store_empl_stor_i_944003363'  AND sc.name = N'dbo'  AND type in (N'F'))
ALTER TABLE [dbo].[store_employees] DROP CONSTRAINT [store_employees$store_empl_stor_i_944003363]
 GO



ALTER TABLE [dbo].[store_employees]
 ADD CONSTRAINT [store_employees$store_empl_stor_i_944003363]
 FOREIGN KEY 
   ([stor_id])
 REFERENCES 
   [pubs3].[dbo].[stores]     ([stor_id])
    ON DELETE NO ACTION
    ON UPDATE NO ACTION

GO


USE pubs3
GO
IF EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'titleauthor$titleautho_au_id_1088003876'  AND sc.name = N'dbo'  AND type in (N'F'))
ALTER TABLE [dbo].[titleauthor] DROP CONSTRAINT [titleauthor$titleautho_au_id_1088003876]
 GO



ALTER TABLE [dbo].[titleauthor]
 ADD CONSTRAINT [titleauthor$titleautho_au_id_1088003876]
 FOREIGN KEY 
   ([au_id])
 REFERENCES 
   [pubs3].[dbo].[authors]     ([au_id])
    ON DELETE NO ACTION
    ON UPDATE NO ACTION

GO

IF EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'titleauthor$titleautho_title__1104003933'  AND sc.name = N'dbo'  AND type in (N'F'))
ALTER TABLE [dbo].[titleauthor] DROP CONSTRAINT [titleauthor$titleautho_title__1104003933]
 GO



ALTER TABLE [dbo].[titleauthor]
 ADD CONSTRAINT [titleauthor$titleautho_title__1104003933]
 FOREIGN KEY 
   ([title_id])
 REFERENCES 
   [pubs3].[dbo].[titles]     ([title_id])
    ON DELETE NO ACTION
    ON UPDATE NO ACTION

GO


USE pubs3
GO
IF EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'titles$titles_pub_id_720002565'  AND sc.name = N'dbo'  AND type in (N'F'))
ALTER TABLE [dbo].[titles] DROP CONSTRAINT [titles$titles_pub_id_720002565]
 GO



ALTER TABLE [dbo].[titles]
 ADD CONSTRAINT [titles$titles_pub_id_720002565]
 FOREIGN KEY 
   ([pub_id])
 REFERENCES 
   [pubs3].[dbo].[publishers]     ([pub_id])
    ON DELETE NO ACTION
    ON UPDATE NO ACTION

GO


USE pubs3
GO
IF EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'publishers$rule$pub_id'  AND sc.name = N'dbo'  AND type in (N'C'))
ALTER TABLE [dbo].[publishers] DROP CONSTRAINT [publishers$rule$pub_id]
 GO



ALTER TABLE [dbo].[publishers]
 ADD CONSTRAINT [publishers$rule$pub_id]
 CHECK (PATINDEX('1756|1622|0877|0736|1389|99[0-9][0-9]', [publishers].[pub_id]) > 0)
GO



USE pubs3
GO
IF EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'salesdetail$rule$title_id'  AND sc.name = N'dbo'  AND type in (N'C'))
ALTER TABLE [dbo].[salesdetail] DROP CONSTRAINT [salesdetail$rule$title_id]
 GO



ALTER TABLE [dbo].[salesdetail]
 ADD CONSTRAINT [salesdetail$rule$title_id]
 CHECK (PATINDEX('BU[0-9][0-9][0-9][0-9]', [salesdetail].[title_id]) > 0 OR PATINDEX('[MT]C[0-9][0-9][0-9][0-9]', [salesdetail].[title_id]) > 0 OR PATINDEX('P[SC][0-9][0-9][0-9][0-9]', [salesdetail].[title_id]) > 0 OR PATINDEX('[A-Z][A-Z]xxxx', [salesdetail].[title_id]) > 0 OR PATINDEX('[A-Z][A-Z]yyyy', [salesdetail].[title_id]) > 0)
GO



USE pubs3
GO
IF EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'titles$rule$title_id'  AND sc.name = N'dbo'  AND type in (N'C'))
ALTER TABLE [dbo].[titles] DROP CONSTRAINT [titles$rule$title_id]
 GO



ALTER TABLE [dbo].[titles]
 ADD CONSTRAINT [titles$rule$title_id]
 CHECK (PATINDEX('BU[0-9][0-9][0-9][0-9]', [titles].[title_id]) > 0 OR PATINDEX('[MT]C[0-9][0-9][0-9][0-9]', [titles].[title_id]) > 0 OR PATINDEX('P[SC][0-9][0-9][0-9][0-9]', [titles].[title_id]) > 0 OR PATINDEX('[A-Z][A-Z]xxxx', [titles].[title_id]) > 0 OR PATINDEX('[A-Z][A-Z]yyyy', [titles].[title_id]) > 0)
GO


USE pubs3
GO
ALTER TABLE  [dbo].[authors]
 ADD DEFAULT ('UNKNOWN') FOR [phone]
GO


USE pubs3
GO
ALTER TABLE  [dbo].[titles]
 ADD DEFAULT ('UNDECIDED') FOR [type]
GO

ALTER TABLE  [dbo].[titles]
 ADD DEFAULT (getdate()) FOR [pubdate]
GO
