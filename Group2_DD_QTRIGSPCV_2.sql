USE Group2_DD;
GO

--QUERIES--

-- Infection rates by city (different than "high case shelters")
SELECT c.city_name, COUNT(*) AS total_survivors, 
    SUM(CASE WHEN sv.status_id = 3 THEN 1 ELSE 0 END) AS infected_survivors,
    CAST((SUM(CASE WHEN sv.status_id = 3 THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0)*100)AS DECIMAL(5,2)) AS infected_percent
FROM City c
JOIN Shelter s ON s.city_id = c.city_id
JOIN Survivor sv ON sv.shelter_id = s.shelter_id
GROUP BY c.city_name
ORDER BY infected_percent DESC, c.city_name;

-- Factions ranked by number of hostile encounters (uses factions instead of survivors)
SELECT f.faction_name, COUNT(*) AS hostile_encounters
FROM Faction f
JOIN Faction_Encounter fe ON fe.faction_id  = f.faction_id
JOIN Encounter e ON e.encounter_id = fe.encounter_id
WHERE e.encounter_vibe = 'Hostile'
GROUP BY f.faction_name
HAVING COUNT(*) > 0
ORDER BY hostile_encounters DESC, f.faction_name;

-- Top 5 shelters by combined inventory value (quantity * unit_value)
SELECT TOP (5) s.shelter_id, s.shelter_name, SUM(iv.quantity) AS total_quantity, SUM(iv.quantity * i.unit_value) AS total_inventory_value
FROM Shelter s
JOIN Inventory iv ON iv.shelter_id = s.shelter_id
JOIN Item i ON i.item_id = iv.item_id
GROUP BY s.shelter_id, s.shelter_name
ORDER BY total_inventory_value DESC;

-- Survivors who currently have no skills recorded
SELECT sv.survivor_id, sv.first_name, sv.last_name, sv.status_id
FROM Survivor sv
LEFT JOIN Survivor_Skill ss ON ss.survivor_id = sv.survivor_id
WHERE ss.survivor_id IS NULL
ORDER BY sv.last_name, sv.first_name;

-- Shelters that ONLY use 'Prestine' or 'Good' water sources
SELECT s.shelter_id, s.shelter_name, c.city_name
FROM Shelter s
JOIN City c ON c.city_id = s.city_id
JOIN Shelter_Water sw ON sw.shelter_id  = s.shelter_id
JOIN WaterSource w ON w.water_source_id = sw.water_source_id
GROUP BY s.shelter_id, s.shelter_name, c.city_name
HAVING SUM(CASE WHEN w.water_quality NOT IN ('Prestine', 'Good') THEN 1 ELSE 0 END) = 0;

-- For each city, count operational vs non-operational resource sites
SELECT c.city_name, SUM(CASE WHEN rs.is_operational = 1 THEN 1 ELSE 0 END) AS operational_sites,
    SUM(CASE WHEN rs.is_operational = 0 THEN 1 ELSE 0 END) AS non_operational_sites, COUNT(*) AS total_sites
FROM City c
JOIN ResourceSite rs ON rs.city_id = c.city_id
GROUP BY c.city_name
ORDER BY operational_sites DESC, total_sites DESC;

-- Survivors who have 3 or more skills
SELECT sv.survivor_id, sv.first_name, sv.last_name, COUNT(ss.skill_id) AS total_skills
FROM Survivor sv
JOIN Survivor_Skill ss ON ss.survivor_id = sv.survivor_id
GROUP BY sv.survivor_id, sv.first_name, sv.last_name
HAVING COUNT(ss.skill_id) >= 3
ORDER BY total_skills DESC, sv.last_name, sv.first_name;

-- Total quantity and total value of items by category across ALL shelters
SELECT i.category, SUM(iv.quantity) AS total_quantity, SUM(iv.quantity * i.unit_value) AS total_value
FROM Item i
JOIN Inventory iv ON iv.item_id = i.item_id
GROUP BY i.category
ORDER BY total_value DESC;

-- Shelters that have redundancy in power and/or water sources
SELECT s.shelter_id, s.shelter_name, c.city_name, 
    COUNT(DISTINCT sp.power_source_id) AS total_power_sources, COUNT(DISTINCT sw.water_source_id) AS total_water_sources
FROM Shelter s
JOIN City c ON c.city_id = s.city_id
LEFT JOIN Shelter_Power sp ON sp.shelter_id = s.shelter_id
LEFT JOIN Shelter_Water sw ON sw.shelter_id = s.shelter_id
GROUP BY s.shelter_id, s.shelter_name, c.city_name
HAVING (COUNT(DISTINCT sp.power_source_id) > 1 OR COUNT(DISTINCT sw.water_source_id) > 1)
ORDER BY s.shelter_name;

-- Survivors who have at least one skill at proficiency level 3
SELECT sv.survivor_id, sv.first_name, sv.last_name, 
    s.skill_name, MAX(ss.proficiency_level) AS max_proficiency
FROM Survivor sv
JOIN Survivor_Skill ss ON ss.survivor_id = sv.survivor_id
JOIN Skill s ON ss.skill_id = s.skill_id
GROUP BY sv.survivor_id, sv.first_name, sv.last_name, s.skill_name
HAVING MAX(ss.proficiency_level) = 3
ORDER BY sv.last_name, sv.first_name;

-- Pairs of factions that are Friendly AND share the same faction_type
SELECT f1.faction_name AS faction_1, f2.faction_name AS faction_2, f1.faction_type
FROM Faction_Relations fr
JOIN Faction f1 ON f1.faction_id = fr.faction_id_1
JOIN Faction f2 ON f2.faction_id = fr.faction_id_2
WHERE fr.attitude = 'Friendly' AND f1.faction_type = f2.faction_type
ORDER BY f1.faction_type, faction_1, faction_2;

-- Shelters whose city has no 'Medical Salvage' resource site
SELECT s.shelter_id, s.shelter_name, c.city_name
FROM Shelter AS s
JOIN City   AS c ON c.city_id = s.city_id
WHERE NOT EXISTS (
    SELECT 1
    FROM ResourceSite AS rs
    WHERE rs.city_id = c.city_id AND rs.resource_type = 'Medical Salvage'
)
ORDER BY c.city_name, s.shelter_name;


--VIEWS--

DROP VIEW IF EXISTS vShelterInventoryValue;
DROP VIEW IF EXISTS vFactionAttitudeSummary;
DROP VIEW IF EXISTS vSurvivorAgeStatus;
DROP VIEW IF EXISTS vFactionEncounterStats;
GO

-- View: total quantity and total value of items by shelter
CREATE VIEW vShelterInventoryValue
AS
SELECT s.shelter_id, s.shelter_name, SUM(ISNULL(iv.quantity, 0)) AS total_quantity, 
    SUM(ISNULL(iv.quantity * i.unit_value, 0)) AS total_inventory_value
FROM Shelter s
LEFT JOIN Inventory iv ON iv.shelter_id = s.shelter_id
LEFT JOIN Item i ON i.item_id = iv.item_id
GROUP BY s.shelter_id, s.shelter_name;
GO

-- View: count of relationships by attitude for each faction
CREATE VIEW vFactionAttitudeSummary
AS
SELECT f.faction_id, f.faction_name,
    SUM(CASE WHEN fr.attitude = 'Friendly' THEN 1 ELSE 0 END) AS friendly_relations,
    SUM(CASE WHEN fr.attitude = 'Hostile'  THEN 1 ELSE 0 END) AS hostile_relations,
    SUM(CASE WHEN fr.attitude = 'Neutral'  THEN 1 ELSE 0 END) AS neutral_relations,
    SUM(CASE WHEN fr.attitude = 'Unknown'  THEN 1 ELSE 0 END) AS unknown_relations
FROM Faction f
LEFT JOIN Faction_Relations fr ON fr.faction_id_1 = f.faction_id
GROUP BY f.faction_id, f.faction_name;
GO

-- View: survivor age, status, and location
CREATE VIEW vSurvivorAgeStatus
AS
SELECT sv.survivor_id, sv.first_name, sv.last_name, sv.birth_date, 
    DATEDIFF(YEAR, sv.birth_date, GETDATE()) AS age_years,
    st.status_name, s.shelter_id, s.shelter_name, c.city_name
FROM Survivor AS sv
JOIN Status AS st ON st.status_id = sv.status_id
JOIN Shelter AS s ON s.shelter_id = sv.shelter_id
JOIN City AS c ON c.city_id = s.city_id;
GO

-- View: encounter statistics by faction
CREATE VIEW vFactionEncounterStats
AS
SELECT f.faction_id, f.faction_name, f.faction_type, f.faction_attitude AS default_attitude,
    COUNT(DISTINCT fe.encounter_id) AS total_encounters,
    SUM(CASE WHEN e.encounter_vibe = 'Hostile'  THEN 1 ELSE 0 END) AS hostile_encounters,
    SUM(CASE WHEN e.encounter_vibe = 'Neutral'  THEN 1 ELSE 0 END) AS neutral_encounters,
    SUM(CASE WHEN e.encounter_vibe = 'Friendly' THEN 1 ELSE 0 END) AS friendly_encounters
FROM Faction AS f
LEFT JOIN Faction_Encounter AS fe ON fe.faction_id = f.faction_id
LEFT JOIN Encounter AS e ON e.encounter_id = fe.encounter_id
GROUP BY f.faction_id, f.faction_name, f.faction_type, f.faction_attitude;
GO


--PROCEDURES--

DROP PROCEDURE IF EXISTS usp_GetCityShelterSummary;
DROP PROCEDURE IF EXISTS usp_GetSurvivorProfile;
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

    SELECT s.shelter_id, s.shelter_name, s.capacity, COUNT(sv.survivor_id) AS total_survivors,
        s.capacity - COUNT(sv.survivor_id) AS open_beds,
        SUM(CASE WHEN sv.status_id = @InfectedStatusId THEN 1 ELSE 0 END) AS infected_survivors
    FROM City c
    JOIN Shelter s ON s.city_id = c.city_id
    LEFT JOIN Survivor sv ON sv.shelter_id = s.shelter_id
    WHERE c.city_name = @CityName
    GROUP BY s.shelter_id, s.shelter_name, s.capacity
    ORDER BY s.shelter_name;
END;
GO

-- Get a single survivor's overall profile: status, disease cases, encounters
CREATE PROCEDURE usp_GetSurvivorProfile
    @SurvivorId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT sv.survivor_id, sv.first_name, sv.last_name, sv.birth_date, st.status_name,
        COUNT(DISTINCT dc.disease_case_id) AS total_disease_cases,
        SUM(CASE WHEN dc.cure_date IS NULL THEN 1 ELSE 0 END) AS open_disease_cases,
        COUNT(DISTINCT se.encounter_id) AS total_encounters,
        SUM(CASE WHEN e.encounter_vibe = 'Hostile' THEN 1 ELSE 0 END) AS hostile_encounters
    FROM Survivor sv
    JOIN Status st ON st.status_id = sv.status_id
    LEFT JOIN DiseaseCase dc ON dc.survivor_id = sv.survivor_id
    LEFT JOIN Survivor_Encounter se ON se.survivor_id = sv.survivor_id
    LEFT JOIN Encounter e ON e.encounter_id = se.encounter_id
    WHERE sv.survivor_id = @SurvivorId
    GROUP BY sv.survivor_id, sv.first_name, sv.last_name, sv.birth_date, st.status_name;
END;
GO

--TRIGGERS--

DROP TRIGGER IF EXISTS trgPreventNegativeInventory;
DROP TRIGGER IF EXISTS trgValidateShelterCapacity;
GO

-- Prevent negative quantities in Inventory
CREATE TRIGGER trgPreventNegativeInventory
ON Inventory
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM inserted WHERE quantity < 0)
    BEGIN
        RAISERROR ('Inventory quantity cannot be negative.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- Make sure we don't exceed a shelter's capacity
CREATE TRIGGER trgValidateShelterCapacity
ON Survivor
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM Shelter s
        JOIN (
            SELECT shelter_id, COUNT(*) AS current_survivors
            FROM Survivor
            WHERE shelter_id IS NOT NULL
            GROUP BY shelter_id
        ) x ON x.shelter_id = s.shelter_id
        JOIN inserted i ON i.shelter_id = s.shelter_id
        WHERE x.current_survivors > s.capacity
    )
    BEGIN
        RAISERROR ('Shelter capacity exceeded. Cannot assign more survivors to this shelter.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO