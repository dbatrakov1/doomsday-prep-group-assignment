BULK INSERT --Table
FROM --path to file needs to be a csv
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2
);