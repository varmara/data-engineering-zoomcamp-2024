# Data Engineering Zoomcamp 2024 - Module 1 Homework: Docker and Terraform

## Docker & SQL

In this homework we'll prepare the environment
and practice with Docker and SQL

### Question 1. Knowing docker tags

Run the command to get information on Docker

```docker --help```

Now run the command to get help on the "docker build" command:

```docker build --help```

Do the same for "docker run".

Which tag has the following text? - _Automatically remove the container when it exits_

- `--delete`
- `--rc`
- `--rmc`
+ `--rm`

#### Solution:

--rm

### Question 2. Understanding docker first run

Run docker with the python:3.9 image in an interactive mode and the entrypoint of bash.
Now check the python modules that are installed ( use ```pip list``` ).

What is version of the package _wheel_ ?

+ 0.42.0
- 1.0.0
- 23.0.1
- 58.1.0

#### Solution:

0.42.0

## Prepare Postgres

Run Postgres and load data as shown in the videos
We'll use the green taxi trips from September 2019:

```wget https://github.com/DataTalksClub/nyc-tlc-data/releases/download/green/green_tripdata_2019-09.csv.gz```

You will also need the dataset with zones:

```wget https://s3.amazonaws.com/nyc-tlc/misc/taxi+_zone_lookup.csv```

Download this data and put it into Postgres (with jupyter notebooks or with a pipeline)

### Question 3. Count records

How many taxi trips were totally made on September 18th 2019?

Tip: started and finished on 2019-09-18.

Remember that `lpep_pickup_datetime` and `lpep_dropoff_datetime` columns are in the format timestamp (date and hour+min+sec) and not in date.
 
+ 15767
- 15612
- 15859
- 89009

#### Solution:

15767

```sql
select count(1) from green_taxi_data where date(lpep_pickup_datetime) = '2019-09-18';
```

### Question 4. Largest trip for each day

Which was the pick up day with the largest trip distance
Use the pick up time for your calculations.

- 2019-09-18
- 2019-09-16
+ 2019-09-26
- 2019-09-21

#### Solution:

2019-09-26

```sql
SELECT date(lpep_pickup_datetime), trip_distance
FROM green_taxi_data
ORDER BY trip_distance DESC
LIMIT 1;
```

### Question 5. Three biggest pick up Boroughs

Consider lpep_pickup_datetime in '2019-09-18' and ignoring Borough has Unknown

Which were the 3 pick up Boroughs that had a sum of total_amount superior to 50000?
 
+ "Brooklyn" "Manhattan" "Queens"
- "Bronx" "Brooklyn" "Manhattan"
- "Bronx" "Manhattan" "Queens"
- "Brooklyn" "Queens" "Staten Island"

#### Solution:

"Brooklyn" "Manhattan" "Queens"

```sql
WITH query AS (
     SELECT "PULocationID", total_amount
     FROM green_taxi_data
     WHERE DATE(lpep_pickup_datetime) = '2019-09-18'
 )
 SELECT zones."Borough", SUM(total_amount) AS borough_total
 FROM query LEFT JOIN zones ON query."PULocationID" = zones."LocationID"
 WHERE zones."Borough" != 'Unknown'
 GROUP BY zones."Borough"
 HAVING SUM(total_amount) > 50000;
```

```sql

SELECT z."Borough", **SUM(total_amount) AS borough_total
FROM green_taxi_data AS g LEFT JOIN zones AS z ON g."PULocationID" = z."LocationID"
WHERE z."Borough" != 'Unknown' AND DATE(lpep_pickup_datetime) = '2019-09-18'
GROUP BY "Borough"
HAVING SUM(total_amount) > 50000;
```

### Question 6. Largest tip

For the passengers picked up in September 2019 in the zone name Astoria which was the drop off zone that had the largest tip?
We want the name of the zone, not the id.

Note: it's not a typo, it's `tip` , not `trip`

- Central Park
- Jamaica
+ JFK Airport
- Long Island City/Queens Plaza

#### Solution:

JFK Airport

```sql
SELECT 
    gtd.tip_amount,
    pu_zone."Zone" AS pickup_zone,
    do_zone."Zone" AS dropoff_zone,
    tip_amount
FROM green_taxi_data gtd
LEFT JOIN zones pu_zone ON gtd."PULocationID" = pu_zone."LocationID"
LEFT JOIN zones do_zone ON gtd."DOLocationID" = do_zone."LocationID"
WHERE
    pu_zone."Zone" = 'Astoria'
ORDER BY tip_amount DESC
LIMIT 10;
```

## Terraform

In this section of homework we'll prepare the environment by creating resources in GCP with Terraform.

In your VM on GCP/Laptop/GitHub Codespace install Terraform.
Copy the files from the course repo
[here](https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/01-docker-terraform/1_terraform_gcp/terraform) to your VM/Laptop/GitHub Codespace.

Modify the files as necessary to create a GCP Bucket and Big Query Dataset.

### Question 7. Creating Resources

After updating the main.tf and variable.tf files run:

```
terraform apply
```

Paste the output of this command into the homework submission form.

#### Solution:

```

Terraform used the selected providers to generate the following execution plan. Resource actions are
indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # google_bigquery_dataset.demo_dataset will be created
  + resource "google_bigquery_dataset" "demo_dataset" {
      + creation_time              = (known after apply)
      + dataset_id                 = "nytaxidata"
      + default_collation          = (known after apply)
      + delete_contents_on_destroy = false
      + effective_labels           = (known after apply)
      + etag                       = (known after apply)
      + id                         = (known after apply)
      + is_case_insensitive        = (known after apply)
      + last_modified_time         = (known after apply)
      + location                   = "EUROPE-WEST1"
      + max_time_travel_hours      = (known after apply)
      + project                    = "plasma-bison-411917"
      + self_link                  = (known after apply)
      + storage_billing_model      = (known after apply)
      + terraform_labels           = (known after apply)
    }

  # google_storage_bucket.demo-bucket will be created
  + resource "google_storage_bucket" "demo-bucket" {
      + effective_labels            = (known after apply)
      + force_destroy               = true
      + id                          = (known after apply)
      + location                    = "EUROPE-WEST1"
      + name                        = "dezoomcamp-plasma-bison-411917-terraform-bucket"
      + project                     = (known after apply)
      + public_access_prevention    = (known after apply)
      + rpo                         = (known after apply)
      + self_link                   = (known after apply)
      + storage_class               = "STANDARD"
      + terraform_labels            = (known after apply)
      + uniform_bucket_level_access = (known after apply)
      + url                         = (known after apply)

      + lifecycle_rule {
          + action {
              + type = "AbortIncompleteMultipartUpload"
            }
          + condition {
              + age                   = 1
              + matches_prefix        = []
              + matches_storage_class = []
              + matches_suffix        = []
              + with_state            = (known after apply)
            }
        }
    }

Plan: 2 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: 

```

