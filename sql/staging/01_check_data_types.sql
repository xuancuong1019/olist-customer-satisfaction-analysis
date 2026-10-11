/*Checking data types in detailed*/

DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql = @sql +
    CASE WHEN @sql = N'' THEN N'' ELSE N'
UNION ALL
' END +
    N'SELECT ' +
    QUOTENAME(TABLE_NAME, '''') + N' AS table_name, ' +
    QUOTENAME(COLUMN_NAME, '''') + N' AS column_name, ' +
    N'COUNT(*) AS total_rows, ' +
    N'COUNT(' + QUOTENAME(COLUMN_NAME) + N') AS non_null_rows, ' +
    N'MAX(LEN(' + QUOTENAME(COLUMN_NAME) + N')) AS max_length, ' +
    N'MAX(DATALENGTH(' + QUOTENAME(COLUMN_NAME) + N')) AS max_bytes ' +
    N'FROM staging.' + QUOTENAME(TABLE_NAME)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'staging'
  AND DATA_TYPE IN ('varchar', 'nvarchar', 'char', 'nchar')
ORDER BY TABLE_NAME, ORDINAL_POSITION;

SET @sql = N'SELECT * FROM (' + @sql + N') AS stats
ORDER BY table_name, column_name;';

EXEC sp_executesql @sql;

/*Checking duplicates on olist_geolocation*/
SELECT
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state,
    COUNT(*) AS duplicate_count
FROM staging.olist_geolocation
GROUP BY
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
HAVING COUNT(*) > 1;


/*Checking (order_id, product_id) PK in order_items*/
SELECT
    order_id,
    product_id,
    COUNT(*) AS duplicate_count
FROM staging.olist_order_items
GROUP BY order_id, product_id
HAVING COUNT(*) > 1;

/*Checking (order_id, order_item_id) as PK in order_items*/
SELECT
    order_id,
    order_item_id,
    COUNT(*) AS duplicate_count
FROM staging.olist_order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;




