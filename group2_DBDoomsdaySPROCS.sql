USE Group2_DD;

DROP PROCEDURE IF EXISTS usp_GetCityShelterSummary;
DROP PROCEDURE IF EXISTS usp_GetSurvivorProfile;
DROP PROCEDURE IF EXISTS usp_updateItemValue
DROP PROCEDURE IF EXISTS usp_safePowerDelete
DROP PROCEDURE IF EXISTS usp_safeWaterDelete
DROP PROCEDURE IF EXISTS usp_ItemSearch


/* =========================================
   PROCEDURES
   ========================================= */

/*Updates an item’s value​*/
GO
CREATE PROCEDURE usp_updateItemValue
@item_id INT,
@new_value DECIMAL(10,2)
AS
IF EXISTS (SELECT * FROM Item WHERE item_id=@item_id)
	BEGIN
		UPDATE Item SET unit_value = @new_value WHERE item_id = @item_id
		PRINT('Item value updated')
	END
ELSE
	BEGIN
		PRINT('Item not found')
	END
GO

-- Demonstrate - Allows for easy updating of item values 
SELECT * FROM Item WHERE item_id = 1
EXECUTE usp_updateItemValue @item_id = 1, @new_value = 2.99
GO

/*Safe delete procedures for both power and
water sources (ensure they are not assigned a
shelter)​*/
CREATE PROCEDURE usp_safePowerDelete
@power_source_id INT
AS
BEGIN
IF EXISTS (SELECT * FROM PowerSource WHERE power_source_id = @power_source_id)
	BEGIN
		IF EXISTS (SELECT * FROM Shelter_Power WHERE power_source_id=@power_source_id)
			BEGIN
				UPDATE PowerSource SET is_active = 0 WHERE power_source_id = @power_source_id;
				PRINT('Power source is currently assigned a shelter so was set to inactive instead of being deleted');
			END
		ELSE
			BEGIN
				DELETE FROM Shelter_Power WHERE power_source_id = @power_source_id
			END
	END
ELSE
	BEGIN
		PRINT('Power source not found')
	END
END
GO

-- Demonstrate - Does not allow water/power sources in use to be deleted, is used in case the constraint fails
SELECT ps.power_source_id FROM PowerSource ps WHERE ps.power_source_id IN (SELECT sp.power_source_id FROM Shelter_Power sp)
EXECUTE usp_safePowerDelete @power_source_id = 1
SELECT * FROM PowerSource WHERE power_source_id = 1
GO

/*Dynamic query to look for quantities of an item
type in shelters (with max/min filters)*/

CREATE PROCEDURE usp_ItemSearch
@itemCategory NVARCHAR(100) = NULL,
@maxQty INT = NULL,
@minQty INT = NULL
AS
BEGIN
DECLARE @sql AS NVARCHAR(MAX) = 'SELECT s.shelter_id, s.shelter_name, i.category, SUM(iv.quantity) AS total_items
	FROM Shelter s
	CROSS JOIN Item i
	LEFT JOIN Inventory iv ON iv.shelter_id = s.shelter_id AND i.item_id = iv.item_id WHERE 1 = 1 '
IF (@itemCategory IS NOT NULL)
	BEGIN
		SET @sql += ' AND i.category = ''' + @itemCategory + '''';
	END

SET @sql += ' GROUP BY s.shelter_id, s.shelter_name, i.category HAVING 1=1'
IF (@maxQty IS NOT NULL)
	BEGIN
		SET @sql += ' AND SUM(iv.quantity) <= ' + CONVERT(NVARCHAR, @maxQty);
	END
IF (@minQty IS NOT NULL)
	BEGIN
		SET @sql += ' AND SUM(iv.quantity) >= ' + CONVERT(NVARCHAR, @minQty);
	END
EXECUTE sp_executesql @sql;
END


GO
-- Demonstrate - Allows for easy checks of item quantities at shelters
EXECUTE usp_ItemSearch @itemCategory = 'Medical', @maxQty = 10, @minQty = 2

GO

-- Get capacity, open beds, and infected counts for shelters in a city
CREATE PROCEDURE usp_GetCityShelterSummary
    @CityName NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @InfectedStatusId INT;
    SELECT @InfectedStatusId = status_id
    FROM Status
    WHERE status_name = 'Infected';

    SELECT 
        s.shelter_id,
        s.shelter_name,
        s.capacity,
        COUNT(sv.survivor_id) AS total_survivors,
        s.capacity - COUNT(sv.survivor_id) AS open_beds,
        SUM(CASE WHEN sv.status_id = @InfectedStatusId THEN 1 ELSE 0 END) AS infected_survivors
    FROM City c
    JOIN Shelter s       ON s.city_id      = c.city_id
    LEFT JOIN Survivor sv ON sv.shelter_id = s.shelter_id
    WHERE c.city_name = @CityName
    GROUP BY s.shelter_id, s.shelter_name, s.capacity
    ORDER BY s.shelter_name;
END;
GO

-- Demonstrate - Allows for easy checks on all shelters capacity/infected summary in a city
EXECUTE usp_GetCityShelterSummary @cityName = 'Sandwich'
GO

-- Get a single survivor's overall profile: status, disease cases, encounters
CREATE PROCEDURE usp_GetSurvivorProfile
    @SurvivorId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        sv.survivor_id,
        sv.first_name,
        sv.last_name,
        sv.birth_date,
        st.status_name,
        COUNT(DISTINCT dc.disease_case_id) AS total_disease_cases,
        SUM(CASE WHEN dc.cure_date IS NULL THEN 1 ELSE 0 END) AS open_disease_cases,
        COUNT(DISTINCT se.encounter_id) AS total_encounters,
        SUM(CASE WHEN e.encounter_vibe = 'Hostile' THEN 1 ELSE 0 END) AS hostile_encounters
    FROM Survivor sv
    JOIN Status st          ON st.status_id       = sv.status_id
    LEFT JOIN DiseaseCase dc ON dc.survivor_id    = sv.survivor_id
    LEFT JOIN Survivor_Encounter se ON se.survivor_id = sv.survivor_id
    LEFT JOIN Encounter e          ON e.encounter_id  = se.encounter_id
    WHERE sv.survivor_id = @SurvivorId
    GROUP BY 
        sv.survivor_id,
        sv.first_name,
        sv.last_name,
        sv.birth_date,
        st.status_name;
END;
GO

-- Demonstrate - Allows for getting a quick overview of a survivor
EXECUTE usp_GetSurvivorProfile @SurvivorId = 21