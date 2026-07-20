-- Set role to ACCOUNTADMIN, and set compute resource (virtual warehouse) to COMPUTE_WH.
CREATE OR REPLACE DATABASE tasty_bytes;
CREATE OR REPLACE SCHEMA raw_pos;

-- Creation of CSV file 
CREATE OR REPLACE FILE FORMAT tasty_bytes.public.csv_ff
type = 'csv';


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

