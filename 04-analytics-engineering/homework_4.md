# Module 4 Homework

## Assignment

In this homework, we'll use the models developed during the week 4 videos and enhance the already presented dbt project using the already loaded Taxi data for fhv vehicles for year 2019 in our DWH.

This means that in this homework we use the following data [Datasets list](https://github.com/DataTalksClub/nyc-tlc-data/)
* Yellow taxi data - Years 2019 and 2020
* Green taxi data - Years 2019 and 2020
* fhv data - Year 2019.

We will use the data loaded for:

* Building a source table: `stg_fhv_tripdata`
* Building a fact table: `fact_fhv_trips`
* Create a dashboard

If you don't have access to GCP, you can do this locally using the ingested data from your Postgres database
instead. If you have access to GCP, you don't need to do it for local Postgres - only if you want to.

> **Note**: if your answer doesn't match exactly, select the closest option

### Question 1:

**What happens when we execute dbt build --vars '{'is_test_run':'true'}'**
You'll need to have completed the ["Build the first dbt models"](https://www.youtube.com/watch?v=UVI30Vxzd6c) video.

- It's the same as running _dbt build_
- It applies a _limit 100_ to all of our models
- It applies a _limit 100_ only to our staging models
- Nothing

**Solution**: It applies a _limit 100_ only to our staging models

### Question 2:

**What is the code that our CI job will run? Where is this code coming from?**  

- The code that has been merged into the main branch
- The code that is behind the creation object on the `dbt_cloud_pr_` schema
- The code from any development branch that has been opened based on main
- The code from the development branch we are requesting to merge to main

**Solution**: The code from the development branch we are requesting to merge to main

### Question 3 (2 points)

**What is the count of records in the model fact_fhv_trips after running all dependencies with the test run variable disabled (:false)?**  
Create a staging model for the fhv data, similar to the ones made for yellow and green data. Add an additional filter for keeping only records with pickup time in year 2019.
Do not add a deduplication step. Run this models without limits (is_test_run: false).

Create a core model similar to fact trips, but selecting from stg_fhv_tripdata and joining with dim_zones.
Similar to what we've done in fact_trips, keep only records with known pickup and dropoff locations entries for pickup and dropoff locations.
Run the dbt model without limits (is_test_run: false).

- 12998722
- 22998722
- 32998722
- 42998722

**Solution**: 42998722

### Question 4 (2 points)

**What is the service that had the most rides during the month of July 2019 month with the biggest amount of rides after building a tile for the fact_fhv_trips table?**

Create a dashboard with some tiles that you find interesting to explore the data. One tile should show the amount of trips per month, as done in the videos for fact_trips, including the fact_fhv_trips data.

- FHV
- Green
- Yellow
- FHV and Green

**Solution**: Yellow
## Homework Solution

### Preparing data

#### Upploading data to GCS

For uploading green and yellow taxi data for 2019-2020, to GCS I modified `web_to_gcs.py` (from [[dezoomcamp-2024-module-3|Module 3: Data Warehouse]] extras).

Install necessary packages

`pip install pandas pyarrow google-cloud-storage`

Set GOOGLE_APPLICATION_CREDENTIALS to your project/service-account key

`export GOOGLE_APPLICATION_CREDENTIALS='/home/varmara/40_learning/data-engineering-zoomcamp-2024/01-docker-terraform/keys/plasma-bison-411917-a3b9e926eda8.json'`

Set GCP_GCS_BUCKET as your bucket

`export GCP_GCS_BUCKET='dezoomcamp-mage-varmara-1'`

Run `web_to_gcs.py`. The modified version of the script accounts for data types while reading gzipped csv files from the New-York taxi data in the course repository.

### Creating tables in BigQuery

I created external tables in BigQuery and materialised them using the adapted SQL scripts from [[dezoomcamp-2024-module-3|Module 3: Data Warehouse]]

### Setting up the dbt project

- A [dbt homework project](https://github.com/varmara/dbt-project_data-engineering) repository

In BigQuery:

- Create a service account credentials (or use the earlier created .json)

In GitHub:

- Create an empty GitHub repo

In dbt Cloud:

- Create a new dbt project
- Set up the connection of dbt to BigQuery (create and upload a json key)
- Connect dbt to your GitHub account (it is possible to restrict access to this particular repo)
- View an ssh key that was automatically generated in dbt for this project and add it to your GitHub repo
- In dbt Cloud initialise a new project in the `main` branch. The project will be automatically populated with a template project.
- To be able to make changes, create a new branch `dev` (either using dbt Cloud interface or GitHub).

### Creating models

For green and yellow taxi data I followed the course videos

For fhv data:

- Add fhv_tripdata to the sources
- Create a stg_fhv_tripdata.sql model
- Add the fields from the table to the schema
- Create a primary key and tests for uniqueness and not being null
- build the model

Answers to the assignment questions are in the Assignment section
