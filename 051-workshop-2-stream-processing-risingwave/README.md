
# Data Engineering Zoomcamp 2024

## Workshop 2: Stream processing in SQL with RisingWave

In this hands-on workshop, we learnt how to process real-time streaming data using SQL in RisingWave. 

RisingWave is an open-source, SQL-based streaming database. It provides incrementally updated, consistent materialized views, which are persistent data structures representing pre-computed and continuously updated results of stream processing queries. Complex stream processing logic can be expressed through cascaded materialized views. One instance of RisingWave can handle multiple streams (e.g., instead of multiple Kafka instances). Users can interact with these materialized views directly within RisingWave, potentially reducing the need to deliver results to an external database for serving.

**Topics covered**:

- Why Stream Processing?
- Stateless computation (Filters, Projections)
- Stateful Computation (Aggregations, Joins)
- Data Ingestion and Delivery

**Homework**: [Workshop 2 Homework](homework_ws2.md)

## The dataset

The NYC Taxi dataset (taxi trips in New York City). Downloaded from [NYC Taxi & Limousine Commission website](https://www1.nyc.gov/site/tlc/about/tlc-trip-record-data.page).
These two files are in the `data` directory:
- `yellow_tripdata_2022-01.parquet`
- `taxi_zone.csv`

The file `seed_kafka.py` contains the logic to process the data and populate RisingWave.

To simulate processing of real-time data, we will replace the `timestamp` fields in the `trip_data` with `timestamp`s close to the current time.

## Project Structure

```plaintext
$ tree -L 1
.
├── README.md                   # This file
├── clickhouse-sql              # SQL scripts for Clickhouse
├── commands.sh                 # Commands to operate the cluster
├── data                        # Data files (trip_data, taxi_zone)
├── docker                      # Contains docker compose files
├── requirements.txt            # Python dependencies
├── risingwave-sql              # SQL scripts for RisingWave (includes some homework files)
└── seed_kafka.py               # Python script to seed Kafka
```

## Prerequisites

1. Docker and Docker Compose
2. Python 3.7 or later
3. `pip` and `virtualenv` for Python
4. `psql` (I use PostgreSQL-14.9)


## Getting started

1. Run diagnostics.
2. Start the RisingWave cluster.
3. Setup python environment.

```bash
# Check version of psql
psql --version
source commands.sh

# Start the RW cluster
start-cluster

# Setup python
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```
