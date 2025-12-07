--[TABLE Creation Statements Here]
/*USE master

DROP DATABASE IF EXISTS Group2_DD;
GO
CREATE DATABASE Group2_DD;
GO*/
USE Group2_DD;
GO

DROP TABLE IF EXISTS Survivor_Encounter;
DROP TABLE IF EXISTS Faction_Encounter;
DROP TABLE IF EXISTS Shelter_Water;
DROP TABLE IF EXISTS Shelter_Power;
DROP TABLE IF EXISTS Inventory;
DROP TABLE IF EXISTS Faction_Relations;
DROP TABLE IF EXISTS Survivor_Skill;

DROP TABLE IF EXISTS DiseaseCase;
DROP TABLE IF EXISTS Survivor;
DROP TABLE IF EXISTS Encounter;
DROP TABLE IF EXISTS Faction;
DROP TABLE IF EXISTS ResourceSite;
DROP TABLE IF EXISTS Item;
DROP TABLE IF EXISTS Skill;
DROP TABLE IF EXISTS Status;
DROP TABLE IF EXISTS Shelter;
DROP TABLE IF EXISTS WaterSource;
DROP TABLE IF EXISTS PowerSource;
DROP TABLE IF EXISTS City;
--[Tables]
CREATE TABLE City (
    city_id INT IDENTITY(1,1) PRIMARY KEY,
    city_name NVARCHAR(100) NOT NULL,
    state CHAR(2)
);

CREATE TABLE PowerSource (
    power_source_id INT IDENTITY(1,1) PRIMARY KEY,
    power_source_name NVARCHAR(100) NOT NULL,
    power_source_description NVARCHAR(500),
    is_active BIT NOT NULL,
    transportable BIT NOT NULL
);

CREATE TABLE WaterSource (
    water_source_id INT IDENTITY(1,1) PRIMARY KEY,
    water_source_name NVARCHAR(100) NOT NULL,
    water_source_description NVARCHAR(500),
    water_quality NVARCHAR(100) NOT NULL,
);

CREATE TABLE Shelter (
    shelter_id INT IDENTITY(1,1) PRIMARY KEY,
    city_id INT NOT NULL,
    shelter_name NVARCHAR(100) NOT NULL UNIQUE,
    capacity INT,
    FOREIGN KEY (city_id) REFERENCES City(city_id)
);

CREATE TABLE Status (
    status_id INT IDENTITY(1,1) PRIMARY KEY,
    status_name NVARCHAR(100) NOT NULL
);

CREATE TABLE Survivor (
    survivor_id INT IDENTITY(1,1) PRIMARY KEY,
    shelter_id INT NOT NULL,
    first_name NVARCHAR(100) NOT NULL,
    last_name NVARCHAR(100) NOT NULL,
    birth_date DATE,
    status_id INT,
    FOREIGN KEY (shelter_id) REFERENCES Shelter(shelter_id),
    FOREIGN KEY (status_id)  REFERENCES Status(status_id)
);

CREATE TABLE Skill (
    skill_id INT IDENTITY(1,1) PRIMARY KEY,
    skill_name NVARCHAR(100) NOT NULL UNIQUE,
    skill_description NVARCHAR(500)
);

CREATE TABLE DiseaseCase (
    disease_case_id INT IDENTITY(1,1) PRIMARY KEY,
    survivor_id INT NOT NULL,
    diagnosis_date DATE     NOT NULL,
    cure_date DATE,
    FOREIGN KEY (survivor_id) REFERENCES Survivor(survivor_id)
);

CREATE TABLE Item (
    item_id INT IDENTITY(1,1) PRIMARY KEY,
    item_name NVARCHAR(100) NOT NULL UNIQUE,
    category NVARCHAR(100) NOT NULL,
    is_currency BIT NOT NULL DEFAULT 0,
    unit_value DECIMAL(10,2)
);

CREATE TABLE ResourceSite (
    resource_site_id INT IDENTITY(1,1) PRIMARY KEY,
    city_id INT NOT NULL,
    resource_type NVARCHAR(100) NOT NULL,
    resource_name NVARCHAR(100) NOT NULL,
    resource_description NVARCHAR(500),
    is_operational BIT NOT NULL DEFAULT 1,
    FOREIGN KEY (city_id) REFERENCES City(city_id)
);

CREATE TABLE Faction (
    faction_id INT IDENTITY(1,1) PRIMARY KEY,
    faction_name NVARCHAR(100) NOT NULL UNIQUE,
    faction_type NVARCHAR(100) NOT NULL,
    faction_attitude NVARCHAR(100)
);

CREATE TABLE Encounter (
    encounter_id INT IDENTITY(1,1) PRIMARY KEY,
    encounter_date DATE NOT NULL,
    encounter_type NVARCHAR(100) NOT NULL,
    encounter_vibe NVARCHAR(100) NOT NULL,
    encounter_description NVARCHAR(500)
);

--[Junction Tables]

CREATE TABLE Faction_Relations (
    faction_id_1 INT NOT NULL,
    faction_id_2 INT NOT NULL,
    attitude NVARCHAR(100),
    PRIMARY KEY (faction_id_1, faction_id_2),
    FOREIGN KEY (faction_id_1) REFERENCES Faction(faction_id),
    FOREIGN KEY (faction_id_2) REFERENCES Faction(faction_id)
);

CREATE TABLE Inventory (
    item_id INT NOT NULL,
    shelter_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 0,
    PRIMARY KEY (item_id, shelter_id),
    FOREIGN KEY (item_id)    REFERENCES Item(item_id),
    FOREIGN KEY (shelter_id) REFERENCES Shelter(shelter_id)
);

CREATE TABLE Shelter_Power (
    shelter_id INT NOT NULL,
    power_source_id INT NOT NULL,
    PRIMARY KEY (shelter_id, power_source_id),
    FOREIGN KEY (shelter_id)      REFERENCES Shelter(shelter_id),
    FOREIGN KEY (power_source_id) REFERENCES PowerSource(power_source_id)
);

CREATE TABLE Shelter_Water (
    shelter_id INT NOT NULL,
    water_source_id INT NOT NULL,
    PRIMARY KEY (shelter_id, water_source_id),
    FOREIGN KEY (shelter_id)      REFERENCES Shelter(shelter_id),
    FOREIGN KEY (water_source_id) REFERENCES WaterSource(water_source_id)
);

CREATE TABLE Survivor_Encounter (
    encounter_id INT NOT NULL,
    survivor_id  INT NOT NULL,
    PRIMARY KEY (encounter_id, survivor_id),
    FOREIGN KEY (encounter_id) REFERENCES Encounter(encounter_id),
    FOREIGN KEY (survivor_id)  REFERENCES Survivor(survivor_id)
);

CREATE TABLE Faction_Encounter (
    encounter_id INT NOT NULL,
    faction_id INT NOT NULL,
    PRIMARY KEY (encounter_id, faction_id),
    FOREIGN KEY (encounter_id) REFERENCES Encounter(encounter_id),
    FOREIGN KEY (faction_id)   REFERENCES Faction(faction_id)
);

CREATE TABLE Survivor_Skill (
    survivor_id INT NOT NULL,
    skill_id INT NOT NULL,
    proficiency_level INT,
    PRIMARY KEY (survivor_id, skill_id),
    FOREIGN KEY (survivor_id) REFERENCES Survivor(survivor_id),
    FOREIGN KEY (skill_id)    REFERENCES Skill(skill_id)
);