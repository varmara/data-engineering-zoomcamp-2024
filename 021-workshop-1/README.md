
# Data Engineering Zoomcamp 2024 - Workshop 1: Data Ingestion

In this workshop, we have learnt how to build data ingestion pipelines using **dlt**

**dlt** ("data load tool") is an open source Python library that automates data ingestion: Loading, schema management, data type detection, self healing, self maintaining, scalable extraction. Speeds up pipeline development.

​The workshop covered:
- ​Extracting data from APIs, or files.
- ​Normalising and loading data
- ​Incremental loading

**Homework** [homework_ws1.ipynb](/homework_ws1.ipynb)

## Resources

- Video: [YouTube - Workshop 1: Data Ingestion](https://www.youtube.com/live/oLXhBM7nf2Q?si=ZxlAC-6kp0IBfdKt)
- Teacher: [Adrian Brudaru](https://www.linkedin.com/in/data-team/)
- Workshop notebook [workshop.ipynb](workshop.ipynb)
- Full workshop content url: [Workshop 1: Data Ingestion](https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/main/cohorts/2024/workshops/dlt.md)
- `dlt` [docs](https://dlthub.com/docs/intro)
- `dlt` [community Slack](https://dlthub.com/community)

## Intro

**Data ingestion** involves:
- extracting data from a producer
- transporting it to a convenient environment
- preparing it for usage:
    - normalising
    - cleaning
    - adding metadata

Data
- structured, with explicit schema, ready for use
    - Parquet, Avro, or table in a db,
- weakly typed, without explicit schema, needs extra processing before usage
    - csv, json

**Schema** specifies the expected format and structure of data within a document or data store, defining the allowed keys, their data types, and any constraints or relationships.

Data Engineer's role:

- main goal is to ensure data flows from source systems to analytical destinations:
    - pipeline development
        - building pipelines, running pipelines and fixing pipelines
    - strategic management and enhancement of the entire data lifecycle
        - optimising data storage
        - ensuring data quality and integrity
        - implementing effective data governance practices
        - continuously refining data architecture to meet the evolving needs of the organisation

## Extracting data

### The considerations of extracting data

Most data is stored behind an API

- Sometimes that’s a RESTful api for some business application, returning records of data.
- Sometimes the API returns a secure file path to something like a json or parquet file in a bucket that enables you to grab the data in bulk,
- Sometimes the API is something else (mongo, sql, other databases or applications) and will generally return records as JSON - the most common interchange format.
- Need to consider:
    - Hardware limits (memory management, storage limits)
    - Network limits (retry on network fail)
    - Source api limits (wait for rate limits)
        - examples: [Zendesk](https://developer.zendesk.com/api-reference/introduction/rate-limits/), [Shopify](https://shopify.dev/docs/api/usage/rate-limits)

Managing memory:

- Many data pipelines run on serverless functions or on orchestrators that delegate the workloads to clusters of small workers:
- filling the memory/disk space might lead to crashing the entire container or machine.
- When disk space is insufficient it can be solved by mounting an external drive mapped to a storage bucket. Example: Airflow supports a "data" folder mapping to a bucket for unlimited capacity.

To avoid filling the memory, control the max memory you use (Why? Usually, the volume of data is unknown upfront and we cannot scale dynamically or infinitely).

### Streaming, generators

**Streaming** - processing the data event by event or chunk by chunk instead of doing bulk operations.

Stream the data between buffers, such as

- from API to local file
- from webhooks to event queues
- from event queue (Kafka, SQS) to Bucket

**generators** in Python are used to process data in a stream.

**Regular function** collects data in memory:

```python
def search_twitter(query):
	data = []
	for row in paginated_get(query):
		data.append(row)
	return data

# Collect all the cat picture data
for row in search_twitter("cat pictures"):
  # Once collected, 
  # print row by row
	print(row)
```

**Generator for streaming the data**:

```python
def search_twitter(query):
	for row in paginated_get(query):
		yield row

# Get one row at a time
for row in extract_data("cat pictures"):
	# print the row
	print(row)
  # do something with the row such as cleaning it and writing it to a buffer
	# continue requesting and printing data
```

### Example 1: Grabbing data from an api

 In this example, we grab data from the Zoomcamp-provided `data_engineering_zoomcamp_api` which serves the NYC taxi dataset.

The api documentation:

- A limited nr of records behind the api
- Can be requested page by page (1000 records each)
- If we request a page with no data, we will get a successful response with no data. Thus, when we get an empty page we can stop requesting pages.
- details:
    - method: get
    - url: `https://us-central1-dlthub-analytics.cloudfunctions.net/data_engineering_zoomcamp_api`
    - parameters: `page` integer. Represents the page number you are requesting. Defaults to 1.
    
**Вottleneck** on the API side: A (restful) api has to read the data from storage, process and return it.

Rerquester:

- Request page by page from the API using generator until we get no more data.
- Pros: **Easy memory management** thanks to api returning events/pages
- Cons: **Low throughput**, due to the data transfer being constrained via an API.

```python
import requests

BASE_API_URL = "https://us-central1-dlthub-analytics.cloudfunctions.net/data_engineering_zoomcamp_api"

def paginated_getter():
    page_number = 1

    while True:
        # Set the query parameters
        params = {'page': page_number}

        # Make the GET request to the API
        response = requests.get(BASE_API_URL, params=params)
        response.raise_for_status()  # Raise an HTTPError for bad responses
        page_json = response.json()
        print(f'got page number {page_number} with {len(page_json)} records')

        # if the page has no records, stop iterating
        if page_json:
            yield page_json
            page_number += 1
        else:
            # No more data, break the loop
            break

if __name__ == '__main__':
    # Use the generator to iterate over pages
    for page_data in paginated_getter():
        # Process each page as needed
        print(page_data)
```

### Example 2: Grabbing same data from file, simple download

Some apis offer the data as files, without going through the restful api layer. Common for apis that offer large volumes of data.

In this example, we grab the same data from the underlying file instead of the API.

- Pros: **High throughput**
- Cons: **Memory** is used to hold all the data

**Bottleneck** on our side: the `data` and `parsed_data` variables hold the entire file data in memory before returning it.

```python
import requests
import json

url = "https://storage.googleapis.com/dtc_zoomcamp_api/yellow_tripdata_2009-06.jsonl"

def download_and_read_jsonl(url):
    response = requests.get(url)
    response.raise_for_status()  # Raise an HTTPError for bad responses
    data = response.text.splitlines()
    parsed_data = [json.loads(line) for line in data]
    return parsed_data
   

downloaded_data = download_and_read_jsonl(url)

if downloaded_data:
    # Process or print the downloaded data as needed
    print(downloaded_data[:5])  # Print the first 5 entries as an example
```

### Example 3: Streaming download

In this example, we stream download the data and process it row-by-row.
- `.jsonl` file is already split into lines (each line is a json document, or a "row" of data) making the code simpler
- `.json` files could also be downloaded in this fashion, e.g., using the `ijson` library.

Pros: **High throughput, easy memory management**
Cons: **Difficult to do for columnar file formats**, as entire blocks need to be downloaded before they can be deserialised to rows.

```python
import requests
import json

def download_and_yield_rows(url):
    response = requests.get(url, stream=True)
    response.raise_for_status()  # Raise an HTTPError for bad responses

    for line in response.iter_lines():
        if line:
            yield json.loads(line)

# Replace the URL with your actual URL
url = "https://storage.googleapis.com/dtc_zoomcamp_api/yellow_tripdata_2009-06.jsonl"

# Use the generator to iterate over rows with minimal memory usage
for row in download_and_yield_rows(url):
    # Process each row as needed
    print(row)
```

**Self-study**: In the colab notebook there is a code snippet to load the data to DuckDB.

The `dlt` loader library will respect the streaming concept of the generator and will process it in an efficient way (low memory usage, parallelism where possible).

## Normalising data

Data cleaning types:
- Normalising data without changing its meaning
- Filtering data for a use case, which changes its meaning

Data cleaning:
- Add types (string to number, string to timestamp, etc)
- Rename columns to follow a supported standard downstream (remove strange symbols)
- Flatten nested dictionaries
- Unnest lists or arrays into child tables: they cannot be flattened into their parent record

Json is unsuitable for direct analytical usage (only for data transfer):

- **No schema**, difficult to find what's inside a json document
- **Types are not enforced between rows of json** (e.g., age may be `25`, `twenty five` or`25.00` in different records)
- **Structure may differ depending on the number of records**. In some systems, you might have a dictionary for a single record, but a list of dicts for multiple records.
- **Memory inefficient**. Reading json loads the whole document, while in parquet or databases we can scan a single column of a document
- **Slow aggregation** (columnar formats are faster)
- **Slow search**

### Data for Normalisation example

A small example of more complex data. Let’s assume we have some information about passengers and stops.

For this example the dataset was modified as follows:

- Added nested dictionaries

```json
"coordinates": {
            "start": {
                "lon": -73.787442,
                "lat": 40.641525
                },
```

- Added nested lists

```json
"passengers": [
            {"name": "John", "rating": 4.9},
            {"name": "Jack", "rating": 3.9}
                ],
```

- Added a record hash that gives us an unique id for the record, for easy identification

```json
"record_hash": "b00361a396177a9cb410ff61f20015ad",
```

Clean up:

- flatten dictionaries into the base row
- flatten lists into a separate table
- convert time strings into time type

```python

data = [
{
    "vendor_name": "VTS",
"record_hash": "b00361a396177a9cb410ff61f20015ad",
    "time": {
        "pickup": "2009-06-14 23:23:00",
        "dropoff": "2009-06-14 23:48:00"
    },
    "Trip_Distance": 17.52,
    "coordinates": {
        "start": {
            "lon": -73.787442,
            "lat": 40.641525
        },
        "end": {
            "lon": -73.980072,
            "lat": 40.742963
        }
    },
    "Rate_Code": None,
    "store_and_forward": None,
    "Payment": {
        "type": "Credit",
        "amt": 20.5,
        "surcharge": 0,
        "mta_tax": None,
        "tip": 9,
        "tolls": 4.15,
    "status": "booked"
    },
    "Passenger_Count": 2,
    "passengers": [
        {"name": "John", "rating": 4.9},
        {"name": "Jack", "rating": 3.9}
    ],
    "Stops": [
        {"lon": -73.6, "lat": 40.6},
        {"lon": -73.5, "lat": 40.5}
    ]
},
]

```

Now let’s normalise this data using `dlt`

### dlt

`dlt` is a Python library, a data loading tool that implements the best practices of data pipelines.

dlt can handle things like:

- Schema: Inferring and evolving schema, alerting changes, using schemas as data contracts.
- Typing data, flattening structures, renaming columns to fit database standards. (in the example we will pass the "data" above and see it normalised).
- Processing a stream of events/rows without filling memory, including extraction from generators.
- Loading to a variety of dbs or file formats.

### Example: Load the nested json to duckdb

- install `dlt`

```bash
# Make sure you are using Python 3.8-3.11 and have pip installed
# spin up a venv
python -m venv ./env
source ./env/bin/activate
# pip install
pip install dlt[duckdb]
```

- grab the data from above and run the snippet, where we define, run the pipeline, and print the outcome:

```python
# define the connection to load to. 
# duckdb in this example; we can switch to Bigquery later
pipeline = dlt.pipeline(pipeline_name="taxi_data",
						destination='duckdb', 
						dataset_name='taxi_rides')

# run the pipeline with default settings, and capture the outcome
info = pipeline.run(data, 
                    table_name="users", 
                    write_disposition="replace")

# show the outcome
print(info)
```

⚠️ If you are running `dlt` locally you can use the built in `streamlit` app by running the `cli` command with the pipeline name we chose above.

```bash
dlt pipeline taxi_data show
```

## Incremental loading

- **State** is information that keeps track of what was loaded, to know what else remains to be loaded. `dlt` stores the state at the destination in a separate table.
- **Incremental extraction** refers to only requesting the increment of data that we need, and not more.
- **Incremental loading** - we would load only the new data during update, not a full copy of a data. Pros: faster and cheaper.
- **Stateless data** is immutable, stands on its own, doesn't depend on other data. For example, a single record of a taxi ride with its origin, destination, and fare.
- **Stateful data** represents the current state, might change over time. For example, a table of customer details (names and addresses), which can be updated if a customer moves.
- **Slowly Changing Dimension (SCD)** like customer details or product categories in a data warehouse. SCD tables **typically store both historical and current data**, allowing analysis of both past and present states.

### dlt currently supports 2 ways of loading incrementally:

1. `Append`:
    - We can use this for _immutable_ or _stateless_ events (data that doesn’t change), such as taxi rides, do not need the entire history.
    - We could also use this to load different versions of _stateful_ data, for example for creating a _"slowly changing dimension" table for auditing changes_. For example, if we load a list of cars and their colours every day, and one day one car changes color, we need both sets of data to be able to discern that a change happened.
2. `Merge`:
    - We can use this to update data that changes.
    - For example, a taxi ride could have a payment status, which is originally "booked" but could later be changed into 'paid", "rejected" or "cancelled"

Here is how we can think about which method to use:

![incremental loading](/021-workshop-1/incremental_loading.png)

### Example: incremental loading via merge

- For example, a taxi ride could have a payment status, which is originally "booked", but later changed from "booked" to "cancelled". Perhaps Jack likes to fraud taxis and that explains his low rating. Besides the ride status change, he also got his rating lowered further.
- The merge operation replaces an old record with a new one based on a key (multiple fields or a single unique id, or a record hash - as in the example).
- A merge operation replaces rows, it does not update them. To update only parts of a row, you would have to load the new data by appending it and doing a custom transformation to combine the old and new data.

In this example, the score of the 2 drivers got lowered and we need to update the values. We do it by using merge write disposition, replacing the records identified by `record hash` present in the new data.

```python
data = [
    {
        "vendor_name": "VTS",
		"record_hash": "b00361a396177a9cb410ff61f20015ad",
        "time": {
            "pickup": "2009-06-14 23:23:00",
            "dropoff": "2009-06-14 23:48:00"
        },
        "Trip_Distance": 17.52,
        "coordinates": {
            "start": {
                "lon": -73.787442,
                "lat": 40.641525
            },
            "end": {
                "lon": -73.980072,
                "lat": 40.742963
            }
        },
        "Rate_Code": None,
        "store_and_forward": None,
        "Payment": {
            "type": "Credit",
            "amt": 20.5,
            "surcharge": 0,
            "mta_tax": None,
            "tip": 9,
            "tolls": 4.15,
			"status": "cancelled"
        },
        "Passenger_Count": 2,
        "passengers": [
            {"name": "John", "rating": 4.4},
            {"name": "Jack", "rating": 3.6}
        ],
        "Stops": [
            {"lon": -73.6, "lat": 40.6},
            {"lon": -73.5, "lat": 40.5}
        ]
    },
]

# define the connection to load to. 
# We now use duckdb, but you can switch to Bigquery later
pipeline = dlt.pipeline(destination='duckdb', dataset_name='taxi_rides')

# run the pipeline with default settings, and capture the outcome
info = pipeline.run(data, 
					table_name="users", 
					write_disposition="merge", 
					merge_key="record_hash")

# show the outcome
print(info)
```

The payment status and Jack’s rating were updated after running the code.

## What’s next?

- Change the destination to parquet + local file system or storage bucket. See the colab bonus section.
- Change the destination to BigQuery. Destination & credential setup docs: https://dlthub.com/docs/dlt-ecosystem/destinations/, https://dlthub.com/docs/walkthroughs/add_credentials
or See the colab bonus section.
- Use a decorator to convert the generator into a customised dlt resource: https://dlthub.com/docs/general-usage/resource
- Build more complex pipelines by following the guides:
    - https://dlthub.com/docs/walkthroughs
    - https://dlthub.com/docs/build-a-pipeline-tutorial
