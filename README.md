## Project Overview
**Project Title**: Weather App data pipeline in Snowflake

**Database**: `Tasty_Bytes`

Weather Application Data Pipeline is an end-to-end cloud data engineering project that demonstrates a modern ELT workflow using Amazon S3, Snowflake, and Streamlit. Raw weather data from the Pelmorex Weather Dataset is first stored in Amazon S3, then ingested and transformed within Snowflake to create analytics-ready datasets. Finally, the processed data is served through an interactive Streamlit application, enabling users to explore weather trends and insights through a web-based interface.

This project showcases key data engineering concepts including cloud storage integration, data warehousing, SQL-based transformations, and interactive data application development. It highlights how Snowflake can be used as a scalable analytics platform while Streamlit provides a lightweight interface for publishing analytical insights.

<img src="Visualization.png" alt="Weather App Visualization" width="800">

## Objectives
1. Build an End-to-End ELT Pipeline: Design and implement a cloud-based data pipeline that ingests raw weather data from Amazon S3 into Snowflake for centralized storage and processing.
2. Transform and Model Weather Data: Clean, transform, and structure raw weather data in Snowflake to create analytics-ready datasets using SQL.
3. Develop an Interactive Weather Application: Publish the processed weather data through a Streamlit application, enabling users to explore weather conditions and insights via an interactive web interface.

## Project Structure

### 1. Database setup & CSV Creation
```sql
-- Set role to ACCOUNTADMIN, and set compute resource (virtual warehouse) to COMPUTE_WH.
CREATE OR REPLACE DATABASE tasty_bytes;
CREATE OR REPLACE SCHEMA raw_pos;
````
### 2. Ingestion of Data from S3 to Country table 
```sql
---Load Sales Data From AWS S3
CREATE OR REPLACE STAGE tasty_bytes.public.s3load
url = 's3://sfquickstarts/tasty-bytes-builder-education/'
-- Specifying the file format 
file_format = tasty_bytes.public.csv_ff;

-- Creation of country table
CREATE OR REPLACE TABLE tasty_bytes.raw_pos.country
(
   country_id NUMBER(18,0),
   country VARCHAR(16777216),
   iso_currency VARCHAR(3),
   iso_country VARCHAR(2),
   city_id NUMBER(19,0),
   city VARCHAR(16777216),
   city_population VARCHAR(16777216)
);

--COPY INTO command to load data into the country table:
COPY INTO tasty_bytes.raw_pos.country
FROM @tasty_bytes.public.s3load/raw_pos/country/;
```
### 3. Data Exploration
``` sql
USE ROLE accountadmin;
USE WAREHOUSE compute_wh;
USE DATABASE tasty_bytes;

-- Query to explore sales in the city of Hamburg, Germany
WITH _feb_date_dim AS (
    SELECT DATEADD(DAY, SEQ4(), '2022-02-01') AS date 
    FROM TABLE(GENERATOR(ROWCOUNT => 28))
)
SELECT
    fdd.date,
    ZEROIFNULL(SUM(o.price)) AS daily_sales
FROM _feb_date_dim fdd
LEFT JOIN analytics.orders_v o
    ON fdd.date = DATE(o.order_ts)
    AND o.country = '#' -- Add country
    AND o.primary_city = '#' -- Add city
WHERE fdd.date BETWEEN '2022-02-01' AND '2022-02-28'
GROUP BY fdd.date
ORDER BY fdd.date ASC;

-- Create view that adds weather data for cities where Tasty Bytes operates
CREATE OR REPLACE VIEW tasty_bytes.harmonized.daily_weather_v
COMMENT = 'Weather Source Daily History filtered to Tasty Bytes supported Cities'
    AS
SELECT
    hd.*,
    TO_VARCHAR(hd.date_valid_std, 'YYYY-MM') AS yyyy_mm,
    pc.city_name AS city,
    c.country AS country_desc
FROM Pelmorex_Weather_Source_frostbyte.onpoint_id.history_day hd
JOIN Pelmorex_Weather_Source_frostbyte.onpoint_id.postal_codes pc
    ON pc.postal_code = hd.postal_code
    AND pc.country = hd.country
JOIN TASTY_BYTES.raw_pos.country c
    ON c.iso_country = hd.country
    AND c.city = hd.city_name;

-- Query the view to explore daily temperatures in Hamburg, Germany for anomalies
SELECT
    dw.country_desc,
    dw.city_name,
    dw.date_valid_std,
    AVG(dw.avg_temperature_air_2m_f) AS avg_temperature_air_2m_f
FROM harmonized.daily_weather_v dw
WHERE 1=1
    AND dw.country_desc = 'Germany'
    AND dw.city_name = 'Hamburg'
    AND YEAR(date_valid_std) = '2022'
    AND MONTH(date_valid_std) = '2' -- February
GROUP BY dw.country_desc, dw.city_name, dw.date_valid_std
ORDER BY dw.date_valid_std DESC;

-- Query the view to explore wind speeds in Hamburg, Germany for anomalies
SELECT
    dw.country_desc,
    dw.city_name,
    dw.date_valid_std,
    MAX(dw.max_wind_speed_100m_mph) AS max_wind_speed_100m_mph
FROM tasty_bytes.harmonized.daily_weather_v dw
WHERE 1=1
    AND dw.country_desc IN ('Germany')
    AND dw.city_name = 'Hamburg'
    AND YEAR(date_valid_std) = '2022'
    AND MONTH(date_valid_std) = '2' -- February
GROUP BY dw.country_desc, dw.city_name, dw.date_valid_std
ORDER BY dw.date_valid_std DESC;

-- Create a view that tracks windspeed for Hamburg, Germany
CREATE OR REPLACE VIEW tasty_bytes.harmonized.hamburg_wind_speed_v--add name of view
    AS
SELECT
    dw.country_desc,
    dw.city_name,
    dw.date_valid_std,
    MAX(dw.max_wind_speed_100m_mph) AS max_wind_speed_100m_mph
FROM harmonized.daily_weather_v dw
WHERE 1=1
    AND dw.country_desc IN ('Germany')
    AND dw.city_name = 'Hamburg'
GROUP BY dw.country_desc, dw.city_name, dw.date_valid_std
ORDER BY dw.date_valid_std DESC;
````

### 4. Insights/Inquaries
```sql
What will the weather be like in Boston next weekend?
/*
Our food truck is scheduled to be at a sporting event in Boston next weekend. Can you tell me the forecasted weather so we can anticipate footfall traffic and prepare food accordingly?
*/
SELECT
    postal_code,
    country,
    date_valid_std,
    avg_temperature_air_2m_f,
    avg_humidity_relative_2m_pct,
    avg_wind_speed_10m_mph,
    tot_precipitation_in,
    tot_snowfall_in,
    avg_cloud_cover_tot_pct,
    probability_of_precipitation_pct,
    probability_of_snow_pct
FROM
(
    SELECT
        postal_code,
        country,
        date_valid_std,
        avg_temperature_air_2m_f,
        avg_humidity_relative_2m_pct,
        avg_wind_speed_10m_mph,
        tot_precipitation_in,
        tot_snowfall_in,
        avg_cloud_cover_tot_pct,
        probability_of_precipitation_pct,
        probability_of_snow_pct,
        DATEADD(DAY,2,CURRENT_DATE()) AS skip_date,
        DATEADD(DAY,7 - DAYOFWEEKISO(skip_date),skip_date) AS next_sunday,
        DATEADD(DAY,-1,next_sunday) AS next_saturday
    FROM
        onpoint_id.forecast_day
    WHERE
        postal_code = '02201' AND
        country = 'US'
)
WHERE
    date_valid_std IN (next_saturday,next_sunday)
ORDER BY
    date_valid_std
;

// We are looking  for new locations for our food trucks in Paris.
/*
We would like to find new locations for our food trucks in Paris. Can we look at last year’s weather in Paris to choose the best location?
*/
SELECT
    postal_code,
    country,
    date_valid_std,
    avg_temperature_air_2m_f,
    avg_humidity_relative_2m_pct,
    avg_wind_speed_10m_mph,
    tot_precipitation_in,
    tot_snowfall_in,
    avg_cloud_cover_tot_pct
FROM
    onpoint_id.history_day
WHERE
    postal_code = '75008' AND
    country = 'FR' AND
    date_valid_std = DATEADD(year,-1,CURRENT_DATE)
;

// What is the temperature in London during May?
/*
We would like to look at the temperatures in May of last year to determine when to rotate seasonal menu items.
*/
SELECT
    postal_code,
    country,
    date_valid_std,
    min_temperature_air_2m_f,
    avg_temperature_air_2m_f,
    max_temperature_air_2m_f
FROM
    onpoint_id.history_day
WHERE
    postal_code = 'SW1A 0AA' AND
    country = 'GB' AND
    date_valid_std BETWEEN DATE_FROM_PARTS(YEAR(CURRENT_DATE)-1,5,1) AND DATE_FROM_PARTS(YEAR(CURRENT_DATE)-1,5,31)
ORDER BY
    date_valid_std
;

// What will the temperature in Tokyo be next Saturday?
/*
Our food truck is catering an outdoor party in Tokyo next Saturday? Can you tell me the forecasted temperatures so we can determine our menu items?
*/
SELECT
    postal_code,
    country,
    date_valid_std,
    min_temperature_air_2m_f,
    avg_temperature_air_2m_f,
    max_temperature_air_2m_f
FROM
(
    SELECT
        postal_code,
        country,
        date_valid_std,
        min_temperature_air_2m_f,
        avg_temperature_air_2m_f,
        max_temperature_air_2m_f,
        DATEADD(DAY,2,CURRENT_DATE()) AS skip_date,
        DATEADD(DAY,6 - DAYOFWEEKISO(skip_date),skip_date) AS next_saturday
    FROM
        onpoint_id.forecast_day
    WHERE
        postal_code = '102-0082' AND
        country = 'JP'
)
WHERE
    date_valid_std = next_saturday
;

// I would like to look at last year's weather in Sydney from September - November.
/*
We would like to look at the weather last year from September to November in Sydney so we can determine the best location to park our food truck during those months.
*/
SELECT
    postal_code,
    country,
    date_valid_std,
    avg_temperature_air_2m_f,
    avg_humidity_relative_2m_pct,
    avg_wind_speed_10m_mph,
    tot_precipitation_in,
    tot_snowfall_in,
    avg_cloud_cover_tot_pct
FROM
    onpoint_id.history_day
WHERE
    postal_code = '2000' AND
    country = 'AU' AND
    date_valid_std BETWEEN DATE_FROM_PARTS(YEAR(CURRENT_DATE)-1,9,1) AND DATE_FROM_PARTS(YEAR(CURRENT_DATE)-1,11,30)
ORDER BY
    date_valid_std
;

```


