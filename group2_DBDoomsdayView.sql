USE Group2_DD;

DROP VIEW IF EXISTS shelterSkills
DROP VIEW IF EXISTS shelterItems
DROP VIEW IF EXISTS encounterRates
DROP VIEW IF EXISTS sheltersAboveCapacity
DROP VIEW IF EXISTS vShelterInventoryValue;
DROP VIEW IF EXISTS vFactionAttitudeSummary;
DROP VIEW IF EXISTS vSurvivorAgeStatus;
DROP VIEW IF EXISTS vFactionEncounterStats;


/* =========================================
   VIEWS
   ========================================= */

/*Check skills of survivors at each shelter, including what is absent​*/
GO
CREATE VIEW shelterSkills (shelter_id, shelter_name, skill_name, survivors_with_skill) AS
	SELECT s.shelter_id, s.shelter_name, sk.skill_name, COUNT(ss.survivor_id)
	FROM Shelter s
	CROSS JOIN Skill sk
	LEFT JOIN Survivor sv ON sv.shelter_id = s.shelter_id
	LEFT JOIN Survivor_Skill ss ON ss.survivor_id = sv.survivor_id AND ss.skill_id = sk.skill_id
	GROUP BY s.shelter_id, s.shelter_name, sk.skill_name
GO

-- Helps with moving survivors to shelters where their skills are needed
SELECT * FROM shelterSkills ORDER BY shelter_id, survivors_with_skill DESC
GO

/*Get a count of the items in each shelter’s inventory (by item category)​*/
CREATE VIEW shelterItems (shelter_id, shelter_name, item_category, total_items) AS
	SELECT s.shelter_id, s.shelter_name, i.category, SUM(iv.quantity)
	FROM Shelter s
	CROSS JOIN Item i
	LEFT JOIN Inventory iv ON iv.shelter_id = s.shelter_id AND i.item_id = iv.item_id
	GROUP BY s.shelter_id, s.shelter_name, i.category
GO

-- Helps know what shelters need, shows where we can allocate the resources from or if they would be better to trade with other factions for it
SELECT * FROM shelterItems ORDER BY item_category, total_items DESC
GO

/*Look for high and low encounter rates in cities​*/
CREATE VIEW encounterRates (city_name, total_encounters_with_survivors_from_city) AS
	SELECT c.city_name,
		(SELECT COUNT(DISTINCT xse.encounter_id) FROM Survivor_Encounter xse JOIN Survivor sv ON sv.survivor_id = xse.survivor_id JOIN Shelter s ON s.shelter_id = sv.shelter_id WHERE s.city_id = c.city_id)
	FROM City c
GO

-- Shows what cities survivors have the most encounters with other factions, where other factions are most present
SELECT * FROM encounterRates ORDER BY total_encounters_with_survivors_from_city DESC
GO

/*Check for shelters above their capacity*/
CREATE VIEW sheltersAboveCapacity (shelter_id, shelter_name, capacity, total_survivors) AS
	SELECT s.shelter_id, s.shelter_name, s.capacity, COUNT(*)
	FROM Shelter s
	JOIN Survivor sv ON sv.shelter_id = s.shelter_id
	WHERE sv.status_id != 4
	GROUP BY s.shelter_id, s.shelter_name, s.capacity
	HAVING COUNT(*) > capacity
GO

-- Shows shelters that either need more resources to increase capacity, or should send survivors to different shelters
SELECT * FROM sheltersAboveCapacity 
GO

-- View: total quantity and total value of items by shelter
CREATE VIEW vShelterInventoryValue
AS
SELECT 
    s.shelter_id,
    s.shelter_name,
    SUM(ISNULL(iv.quantity, 0))                AS total_quantity,
    SUM(ISNULL(iv.quantity * i.unit_value, 0)) AS total_inventory_value
FROM Shelter s
LEFT JOIN Inventory iv ON iv.shelter_id = s.shelter_id
LEFT JOIN Item i       ON i.item_id     = iv.item_id
GROUP BY s.shelter_id, s.shelter_name;
GO

-- Identifies the most valuable shelters, helps allocate security where it is most needed
SELECT * FROM vShelterInventoryValue ORDER BY total_inventory_value DESC

GO

-- View: count of relationships by attitude for each faction
CREATE VIEW vFactionAttitudeSummary
AS
SELECT 
    f.faction_id,
    f.faction_name,
    SUM(CASE WHEN fr.attitude = 'Friendly' THEN 1 ELSE 0 END) AS friendly_relations,
    SUM(CASE WHEN fr.attitude = 'Hostile'  THEN 1 ELSE 0 END) AS hostile_relations,
    SUM(CASE WHEN fr.attitude = 'Neutral'  THEN 1 ELSE 0 END) AS neutral_relations,
    SUM(CASE WHEN fr.attitude = 'Unknown'  THEN 1 ELSE 0 END) AS unknown_relations
FROM Faction f
LEFT JOIN Faction_Relations fr 
       ON fr.faction_id_1 = f.faction_id
GROUP BY f.faction_id, f.faction_name;
GO

-- Shows what factions are most friendly and most hostile, good for knowing who to interact with
SELECT * FROM vFactionAttitudeSummary ORDER BY friendly_relations DESC

GO

-- View: survivor age, status, and location
CREATE VIEW vSurvivorAgeStatus
AS
SELECT
    sv.survivor_id,
    sv.first_name,
    sv.last_name,
    sv.birth_date,
    DATEDIFF(YEAR, sv.birth_date, (GETDATE() + YEAR(5))) AS age_years,
    st.status_name,
    s.shelter_id,
    s.shelter_name,
    c.city_name
FROM Survivor AS sv
JOIN Status  AS st ON st.status_id = sv.status_id
JOIN Shelter AS s  ON s.shelter_id = sv.shelter_id
JOIN City    AS c  ON c.city_id    = s.city_id;
GO

-- Give a complete view of every survivor that are at shelters, good for moving survivors to shelters with low occupancy
-- *Note: added 5 years to current date because we are setting this in the future*
SELECT * FROM vSurvivorAgeStatus ORDER BY shelter_name, status_name
GO

-- View: encounter statistics by faction
CREATE VIEW vFactionEncounterStats
AS
SELECT
    f.faction_id,
    f.faction_name,
    f.faction_type,
    f.faction_attitude AS default_attitude,
    COUNT(DISTINCT fe.encounter_id) AS total_encounters,
    SUM(CASE WHEN e.encounter_vibe = 'Hostile'  THEN 1 ELSE 0 END) AS hostile_encounters,
    SUM(CASE WHEN e.encounter_vibe = 'Neutral'  THEN 1 ELSE 0 END) AS neutral_encounters,
    SUM(CASE WHEN e.encounter_vibe = 'Friendly' THEN 1 ELSE 0 END) AS friendly_encounters
FROM Faction AS f
LEFT JOIN Faction_Encounter AS fe ON fe.faction_id   = f.faction_id
LEFT JOIN Encounter          AS e  ON e.encounter_id = fe.encounter_id
GROUP BY 
    f.faction_id,
    f.faction_name,
    f.faction_type,
    f.faction_attitude;
GO

-- Helps ensure our attitude to other factions stays accurate with our interactions with them
SELECT * FROM vFactionEncounterStats ORDER BY default_attitude
