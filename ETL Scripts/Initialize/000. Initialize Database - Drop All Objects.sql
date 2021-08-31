IF OBJECT_ID('tempdb..#Commands') IS NOT NULL
	DROP TABLE #Commands
IF OBJECT_ID('tempdb..#Drops') IS NOT NULL
	DROP TABLE #Drops

SET NOCOUNT ON;

-- Set this to a value to only drop objects in specific schemas.
DECLARE @OnlyInSchemas NVARCHAR(1000)
SET @OnlyInSchemas = N'[synthea],[vocab],[omop],[helper]';
SET @OnlyInSchemas = REPLACE(REPLACE(@OnlyInSchemas,'[', ''), ']', '')

CREATE TABLE #Commands (
    [Description]   NVARCHAR(MAX),
    [Line]          NVARCHAR(MAX),
	[DateAdded]		DATETIME
) WITH (HEAP);

CREATE TABLE #Drops (
    [Type]          NVARCHAR(2),
    [Template]      NVARCHAR(MAX)
) WITH (HEAP);

-- -- -- -- -- OBJECTS NOT ASSOCIATED WITH TABLES -- -- -- -- --
INSERT INTO #Drops
SELECT N'AF', N'DROP AGGREGATE $S.$O;' UNION
SELECT N'FN', N'DROP FUNCTION $S.$O;' UNION
SELECT N'FS', N'DROP FUNCTION $S.$O;' UNION
SELECT N'FT', N'DROP FUNCTION $S.$O;' UNION
SELECT N'IF', N'DROP FUNCTION $S.$O;' UNION
SELECT N'P', N'DROP PROCEDURE $S.$O;' UNION
SELECT N'V', N'DROP VIEW $S.$O;' UNION
SELECT N'SN', N'DROP SYNONYM $S.$O;' UNION
SELECT N'SQ', N'DROP QUEUE $S.$O;' UNION
SELECT N'TR', N'DROP TRIGGER $S.$O;' UNION
SELECT N'TT', N'DROP TYPE $S.$O;' UNION
SELECT N'TF', N'DROP FUNCTION $S.$O;';

INSERT INTO #Commands
SELECT  QUOTENAME(RTRIM([S].[name])) + '.' + QUOTENAME(RTRIM([O].[name])),
        REPLACE(REPLACE([D].[Template], '$S', QUOTENAME(RTRIM([S].[name]))), '$O', QUOTENAME(RTRIM([O].[name]))),
		GETDATE()
    FROM [sys].[objects] AS [O]
        INNER JOIN [sys].[schemas] AS [S] ON [O].[schema_id] = [S].[schema_id]
        INNER JOIN #Drops AS [D] ON [O].[type] COLLATE Latin1_General_CS_AS = [D].[Type] COLLATE Latin1_General_CS_AS
        WHERE [S].[name] COLLATE Latin1_General_CS_AS IN (SELECT value FROM STRING_SPLIT(@OnlyInSchemas, ',')) 
          AND [S].[name] COLLATE Latin1_General_CS_AS <> 'sys'
          AND [O].[is_ms_shipped] = 0;

-- -- -- -- -- OBJECTS ASSOCIATED WITH TABLES -- -- -- -- --
DELETE FROM #Drops;
INSERT INTO #Drops
SELECT N'C', N'ALTER TABLE $TS.$TO DROP CONSTRAINT $O;' UNION
SELECT N'D', N'ALTER TABLE $TS.$TO DROP CONSTRAINT $O;' UNION
SELECT N'F', N'ALTER TABLE $TS.$TO DROP CONSTRAINT $O;' UNION
SELECT N'PK', N'ALTER TABLE $TS.$TO DROP CONSTRAINT $O;';

INSERT INTO #Commands
SELECT  QUOTENAME(RTRIM([S].[name])) + '.' + QUOTENAME(RTRIM([PO].[name])) + '::' + QUOTENAME(RTRIM([O].[name])),
        REPLACE(REPLACE(REPLACE([D].[Template], '$TS', QUOTENAME(RTRIM([S].[name]))), '$O', QUOTENAME(RTRIM([O].[name]))), '$TO', QUOTENAME(RTRIM([PO].[name]))),
		GETDATE()
    FROM [sys].[objects] AS [O]
        INNER JOIN [sys].[objects] AS [PO] ON [O].[parent_object_id] = [PO].[object_id]
        INNER JOIN [sys].[schemas] AS [S] ON [PO].[schema_id] = [S].[schema_id]
        INNER JOIN #Drops AS [D] ON [O].[type] COLLATE Latin1_General_CS_AS = [D].[Type] COLLATE Latin1_General_CS_AS
        WHERE [S].[name] COLLATE Latin1_General_CS_AS IN (SELECT value FROM STRING_SPLIT(@OnlyInSchemas, ',')) 
          AND [S].[name] COLLATE Latin1_General_CS_AS <> 'sys'
          AND [O].[is_ms_shipped] = 0;


-- -- -- -- -- ACTUAL DROP -- -- -- -- --
DELETE FROM #Drops;
INSERT INTO #Drops
SELECT N'U', N'DROP TABLE $S.$O;' UNION
SELECT N'V', N'DROP TABLE $S.$O;';

INSERT INTO #Commands
SELECT  QUOTENAME(RTRIM([S].[name])) + '.' + QUOTENAME(RTRIM([O].[name])),
        REPLACE(REPLACE([D].[Template], '$S', QUOTENAME(RTRIM([S].[name]))), '$O', QUOTENAME(RTRIM([O].[name]))),
		GETDATE()
    FROM [sys].[objects] AS [O]
        INNER JOIN [sys].[schemas] AS [S] ON [O].[schema_id] = [S].[schema_id]
        INNER JOIN #Drops AS [D] ON [O].[type] COLLATE Latin1_General_CS_AS = [D].[Type] COLLATE Latin1_General_CS_AS
        WHERE [S].[name] COLLATE Latin1_General_CS_AS IN (SELECT value FROM STRING_SPLIT(@OnlyInSchemas, ',')) 
          AND [S].[name] COLLATE Latin1_General_CS_AS <> 'sys'
          AND [O].[is_ms_shipped] = 0;


--Drop Schemas
INSERT INTO #Commands
SELECT  QUOTENAME(RTRIM([S].[name])),
        'DROP SCHEMA ' + QUOTENAME(RTRIM([S].[name])),
		GETDATE()
	FROM [sys].[schemas] AS [S]
        WHERE [S].[name] COLLATE Latin1_General_CS_AS IN (SELECT value FROM STRING_SPLIT(@OnlyInSchemas, ',')) 
          AND [S].[name] COLLATE Latin1_General_CS_AS <> 'sys'
          AND [S].[schema_id] > 7;


-- -- -- -- -- TABLES -- -- -- -- --
DECLARE @Description NVARCHAR(MAX);
DECLARE @Message NVARCHAR(MAX);
DECLARE @Command NVARCHAR(MAX);


WHILE (SELECT COUNT(*) FROM #Commands) > 0

BEGIN

SELECT TOP 1 
	@Description = Description,
	@Command = [Line]
FROM #Commands
ORDER BY DateAdded ASC, Description ASC


    SET @Message = N'Dropping ' + @Description + '...';
    PRINT @Message;

    BEGIN TRY
        EXEC sp_executesql @Command;
    END TRY
    BEGIN CATCH
        SET @Message = N'Failed to drop ' + @Description + ':';
        PRINT @Message;
        PRINT ERROR_MESSAGE()
    END CATCH

   DELETE FROM #Commands WHERE @Description = Description
END

