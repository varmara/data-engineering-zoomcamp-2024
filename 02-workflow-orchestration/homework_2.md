# Data Engineering Zoomcamp 2024 - Module 2 Homework: Workflow orchestration

## Mage

> In case you don't get one option exactly, select the closest one

For the homework, we'll be working with the _green_ taxi dataset located here:

`https://github.com/DataTalksClub/nyc-tlc-data/releases/tag/green/download`

## Assignment

The goal will be to construct an ETL pipeline that loads the data, performs some transformations, and writes the data to a database (and Google Cloud!).

- Create a new pipeline, call it `green_taxi_etl`
- Add a data loader block and use Pandas to read data for the final quarter of 2020 (months `10`, `11`, `12`).
  - You can use the same datatypes and date parsing methods shown in the course.
  - `BONUS`: load the final three months using a for loop and `pd.concat`
- Add a transformer block and perform the following:
  - Remove rows where the passenger count is equal to 0 _or_ the trip distance is equal to zero.
  - Create a new column `lpep_pickup_date` by converting `lpep_pickup_datetime` to a date.
  - Rename columns in Camel Case to Snake Case, e.g. `VendorID` to `vendor_id`.
  - Add three assertions:
    - `vendor_id` is one of the existing values in the column (currently)
    - `passenger_count` is greater than 0
    - `trip_distance` is greater than 0
- Using a Postgres data exporter (SQL or Python), write the dataset to a table called `green_taxi` in a schema `mage`. Replace the table if it already exists.
- Write your data as Parquet files to a bucket in GCP, partioned by `lpep_pickup_date`. Use the `pyarrow` library!
- Schedule your pipeline to run daily at 5AM UTC.

## SOLUTION


Pipeline `green_taxi_etl_homework`

[ETL: API to postgres & GCP](../images/image-2024-02-07-14.55.50.png)

### Data loader 

Data loader `magic-zoomcamp/data_loaders/load_green_taxi_data.py`

```python
import io
import pandas as pd
if 'data_loader' not in globals():
    from mage_ai.data_preparation.decorators import data_loader
if 'test' not in globals():
    from mage_ai.data_preparation.decorators import test


@data_loader
def load_data_from_api(*args, **kwargs):
    """
    Load data from several .csv.gz
    """
    base_url = 'https://github.com/DataTalksClub/nyc-tlc-data/releases/download/green/green_tripdata_'
    year = 2020
    months = [10, 11, 12]

    # construct urls from base_url, year and month (formatted to two digits with :02d) 
    urls = [f"{base_url}{year}-{month:02d}.csv.gz" for month in months]

    taxi_dtypes = {
        'VendorID': pd.Int64Dtype(),
        'passenger_count': pd.Int64Dtype(),
        'trip_distance': float,
        'RatecodeID':pd.Int64Dtype(),
        'store_and_fwd_flag':str,
        'PULocationID':pd.Int64Dtype(),
        'DOLocationID':pd.Int64Dtype(),
        'payment_type': pd.Int64Dtype(),
        'fare_amount': float,
        'extra':float,
        'mta_tax':float,
        'tip_amount':float,
        'tolls_amount':float,
        'improvement_surcharge':float,
        'total_amount':float,
        'congestion_surcharge':float
    }
    
    # native date parsing 
    parse_dates = ['lpep_pickup_datetime', 'lpep_dropoff_datetime']

    dfs = []
    for url in urls:
        df = pd.read_csv(
            url, 
            compression='gzip', 
            dtype=taxi_dtypes, 
            parse_dates=parse_dates)
        dfs.append(df)

    return pd.concat(dfs, ignore_index=True)


@test
def test_output(output, *args) -> None:
    """
    Template code for testing the output of the block.
    """
    assert output is not None, 'The output is undefined'
```
### Data transformer

Data transformer `magic-zoomcamp/transformers/transform_green_taxi_data.py`

```python
import re
import pandas as pd

if 'transformer' not in globals():
    from mage_ai.data_preparation.decorators import transformer
if 'test' not in globals():
    from mage_ai.data_preparation.decorators import test

def camel_to_snake(x):
    """
    Convert a CamelCase string to snake_case.

    This function applies a regular expression to transform the input string
    from CamelCase (also handling sequences of uppercase letters) to snake_case,
    ensuring lowercase letters with underscores separating words.

    Parameters:
    - x (str): The CamelCase string to be converted to snake_case.

    Returns:
    - str: The converted snake_case string.

    Examples:
    >>> camel_to_snake('CamelCase')
    'camel_case'
    >>> camel_to_snake('CamelCamelCase')
    'camel_camel_case'
    >>> camel_to_snake('Camel2Camel2Case')
    'camel2_camel2_case'
    >>> camel_to_snake('getHTTPResponseCode')
    'get_http_response_code'
    >>> camel_to_snake('get2HTTPResponseCode')
    'get2_http_response_code'
    """
    return re.sub(r'(?<=[a-z0-9])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])', '_', x).lower()

@transformer
def transform(data, *args, **kwargs):
    """
    Cleans and transforms input data for further analysis or modeling.

    1. Removes rows where passengers count or trip distance is zero, indicating invalid or incomplete trips.
    2. Extracts the date from 'lpep_pickup_datetime' and stores it in a new column 'lpep_pickup_date'.
    3. Renames columns from CamelCase to snake_case for consistency.

    Args:
        data (DataFrame): The input DataFrame containing green taxi trip records.
        *args: The output from any additional upstream blocks (if applicable).
        **kwargs: Arbitrary keyword arguments for additional parameters or configuration options.

    Returns:
        DataFrame: The transformed DataFrame with preprocessing steps applied.

    Note:
        The function assumes the input DataFrame contains specific columns ('lpep_pickup_datetime',
        'passenger_count', 'trip_distance'). 
    """

    print(f"Q1: Data shape is {data.shape}")

    # Remove trips with zero passengers or zero distance
    print(f"Rows with zero passengers: {data['passenger_count'].isin([0]).sum()}")
    print(f"Rows with zero trip distance: {data['trip_distance'].isin([0]).sum()}")
    print(f"Removed { ((data['passenger_count'] == 0) | (data['trip_distance'] == 0)).sum() } rows")
    data = data[(data['passenger_count'] > 0) & (data['trip_distance'] > 0)]

    print(f"Q2: After filtering zeros {data.shape[0]} rows remain")

    # Extract trip date to separate variable
    data['lpep_pickup_date'] = data['lpep_pickup_datetime'].dt.date
    # data['lpep_dropoff_date'] = data['lpep_dropoff_datetime'].dt.date

    # Rename columns in Camel Case to Snake Case
    data.columns = (data.columns
                    .str.replace(' ', '_')
                    .map(camel_to_snake)
                    .str.lower()
    )
    print(f"Q4: Vendor IDs in the dataset: {data['vendor_id'].unique()}")
    print(f"Q6: Unique pickup dates: {data['lpep_pickup_date'].nunique()}")

    return data

@test
def test_output(output, *args) -> None:
    assert output is not None, 'The output is undefined'

# 1) `vendor_id` is one of the existing values in the column (currently)
@test
def test_vendor_id(output, *args) -> None:
    assert 'vendor_id' in output.columns, 'There is no column `vendor_id`. Check if the columns were renamed correctly'

# 2) `passenger_count` is greater than 0
@test
def test_passenger_count(output, *args) -> None:
    assert all(output['passenger_count'] > 0), 'There are rows with zero `passenger_count`. Check if zeros were handled correctly'

# 3) `trip_distance` is greater than 0
@test
def test_trip_distance(output, *args) -> None:
    assert all(output['trip_distance'] > 0), 'There are rows with zero `trip_distance`. Check if zeros were handled correctly'
```
### Data exporter 

Data exporter (Postgres, Python) `green_taxi_to_postgres.py`

```python
from mage_ai.settings.repo import get_repo_path
from mage_ai.io.config import ConfigFileLoader
from mage_ai.io.postgres import Postgres
from pandas import DataFrame
from os import path

if 'data_exporter' not in globals():
    from mage_ai.data_preparation.decorators import data_exporter

@data_exporter
def export_data_to_postgres(df: DataFrame, **kwargs) -> None:
    """
    Template for exporting data to a PostgreSQL database.
    Specify your configuration settings in 'io_config.yaml'.

    Docs: https://docs.mage.ai/design/data-loading#postgresql
    """
    schema_name = 'mage'  # Specify the name of the schema to export data to
    table_name = 'green_taxi_data'  # Specify the name of the table to export data to
    config_path = path.join(get_repo_path(), 'io_config.yaml')
    config_profile = 'dev'

    with Postgres.with_config(ConfigFileLoader(config_path, config_profile)) as loader:
        loader.export(
            df,
            schema_name,
            table_name,
            index=False,  # Specifies whether to include index in exported table
            if_exists='replace',  # Specify resolution policy if table name already exists
        )
```
### Data exporter 

Data exporter (GCP bucket, Python; parquet, partitioned by `lpep_pickup_date` using `pyarrow`) `green_taxi_to_gcs_partitioned_parquet.py`

```python
import pyarrow as pa
import pyarrow.parquet as pq
import os

if 'data_exporter' not in globals():
    from mage_ai.data_preparation.decorators import data_exporter

# Tell pyarrow where the credentials live:
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = "/home/src/path-to-your-key-file.json"
# Define the bucket name, the project id and table name:
bucket_name = 'your-gcs-bucket-name'
project_id = 'your-gcp-project-id'
table_name = 'green_taxi_data'
# Define the root path:
root_path = f'{bucket_name}/{table_name}'

@data_exporter
def export_data(data, *args, **kwargs):
    # define a oyarrow table
    table = pa.Table.from_pandas(data)
    # find a google cloud storage
    gcs = pa.fs.GcsFileSystem()
    # break data into files by date and write into separate parquet files
    pq.write_to_dataset(
        table,
        root_path=root_path,
        partition_cols=['lpep_pickup_date'],
        filesystem=gcs
    )
```
## Question 1. Data Loading

Once the dataset is loaded, what's the shape of the data?

* 266,855 rows x 20 columns
* 544,898 rows x 18 columns
* 544,898 rows x 20 columns
* 133,744 rows x 20 columns

### Solution

Q1: Data shape is (266855, 20)

## Question 2. Data Transformation

Upon filtering the dataset where the passenger count is greater than 0 _and_ the trip distance is greater than zero, how many rows are left?

* 544,897 rows
* 266,855 rows
* 139,370 rows
* 266,856 rows

### Solution

Q2: After filtering zeros 139370 rows remain

## Question 3. Data Transformation

Which of the following creates a new column `lpep_pickup_date` by converting `lpep_pickup_datetime` to a date?

* `data = data['lpep_pickup_datetime'].date`
* `data('lpep_pickup_date') = data['lpep_pickup_datetime'].date`
* `data['lpep_pickup_date'] = data['lpep_pickup_datetime'].dt.date`
* `data['lpep_pickup_date'] = data['lpep_pickup_datetime'].dt().date()`

### Solution

`data['lpep_pickup_date'] = data['lpep_pickup_datetime'].dt.date`

## Question 4. Data Transformation

What are the existing values of `VendorID` in the dataset?

* 1, 2, or 3
* 1 or 2
* 1, 2, 3, 4
* 1

### Solution

1 or 2

## Question 5. Data Transformation

How many columns need to be renamed to snake case?

* 3
* 6
* 2
* 4

### Solution

4 columns

## Question 6. Data Exporting

Once exported, how many partitions (folders) are present in Google Cloud?

* 96
* 56
* 67
* 108

### Solution

Assuming a single .parquet per directory:

```python
gsutil ls -lR gs://bucket-name/directory-name | grep '.parquet' | wc -l
# 95
```

Closest option is 96
