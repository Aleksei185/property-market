DROP TABLE IF EXISTS nashville_housing;

CREATE TABLE nashville_housing (
    unique_id        INTEGER,
    parcel_id        TEXT,
    land_use         TEXT,
    property_address TEXT,
    sale_date        TEXT,
    sale_price       BIGINT,
    legal_reference  TEXT,
    sold_as_vacant   TEXT,
    owner_name       TEXT,
    owner_address    TEXT,
    acreage          TEXT,
    tax_district     TEXT,
    land_value       NUMERIC,
    building_value   NUMERIC,
    total_value      NUMERIC,
    year_built       NUMERIC,
    bedrooms         NUMERIC,
    full_bath        NUMERIC,
    half_bath        NUMERIC
);

-- Преобразование даты из текста в формат DATE

ALTER TABLE nashville_housing ADD COLUMN sale_date_new DATE;

UPDATE nashville_housing
SET sale_date_new = TO_DATE(sale_date, 'Month DD, YYYY')
WHERE sale_date IS NOT NULL
  AND sale_date != ''
  AND sale_date != 'NaN';

ALTER TABLE nashville_housing DROP COLUMN sale_date;

ALTER TABLE nashville_housing RENAME COLUMN sale_date_new TO sale_date;

-- Заполнение пропусков в property_address через self-join

UPDATE nashville_housing AS a
SET property_address = b.property_address
FROM nashville_housing AS b
WHERE a.parcel_id = b.parcel_id
  AND a.property_address IS NULL
  AND b.property_address IS NOT NULL
  AND b.property_address != ''
  AND b.property_address != 'NaN';

-- Разбиение адреса на Street и City

ALTER TABLE nashville_housing
ADD COLUMN property_street TEXT,
ADD COLUMN property_city TEXT;

UPDATE nashville_housing
SET property_street = TRIM(SPLIT_PART(property_address, ',', 1)),
    property_city   = TRIM(SPLIT_PART(property_address, ',', 2))
WHERE property_address IS NOT NULL
  AND property_address != ''
  AND property_address != 'NaN';

-- Приведение sold_as_vacant к единому виду

UPDATE nashville_housing
SET sold_as_vacant = CASE
    WHEN sold_as_vacant = 'Y' THEN 'Yes'
    WHEN sold_as_vacant = 'N' THEN 'No'
    ELSE sold_as_vacant
END;

-- Удаление дубликатов


WITH duplicates AS (
    SELECT
        unique_id,
        ROW_NUMBER() OVER (
            PARTITION BY parcel_id, property_address, sale_price, sale_date, legal_reference
            ORDER BY unique_id
        ) AS row_num
    FROM nashville_housing
)
DELETE FROM nashville_housing
WHERE unique_id IN (
    SELECT unique_id FROM duplicates WHERE row_num > 1
);

-- Приведение acreage к числовому типу

UPDATE nashville_housing
SET acreage = REPLACE(acreage, ',', '.')
WHERE acreage IS NOT NULL
  AND acreage != ''
  AND acreage != 'NaN';

ALTER TABLE nashville_housing
ALTER COLUMN acreage TYPE NUMERIC
USING acreage::NUMERIC;

FROM nashville_housing;
