# Week 3 Homework

## Assignment

- _Data_: 2022 Green Taxi Trip Record Parquet Files from the New York City Taxi Data found here:  
https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page
- Load the files into a bucket. You will need to use the PARQUET option files when creating an External Table.
- In _BigQuery_, create an external table using the Green Taxi Trip Records Data for 2022
- Create a table in BQ using the Green Taxi Trip Records for 2022 (do not partition or cluster this table).

### Solution

I created a pipeline in Mage to load the New York City Taxi Data from their website

- data loader [`green_taxi_2022_parquet_to_pandas_df.py`](mage_green_taxi_2022_parquet_to_gcs/green_taxi_2022_parquet_to_pandas_df.py) - loads multiple .parquet files and concatenates them into a single pandas dataframe
- data exporter [`green_taxi_2022_parquet_to_gsc.py`](mage_green_taxi_2022_parquet_to_gcs/green_taxi_2022_parquet_to_gsc.py) - writes a parquet file to GCS bucket.

## Quiz

### Question 1

What is count of records for the 2022 Green Taxi Data?

- 65,623,481
- 840,402
- 1,936,423
- 253,647

S: - 840,402
### Question 2

Write a query to count the distinct number of PULocationIDs for the entire dataset on both the tables. 
What is the estimated amount of data that will be read when this query is executed on the External Table and the Table?

- 0 MB for the External Table and 6.41MB for the Materialized Table
- 18.82 MB for the External Table and 47.60 MB for the Materialized Table
- 0 MB for the External Table and 0MB for the Materialized Table
- 2.14 MB for the External Table and 0MB for the Materialized Table

S: - 0 MB for the External Table and 6.41MB for the Materialized Table
### Question 3

How many records have a fare_amount of 0?

- 12,488
- 128,219
- 112
- 1,622

S: - 1,622

### Question 4

What is the best strategy to make an optimized table in Big Query if your query will always order the results by PUlocationID and filter based on lpep_pickup_datetime? (Create a new table with this strategy)

- Cluster on lpep_pickup_datetime Partition by PUlocationID
- Partition by lpep_pickup_datetime Cluster on PUlocationID
- Partition by lpep_pickup_datetime and Partition by PUlocationID
- Cluster on by lpep_pickup_datetime and Cluster on PUlocationID

S: - Partition by lpep_pickup_datetime Cluster on PULocationID

### Question 5

Write a query to retrieve the distinct PULocationID between lpep_pickup_datetime
06/01/2022 and 06/30/2022 (inclusive)

Use the materialized table you created earlier in your from clause and note the estimated bytes. Now change the table in the from clause to the partitioned table you created for question 4 and note the estimated bytes processed. What are these values?

Choose the answer which most closely matches.

- 22.82 MB for non-partitioned table and 647.87 MB for the partitioned table
- 12.82 MB for non-partitioned table and 1.12 MB for the partitioned table
- 5.63 MB for non-partitioned table and 0 MB for the partitioned table
- 10.31 MB for non-partitioned table and 10.31 MB for the partitioned table

S: - 12.82 MB for non-partitioned table and 1.12 MB for the partitioned table
### Question 6

Where is the data stored in the External Table you created?

- Big Query
- GCP Bucket
- Big Table
- Container Registry

S: - GCP Bucket

### Question 7

It is best practice in Big Query to always cluster your data:

- True
- False

S: - True

### (Bonus: Not worth points) Question 8

Write a `SELECT count(*)` query FROM the materialized table you created. How many bytes does it estimate will be read? Why?
