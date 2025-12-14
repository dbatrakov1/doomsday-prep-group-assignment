USE Group2_DD;

DROP TRIGGER IF EXISTS trgResourceSiteDeletion
DROP TRIGGER IF EXISTS trgCheckOngoingCases
DROP TRIGGER IF EXISTS trgStopDeleteCurrency
DROP TRIGGER IF EXISTS trgPreventNegativeInventory;
DROP TRIGGER IF EXISTS trgValidateShelterCapacity;


/* =========================================
   TRIGGERS
   ========================================= */


/*Stop resource sites from being deleted and tell
the user to set the site to inactive​*/
GO
CREATE TRIGGER trgResourceSiteDeletion ON ResourceSite INSTEAD OF DELETE AS
	DECLARE @resource_site_id  AS INT = (SELECT resource_site_id FROM deleted);
	UPDATE ResourceSite SET is_operational = 0 WHERE resource_site_id = @resource_site_id; 
	RAISERROR ('Resource Site set to inactive', 16, 1);
GO

--Demostrate - Stops resource sites from being deleted, these are locations and do not just disappear, they go inactive
DELETE FROM ResourceSite WHERE resource_site_id = 19
SELECT * FROM ResourceSite WHERE resource_site_id = 19
GO

/*When a disease case is added check that the
survivor does not already an existing case (not
cured)​*/
CREATE TRIGGER trgCheckOngoingCases ON DiseaseCase INSTEAD OF INSERT AS
	DECLARE @survivor_id AS INT = (SELECT survivor_id FROM inserted);
	DECLARE @diagnosis_date AS DATE = (SELECT diagnosis_date FROM inserted);
	DECLARE @cure_date AS DATE = (SELECT cure_date FROM inserted);
	IF EXISTS (SELECT * FROM DiseaseCase dc WHERE dc.survivor_id = @survivor_id AND dc.cure_date IS NULL)
		BEGIN
			RAISERROR ('This survivor already has an ongoing disease case!', 16, 1);
		END
	ELSE
		BEGIN
			INSERT INTO DiseaseCase (survivor_id, diagnosis_date, cure_date) VALUES (@survivor_id, @diagnosis_date, @cure_date);
		END
GO

--Demostrate - A survivor can't get a case of the disease when they already have it. 
INSERT INTO DiseaseCase (survivor_id, diagnosis_date, cure_date) VALUES (60, '2025-12-12', NULL)
INSERT INTO DiseaseCase (survivor_id, diagnosis_date, cure_date) VALUES (62, '2025-12-12', NULL)
SELECT * FROM DiseaseCase WHERE survivor_id = 60
GO

/*Do not allow items that are currency to be
deleted*/
CREATE TRIGGER trgStopDeleteCurrency ON Item INSTEAD OF DELETE AS
	DECLARE @item_id AS INT = (SELECT item_id FROM deleted);
	IF EXISTS (SELECT * FROM Item WHERE item_id=@item_id AND is_currency = 1)
		BEGIN
			RAISERROR('This item is a currency and should not be deleted!', 16, 1);
		END
	ELSE
		BEGIN
			DELETE FROM Item WHERE item_id=@item_id;
		END
GO

--Demostrate - We do not want to stop tracking items that can be traded with other factions as currency
SELECT * FROM Item WHERE is_currency = 1
DELETE FROM Item WHERE item_id = 21
GO

-- Prevent negative quantities in Inventory
CREATE TRIGGER trgPreventNegativeInventory
ON Inventory
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 
        FROM inserted
        WHERE quantity < 0
    )
    BEGIN
        RAISERROR ('Inventory quantity cannot be negative.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

--Demostrate - It is not possible to possess negative items in a shelters inventory.
INSERT INTO Inventory (item_id, shelter_id, quantity) VALUES (10, 10, -1);
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

--Demostrate - We do not want new survivors sent to shelters that cannot handle them
SELECT s.shelter_id FROM Shelter s WHERE s.capacity < (SELECT COUNT(*) FROM Survivor sv WHERE sv.shelter_id = s.shelter_id AND sv.status_id != 4)
INSERT INTO Survivor (first_name, last_name, shelter_id, status_id) VALUES ('John', 'Doe', 1, 1)