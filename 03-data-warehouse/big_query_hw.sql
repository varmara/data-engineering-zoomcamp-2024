-- Creating external table referring to gcs path
CREATE OR REPLACE EXTERNAL TABLE `plasma-bison-411917.ny_taxi.green_taxi_2022_ext`
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://dezoomcamp-mage-varmara-1/green_taxi_2022_data/*.parquet']
);

-- Create a non partitioned table from external table
CREATE OR REPLACE TABLE `plasma-bison-411917.ny_taxi.green_tripdata_non_partitioned` AS
SELECT * FROM `plasma-bison-411917.ny_taxi.green_taxi_2022_ext`;

-- Q1
select COUNT(*)
FROM `plasma-bison-411917.ny_taxi.green_tripdata_partitioned`;

-- Q2 Write a query to count the distinct number of PULocationIDs for the entire dataset on both the tables. 
-- 0
select distinct(PULocationID)
FROM `plasma-bison-411917.ny_taxi.green_taxi_2022_ext`;
-- 6.41 MB
select distinct(PULocationID)
FROM `plasma-bison-411917.ny_taxi.green_tripdata_non_partitioned`;

-- Q3
select count(fare_amount)
FROM `plasma-bison-411917.ny_taxi.green_tripdata_partitioned`
WHERE fare_amount = 0;

-- Q4
CREATE OR REPLACE TABLE `plasma-bison-411917.ny_taxi.green_tripdata_part_clust`
PARTITION BY
  DATE(lpep_pickup_datetime)
  CLUSTER BY PULocationID AS
SELECT * FROM `plasma-bison-411917.ny_taxi.green_taxi_2022_ext`;

--  Q5
-- Scanning 12.82 MB of data
SELECT DISTINCT(PULocationID)
FROM `plasma-bison-411917.ny_taxi.green_tripdata_non_partitioned`
WHERE DATE(lpep_pickup_datetime) BETWEEN '2022-06-01' AND '2022-06-30';

-- Scanning ~1.12 MB of DATA
SELECT DISTINCT(PULocationID)
FROM `plasma-bison-411917.ny_taxi.green_tripdata_part_clust`
WHERE DATE(lpep_pickup_datetime) BETWEEN '2022-06-01' AND '2022-06-30';

-- Q6
-- BigQuery

-- Q7
-- True

-- Q8 Bonus
SELECT count(*) FROM `plasma-bison-411917.ny_taxi.green_tripdata_non_partitioned`;


