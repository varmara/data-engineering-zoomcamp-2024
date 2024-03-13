# Homework

## Setting up

In order to get a static set of results, we will use historical data from the dataset.

Run the following commands:

```bash
# Load the cluster op commands.
source commands.sh
# First, reset the cluster:
clean-cluster
# Start a new cluster
start-cluster
# wait for cluster to start
sleep 5
# Seed historical data instead of real-time data
seed-kafka
# Recreate trip data table
psql -f risingwave-sql/table/trip_data.sql
# Wait for a while for the trip_data table to be populated.
sleep 5
# Check that you have 100K records in the trip_data table
# You may rerun it if the count is not 100K
psql -c "SELECT COUNT(*) FROM trip_data"
```

## Assignment

### Question 0

What are the dropoff taxi zones at the latest dropoff times?

For this part, we will use the [dynamic filter pattern](https://docs.risingwave.com/docs/current/sql-pattern-dynamic-filters/).

<details>
<summary>Provided solution</summary>

```sql
CREATE MATERIALIZED VIEW latest_dropoff_time AS
    WITH t AS (
        SELECT MAX(tpep_dropoff_datetime) AS latest_dropoff_time
        FROM trip_data
    )
    SELECT taxi_zone.Zone as taxi_zone, latest_dropoff_time
    FROM t,
            trip_data
    JOIN taxi_zone
        ON trip_data.DOLocationID = taxi_zone.location_id
    WHERE trip_data.tpep_dropoff_datetime = t.latest_dropoff_time;

--    taxi_zone    | latest_dropoff_time
-- ----------------+---------------------
--  Midtown Center | 2022-01-03 17:24:54
-- (1 row)
```

</details>

**Solution**:


```sql
CREATE MATERIALIZED VIEW question_0_v1 AS
SELECT 
    DISTINCT Zone, 
    tpep_dropoff_datetime AS latest_dropoff_time
FROM
    taxi_zone JOIN trip_data ON trip_data.DOLocationID = taxi_zone.location_id
WHERE 
    tpep_dropoff_datetime = (
        SELECT
                max(tpep_dropoff_datetime)
        FROM trip_data
    );
```

**Answer**: Midtown Center

### Question 1

Create a materialized view to compute the average, min and max trip time **between each taxi zone**.

Note that we consider the do not consider `a->b` and `b->a` as the same trip pair.
So as an example, you would consider the following trip pairs as different pairs:
```plaintext
Yorkville East -> Steinway
Steinway -> Yorkville East
```

From this MV, find the pair of taxi zones with the highest average trip time.
You may need to use the [dynamic filter pattern](https://docs.risingwave.com/docs/current/sql-pattern-dynamic-filters/) for this.


Options:
1. Yorkville East, Steinway
2. Murray Hill, Midwood
3. East Flatbush/Farragut, East Harlem North
4. Midtown Center, University Heights/Morris Heights

**Solution**:

```sql
CREATE MATERIALIZED VIEW question_1 AS
SELECT
taxi_zone_pickup.zone AS pickup_zone,
    taxi_zone_dropoff.zone AS dropoff_zone,
    AVG(tpep_dropoff_datetime - tpep_pickup_datetime) AS avg_dur,
    MIN(tpep_dropoff_datetime - tpep_pickup_datetime) AS min_dur,
    MAX(tpep_dropoff_datetime - tpep_pickup_datetime) AS max_dur
FROM trip_data
    JOIN taxi_zone AS taxi_zone_dropoff
        ON trip_data.dolocationid = taxi_zone_dropoff.location_id
    JOIN taxi_zone AS taxi_zone_pickup
        ON trip_data.pulocationid = taxi_zone_pickup.location_id
GROUP BY 
    taxi_zone_pickup.zone, 
    taxi_zone_dropoff.zone
ORDER BY
    avg_dur DESC;
```


**Answer**: Yorkville East, Steinway


### Question 2

Recreate the MV(s) in question 1, to also find the **number of trips** for the pair of taxi zones with the highest average trip time.

Options:
1. 5
2. 3
3. 10
4. 1

**Solution 1**:


```sql
CREATE MATERIALIZED VIEW question_2 AS
SELECT
    taxi_zone_pickup.zone AS pickup_zone,
    taxi_zone_dropoff.zone AS dropoff_zone,
    AVG(tpep_dropoff_datetime - tpep_pickup_datetime) AS avg_dur,
    MIN(tpep_dropoff_datetime - tpep_pickup_datetime) AS min_dur,
    MAX(tpep_dropoff_datetime - tpep_pickup_datetime) AS max_dur,
    COUNT(1) AS n_trips
FROM trip_data
    JOIN taxi_zone AS taxi_zone_dropoff
        ON trip_data.dolocationid = taxi_zone_dropoff.location_id
    JOIN taxi_zone AS taxi_zone_pickup
        ON trip_data.pulocationid = taxi_zone_pickup.location_id
GROUP BY 
    taxi_zone_pickup.zone, 
    taxi_zone_dropoff.zone
HAVING
    AVG(tpep_dropoff_datetime - tpep_pickup_datetime) = (SELECT MAX(avg_dur) FROM question_1);
```


**Solution 2**: Ugly solution with a dynamic filter (?)

```sql
CREATE MATERIALIZED VIEW question_2_v2 AS
    WITH t AS (
        SELECT pickup_zone, dropoff_zone
        FROM question_1
        WHERE avg_dur = (
            SELECT MAX(avg_dur) AS max_avg_dur
            FROM question_1
        )
    )
    SELECT 
        taxi_zone_pickup.zone AS pickup_zone,
        taxi_zone_dropoff.zone AS dropoff_zone,
        COUNT(*) AS n_trips
    FROM t, 
        trip_data
            JOIN taxi_zone AS taxi_zone_dropoff
                ON trip_data.dolocationid = taxi_zone_dropoff.location_id 
            JOIN taxi_zone AS taxi_zone_pickup
                ON trip_data.pulocationid = taxi_zone_pickup.location_id
    WHERE taxi_zone_dropoff.zone = t.dropoff_zone AND taxi_zone_pickup.zone = t.pickup_zone
    GROUP BY 
        taxi_zone_pickup.zone, taxi_zone_dropoff.zone;
```


**Answer**: 1 

```
pickup_zone   | dropoff_zone | avg_dur  | min_dur  | max_dur  | n_trips 
----------------+--------------+----------+----------+----------+---------
 Yorkville East | Steinway     | 23:59:33 | 23:59:33 | 23:59:33 |       1
(1 row)
```


### Question 3

From the latest pickup time to 17 hours before, what are the top 3 busiest zones in terms of number of pickups?
For example if the latest pickup time is 2020-01-01 17:00:00,
then the query should return the top 3 busiest zones from 2020-01-01 00:00:00 to 2020-01-01 17:00:00.

HINT: You can use [dynamic filter pattern](https://docs.risingwave.com/docs/current/sql-pattern-dynamic-filters/)
to create a filter condition based on the latest pickup time.

NOTE: For this question `17 hours` was picked to ensure we have enough data to work with.

Options:
1. Clinton East, Upper East Side North, Penn Station
2. LaGuardia Airport, Lincoln Square East, JFK Airport
3. Midtown Center, Upper East Side South, Upper East Side North
4. LaGuardia Airport, Midtown Center, Upper East Side North


**Solution**: 

```sql
CREATE MATERIALIZED VIEW question_3_1 AS
    WITH t AS (
        SELECT MAX(tpep_pickup_datetime) AS latest_pickup_time
        FROM trip_data
    )
    SELECT 
        taxi_zone.zone AS zone_name,
        COUNT(1) AS n_trips
    FROM t,
         trip_data
            JOIN taxi_zone
                ON trip_data.pulocationid = taxi_zone.location_id
    WHERE trip_data.tpep_pickup_datetime > latest_pickup_time - interval '17 hour'
    GROUP BY taxi_zone.zone
    ORDER BY n_trips DESC
    LIMIT 3;

```

**Answer**: LaGuardia Airport, Lincoln Square East, JFK Airport


