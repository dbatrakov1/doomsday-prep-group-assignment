USE Group2_DD;

DROP TRIGGER IF EXISTS trgResourceSiteDeletion
DROP TRIGGER IF EXISTS trgCheckOngoingCases
DROP TRIGGER IF EXISTS trgStopDeleteCurrency
DROP VIEW IF EXISTS shelterSkills
DROP VIEW IF EXISTS shelterItems
DROP VIEW IF EXISTS encounterRates
DROP VIEW IF EXISTS sheltersAboveCapacity
DROP PROCEDURE IF EXISTS usp_updateItemValue
DROP PROCEDURE IF EXISTS usp_safePowerDelete
DROP PROCEDURE IF EXISTS usp_safeWaterDelete
DROP PROCEDURE IF EXISTS usp_ItemSearch


-- QUERIES --


/*Check for shelters with a high amounts of cases ​*/
SELECT s.shelter_name, c.city_name, COUNT(*) AS 'total_cases'
FROM Shelter s
JOIN Survivor sv ON sv.shelter_id = s.shelter_id
JOIN DiseaseCase dc ON dc.survivor_id = sv.survivor_id
JOIN City c ON c.city_id = s.city_id
GROUP BY c.city_name, s.shelter_name
HAVING COUNT(*) > 2
ORDER BY COUNT(*) DESC

/*Look for survivors with high amounts of
dangerous encounters with hostile factions​*/
SELECT sv.first_name + ' ' + sv.last_name AS full_name, COUNT(*) AS 'total_hostile_encounters'
FROM Survivor sv
JOIN Survivor_Encounter se ON se.survivor_id = sv.survivor_id
JOIN Encounter e ON e.encounter_id = se.encounter_id
WHERE e.encounter_vibe = 'hostile'
GROUP BY sv.first_name, sv.last_name
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC

/*Look for survivors who have gotten sick multiple
times and survived*/
SELECT sv.first_name + ' ' + sv.last_name AS full_name, COUNT(*) AS 'total_times_infected'
FROM Survivor sv
JOIN DiseaseCase dc ON dc.survivor_id = sv.survivor_id
WHERE sv.status_id = 1
GROUP BY sv.first_name, sv.last_name
HAVING COUNT(*) > 0
ORDER BY COUNT(*)

-- TRIGGERS --

/*Stop resource sites from being deleted and tell
the user to set the site to inactive​*/
GO
CREATE TRIGGER trgResourceSiteDeletion ON ResourceSite INSTEAD OF DELETE AS
	DECLARE @resource_site_id  AS INT = (SELECT resource_site_id FROM deleted);
	UPDATE ResourceSite SET is_operational = 0 WHERE resource_site_id = @resource_site_id; 
	PRINT('Resource Site set to inactive')
GO

--Demostrate
--DELETE FROM ResourceSite WHERE resource_site_id = 19

/*When a disease case is added check that the
survivor does not already an existing case (not
cured)​*/
CREATE TRIGGER trgCheckOngoingCases ON DiseaseCase INSTEAD OF INSERT AS
	DECLARE @survivor_id AS INT = (SELECT survivor_id FROM inserted);
	DECLARE @diagnosis_date AS DATE = (SELECT diagnosis_date FROM inserted);
	DECLARE @cure_date AS DATE = (SELECT cure_date FROM inserted);
	IF EXISTS (SELECT * FROM DiseaseCase dc WHERE dc.survivor_id = @survivor_id AND dc.cure_date IS NULL)
		BEGIN
			PRINT('This survivor already has an ongoing disease case!')
		END
	ELSE
		BEGIN
			INSERT INTO DiseaseCase (survivor_id, diagnosis_date, cure_date) VALUES (@survivor_id, @diagnosis_date, @cure_date);
		END
GO

--Demostrate
--INSERT INTO DiseaseCase (survivor_id, diagnosis_date, cure_date) VALUES (60, '2025-12-12', NULL)

/*Do not allow items that are currency to be
deleted*/
CREATE TRIGGER trgStopDeleteCurrency ON Item INSTEAD OF DELETE AS
	DECLARE @item_id AS INT = (SELECT item_id FROM inserted);
	IF EXISTS (SELECT * FROM Item WHERE item_id=@item_id AND is_currency = 1)
		BEGIN
			PRINT('This item is a currency and should not be deleted!');
		END
	ELSE
		BEGIN
			DELETE FROM Item WHERE item_id=@item_id;
		END

-- VIEWS --

/*Check skills of survivors at each shelter,
including what is absent​*/
GO
CREATE VIEW shelterSkills (shelter_id, shelter_name, skill_name, survivors_with_skill) AS
	SELECT s.shelter_id, s.shelter_name, sk.skill_name, COUNT(ss.survivor_id)
	FROM Shelter s
	CROSS JOIN Skill sk
	LEFT JOIN Survivor sv ON sv.shelter_id = s.shelter_id
	LEFT JOIN Survivor_Skill ss ON ss.survivor_id = sv.survivor_id AND ss.skill_id = sk.skill_id
	GROUP BY s.shelter_id, s.shelter_name, skill_name
GO

SELECT * FROM shelterSkills ORDER BY shelter_id, survivors_with_skill DESC
GO
/*Get a count of the items in each shelters
inventory (by item category)​*/
CREATE VIEW shelterItems (shelter_id, shelter_name, item_category, total_items) AS
	SELECT s.shelter_id, s.shelter_name, i.category, SUM(iv.quantity)
	FROM Shelter s
	CROSS JOIN Item i
	LEFT JOIN Inventory iv ON iv.shelter_id = s.shelter_id AND i.item_id = iv.item_id
	GROUP BY s.shelter_id, s.shelter_name, i.category
GO

SELECT * FROM shelterItems ORDER BY shelter_id, total_items DESC
GO

/*Look for high and low encounter rates in each
city​*/
CREATE VIEW encounterRates (city_name, total_encounters_with_survivors_from_city) AS
	SELECT c.city_name,
		(SELECT COUNT(DISTINCT xse.encounter_id) FROM Survivor_Encounter xse JOIN Survivor sv ON sv.survivor_id = xse.survivor_id JOIN Shelter s ON s.shelter_id = sv.shelter_id WHERE s.city_id = c.city_id)
	FROM City c
GO

SELECT * FROM encounterRates ORDER BY total_encounters_with_survivors_from_city DESC
GO

/*Check for shelters above their capacity*/
CREATE VIEW sheltersAboveCapacity (shelter_id, shelter_name, capacity, total_survivors) AS
	SELECT s.shelter_id, s.shelter_name, s.capacity, COUNT(*)
	FROM Shelter s
	JOIN Survivor sv ON sv.shelter_id = s.shelter_id
	GROUP BY s.shelter_id, s.shelter_name, s.capacity
	HAVING COUNT(*) > capacity
GO

SELECT * FROM sheltersAboveCapacity 
GO
-- STORED PROCEDURES --

/*Updated a items value​*/
CREATE PROCEDURE usp_updateItemValue
@item_id AS INT,
@new_value AS DECIMAL(10,2) AS
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

SELECT * FROM Item WHERE item_id = 1
EXECUTE usp_updateItemValue @item_id = 1, @new_value = 3.99
GO

/*Safe delete procedures for both power and
water sources (ensure they are not assigned a
shelter)​*/
CREATE PROCEDURE usp_safePowerDelete
@power_source_id AS INT AS
IF EXISTS (SELECT * FROM Shelter_Power WHERE power_source_id = @power_source_id)
	BEGIN
		IF EXISTS (SELECT * FROM Shelter_Power WHERE power_source_id=@power_source_id)
			BEGIN
				PRINT('Power source is currently assigned a shelter and cannot be deleted')
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
GO

CREATE PROCEDURE usp_safeWaterDelete
@water_source_id AS INT AS
IF EXISTS (SELECT * FROM Shelter_Water WHERE water_source_id = @water_source_id)
	BEGIN
		IF EXISTS (SELECT * FROM Shelter_Water WHERE water_source_id=@water_source_id)
			BEGIN
				PRINT('Water source is currently assigned a shelter and cannot be deleted')
			END
		ELSE
			BEGIN
				DELETE FROM Shelter_Water WHERE water_source_id = @water_source_id
			END
	END
ELSE
	BEGIN
		PRINT('Water source not found')
	END
GO

/*Dynamic query to look for quantities of an item
type in shelters (with max/min filters)*/

CREATE PROCEDURE usp_ItemSearch
@itemCategory AS NVARCHAR(100) = NULL,
@maxQty AS INT = NULL,
@minQty AS INT = NULL AS
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
		SET @sql += 'AND SUM(iv.quantity) <= ' + CONVERT(NVARCHAR, @maxQty);
	END
IF (@minQty IS NOT NULL)
	BEGIN
		SET @sql += ' AND SUM(iv.quantity) >= ' + CONVERT(NVARCHAR, @minQty);
	END
EXECUTE sp_executesql @sql;


GO
EXECUTE usp_ItemSearch @itemCategory = 'Medical', @maxQty = 10, @minQty = 2