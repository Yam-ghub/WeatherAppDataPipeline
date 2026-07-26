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



