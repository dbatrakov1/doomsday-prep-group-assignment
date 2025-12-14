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


/* =========================================
   QUERIES
   ========================================= */


/*Check for shelters with a high amounts of cases -
Allows us to identify potential outbreaks and allocate resources accordingly ​*/
SELECT
	s.shelter_id,
    s.shelter_name,
    COUNT(*) AS total_survivors,
    SUM(CASE WHEN sv.status_id = 3 THEN 1 ELSE 0 END) AS infected_survivors,
    CAST(
        100.0 * SUM(CASE WHEN sv.status_id = 3 THEN 1 ELSE 0 END) 
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(5,2)
    ) AS infected_percent
FROM Shelter s
JOIN Survivor sv ON sv.shelter_id = s.shelter_id
GROUP BY s.shelter_name, s.shelter_id
ORDER BY infected_percent DESC, s.shelter_name;

/*Look for survivors with high amounts of dangerous encounters with hostile factions -
Allows us to find individuals with experience that could fill leadership positions if needed*/
SELECT sv.first_name + ' ' + sv.last_name AS full_name, COUNT(*) AS 'total_hostile_encounters'
FROM Survivor sv
JOIN Survivor_Encounter se ON se.survivor_id = sv.survivor_id
JOIN Encounter e ON e.encounter_id = se.encounter_id
WHERE e.encounter_vibe = 'hostile'
GROUP BY sv.first_name, sv.last_name
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC

/*Look for survivors who have gotten sick multiple times and survived - 
Gives our researchers a lead on curing the disease by identifying successful recoveries*/
SELECT sv.first_name + ' ' + sv.last_name AS full_name, COUNT(*) AS 'total_times_infected'
FROM Survivor sv
JOIN DiseaseCase dc ON dc.survivor_id = sv.survivor_id
WHERE sv.status_id = 1
GROUP BY sv.first_name, sv.last_name
HAVING COUNT(*) > 0
ORDER BY COUNT(*)

/*Infection rates by city (different than "high case shelters") - 
Allows us to identify disease hot spots and what cities are safest*/
SELECT 
    c.city_name,
    COUNT(*) AS total_survivors,
    SUM(CASE WHEN sv.status_id = 3 THEN 1 ELSE 0 END) AS infected_survivors,
    CAST(
        100.0 * SUM(CASE WHEN sv.status_id = 3 THEN 1 ELSE 0 END) 
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(5,2)
    ) AS infected_percent
FROM City c
JOIN Shelter s   ON s.city_id     = c.city_id
JOIN Survivor sv ON sv.shelter_id = s.shelter_id
GROUP BY c.city_name
ORDER BY infected_percent DESC, c.city_name;

/*Factions ranked by number of hostile encounters (uses factions instead of survivors) -
Allows us to identify dangerous factions that we should avoid interacting with*/
SELECT 
    f.faction_name,
    COUNT(*) AS hostile_encounters
FROM Faction f
JOIN Faction_Encounter fe ON fe.faction_id  = f.faction_id
JOIN Encounter e          ON e.encounter_id = fe.encounter_id
WHERE e.encounter_vibe = 'Hostile'
GROUP BY f.faction_name
HAVING COUNT(*) > 0
ORDER BY hostile_encounters DESC, f.faction_name;

/*Top 5 shelters by combined inventory value (quantity * unit_value) -
Identifies high value locations that should have increased security presence*/
SELECT TOP (5)
    s.shelter_id,
    s.shelter_name,
    SUM(iv.quantity) AS total_quantity,
    SUM(iv.quantity * i.unit_value) AS total_inventory_value
FROM Shelter s
JOIN Inventory iv ON iv.shelter_id = s.shelter_id
JOIN Item i       ON i.item_id     = iv.item_id
GROUP BY s.shelter_id, s.shelter_name
ORDER BY total_inventory_value DESC;

/* Survivors who currently have no skills recorded -
Identifies survivors that would benefit the most from training*/
SELECT 
    sv.survivor_id,
    sv.first_name,
    sv.last_name,
    sv.status_id
FROM Survivor sv
LEFT JOIN Survivor_Skill ss ON ss.survivor_id = sv.survivor_id
WHERE ss.survivor_id IS NULL
ORDER BY sv.last_name, sv.first_name;

/* Shelters that ONLY use 'Pristine' or 'Good' water sources -
Identifies shelters with the best water supplies, good places to send sick survivors to*/
SELECT 
    s.shelter_id,
    s.shelter_name,
    c.city_name
FROM Shelter s
JOIN City c           ON c.city_id      = s.city_id
JOIN Shelter_Water sw ON sw.shelter_id  = s.shelter_id
JOIN WaterSource w    ON w.water_source_id = sw.water_source_id
GROUP BY s.shelter_id, s.shelter_name, c.city_name
HAVING 
    SUM(CASE WHEN w.water_quality NOT IN ('Pristine', 'Good') THEN 1 ELSE 0 END) = 0;

/* For each city, count operational vs non-operational resource sites -
Shows where resources are plentiful and sparse, good for coordinating moving resources between shelters*/
SELECT 
    c.city_name,
    SUM(CASE WHEN rs.is_operational = 1 THEN 1 ELSE 0 END) AS operational_sites,
    SUM(CASE WHEN rs.is_operational = 0 THEN 1 ELSE 0 END) AS non_operational_sites,
    COUNT(*) AS total_sites
FROM City c
JOIN ResourceSite rs ON rs.city_id = c.city_id
GROUP BY c.city_name
ORDER BY operational_sites DESC, total_sites DESC;

/* Survivors who have 3 or more skills -
Identifies survivors that could be good in leadership positions*/
SELECT 
    sv.survivor_id,
    sv.first_name,
    sv.last_name,
    COUNT(ss.skill_id) AS total_skills
FROM Survivor sv
JOIN Survivor_Skill ss ON ss.survivor_id = sv.survivor_id
GROUP BY sv.survivor_id, sv.first_name, sv.last_name
HAVING COUNT(ss.skill_id) >= 3
ORDER BY total_skills DESC, sv.last_name, sv.first_name;

/* Total quantity and total value of items by category across ALL shelters -
Shows where we hold our value, good for knowing what we are lacking and should try to acquire from other factions*/
SELECT 
    i.category,
    SUM(iv.quantity) AS total_quantity,
    SUM(iv.quantity * i.unit_value) AS total_value
FROM Item i
JOIN Inventory iv ON iv.item_id = i.item_id
GROUP BY i.category
ORDER BY total_value DESC;

/* Shelters that have redundancy in power and/or water sources -
Identifies shelters that have reliable water and power, good places to research at and move infected survivors*/
SELECT 
    s.shelter_id,
    s.shelter_name,
    c.city_name,
    COUNT(DISTINCT sp.power_source_id) AS total_power_sources,
    COUNT(DISTINCT sw.water_source_id) AS total_water_sources
FROM Shelter s
JOIN City c               ON c.city_id      = s.city_id
LEFT JOIN Shelter_Power sp ON sp.shelter_id = s.shelter_id
LEFT JOIN Shelter_Water sw ON sw.shelter_id = s.shelter_id
GROUP BY s.shelter_id, s.shelter_name, c.city_name
HAVING 
      COUNT(DISTINCT sp.power_source_id) > 1
   OR COUNT(DISTINCT sw.water_source_id) > 1
ORDER BY s.shelter_name;

/* Survivors who have at least one skill at proficiency level 3 -
Identifies the best survivors for training others*/
SELECT 
    sv.survivor_id,
    sv.first_name,
    sv.last_name,
    MAX(ss.proficiency_level) AS max_proficiency
FROM Survivor sv
JOIN Survivor_Skill ss ON ss.survivor_id = sv.survivor_id
GROUP BY sv.survivor_id, sv.first_name, sv.last_name
HAVING MAX(ss.proficiency_level) = 3
ORDER BY sv.last_name, sv.first_name;

/* Pairs of factions that are Friendly AND share the same faction_type -
Shows other factions with strong alliances, and might perform actions together (with or against us)*/
SELECT 
    f1.faction_name AS faction_1,
    f2.faction_name AS faction_2,
    f1.faction_type
FROM Faction_Relations fr
JOIN Faction f1 ON f1.faction_id = fr.faction_id_1
JOIN Faction f2 ON f2.faction_id = fr.faction_id_2
WHERE fr.attitude = 'Friendly'
  AND f1.faction_type = f2.faction_type
ORDER BY f1.faction_type, faction_1, faction_2;

/* Shelters whose city has no 'Medical Salvage' resource site -
Shows where medical supplies need to be brought to*/
SELECT 
    s.shelter_id,
    s.shelter_name,
    c.city_name
FROM Shelter AS s
JOIN City   AS c ON c.city_id = s.city_id
WHERE NOT EXISTS (
    SELECT 1
    FROM ResourceSite AS rs
    WHERE rs.city_id = c.city_id
      AND rs.resource_type = 'Medical Salvage'
)
ORDER BY c.city_name, s.shelter_name;
