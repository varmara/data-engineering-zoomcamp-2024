import io
import pandas as pd
if 'data_loader' not in globals():
    from mage_ai.data_preparation.decorators import data_loader
if 'test' not in globals():
    from mage_ai.data_preparation.decorators import test
import pyarrow.parquet as pq

@data_loader
def load_data_from_api(*args, **kwargs):
    """
    Load data from several .parquet
    """
    base_url = 'https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_'
    year = 2022
    months = list(range(1, 13))
    extension = '.parquet'

    # construct urls from base_url, year and month (formatted to two digits with :02d) 
    urls = [f"{base_url}{year}-{month:02d}{extension}" for month in months]

    dfs = []
    for url in urls:
        df = pd.read_parquet(url)
        dfs.append(df)

    return pd.concat(dfs, ignore_index=True)


@test
def test_output(output, *args) -> None:
    """
    Template code for testing the output of the block.
    """
    assert output is not None, 'The output is undefined'
