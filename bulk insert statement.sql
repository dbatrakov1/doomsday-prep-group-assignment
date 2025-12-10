USE Group2_DD;
GO
DROP PROCEDURE IF EXISTS sp_insert
GO
CREATE PROCEDURE sp_insert
    @TableName NVARCHAR(128)
AS
BEGIN
    --SET NOCOUNT ON;
    DECLARE @BasePath NVARCHAR(500) = 'C:\Users\bette\Desktop\School\Data\Group Work\doomsday-prep-group-assignment\CSVs\';  -- Set your folder path
    DECLARE @SQL NVARCHAR(MAX);
    SET @SQL = N'
    BULK INSERT ' + QUOTENAME(@TableName) + '
    FROM ''' + @BasePath + @TableName + '.csv''
    WITH (
        FIELDTERMINATOR = '','',
        ROWTERMINATOR = ''\n'',
        FIRSTROW = 2
    );';
    EXEC sp_executesql @SQL;
END;
GO

EXEC sp_insert 'City';
EXEC sp_insert 'PowerSource';
EXEC sp_insert 'WaterSource';
EXEC sp_insert 'Shelter';
EXEC sp_insert 'Survivor';
EXEC sp_insert 'Skill';
EXEC sp_insert 'Item';
EXEC sp_insert 'Status';
EXEC sp_insert 'ResourceSite';
EXEC sp_insert 'Faction';
EXEC sp_insert 'Encounter';
EXEC sp_insert 'DiseaseCase';
EXEC sp_insert 'Survivor_Skill';
EXEC sp_insert 'Faction_Relations';
EXEC sp_insert 'Inventory';
EXEC sp_insert 'Shelter_Power';
EXEC sp_insert 'Shelter_Water';
EXEC sp_insert 'Faction_Encounter';
EXEC sp_insert 'Survivor_Encounter';