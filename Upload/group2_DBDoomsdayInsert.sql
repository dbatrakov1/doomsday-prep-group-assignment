USE Group2_DD;
GO
DROP PROCEDURE IF EXISTS sp_insert
GO
CREATE PROCEDURE sp_insert
    @TableName NVARCHAR(128),
    @FileName NVARCHAR(128)
AS
BEGIN
    --SET NOCOUNT ON;
    DECLARE @BasePath NVARCHAR(500) = 'C:\**File path location where the CSVs are**\';  -- Set your folder path
    DECLARE @SQL NVARCHAR(MAX);
    SET @SQL = N'
        BULK INSERT ' + QUOTENAME(@TableName) + '
        FROM ''' + @BasePath + @FileName + '.csv''
        WITH (
            FIELDTERMINATOR = '','',
            ROWTERMINATOR = ''\n'',
            FIRSTROW = 2
        );';
    EXEC sp_executesql @SQL;
END;
GO

EXEC sp_insert 'City', 'group2_DBDoomsdayInsertCity';
EXEC sp_insert 'PowerSource', 'group2_DBDoomsdayInsertPowerSource';
EXEC sp_insert 'WaterSource', 'group2_DBDoomsdayInsertWaterSource';
EXEC sp_insert 'Shelter', 'group2_DBDoomsdayInsertShelter';
EXEC sp_insert 'Survivor', 'group2_DBDoomsdayInsertSurvivor';
EXEC sp_insert 'Skill', 'group2_DBDoomsdayInsertSkill';
EXEC sp_insert 'Item', 'group2_DBDoomsdayInsertItem';
EXEC sp_insert 'Status', 'group2_DBDoomsdayInsertStatus';
EXEC sp_insert 'ResourceSite', 'group2_DBDoomsdayInsertResourceSite';
EXEC sp_insert 'Encounter', 'group2_DBDoomsdayInsertEncounter';
EXEC sp_insert 'DiseaseCase', 'group2_DBDoomsdayInsertDiseaseCase';
EXEC sp_insert 'Survivor_Skill', 'group2_DBDoomsdayInsertSurvivor_Skill';
EXEC sp_insert 'Faction_Relations', 'group2_DBDoomsdayInsertFaction_Relations';
EXEC sp_insert 'Inventory', 'group2_DBDoomsdayInsertInventory';
EXEC sp_insert 'Shelter_Power', 'group2_DBDoomsdayInsertShelter_Power';
EXEC sp_insert 'Shelter_Water', 'group2_DBDoomsdayInsertShelter_Water';
EXEC sp_insert 'Faction_Encounter', 'group2_DBDoomsdayInsertFaction_Encounter';
EXEC sp_insert 'Survivor_Encounter', 'group2_DBDoomsdayInsertSurvivor_Encounter';