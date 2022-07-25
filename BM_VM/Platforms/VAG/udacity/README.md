
# == Platform detaIls:  1-master-3-slave 4-Vagrant-node Big Data cluster with:
# - Spark:      slave11, slave12, slave13, master01,
# - Kafka:      slave11, slave12, slave13
# - Zookeeper:  slave11, slave12, slave13

Therefore, there are same zookeeper.properties files and almost the same server.properties files, except for the broker ID( 11, 12, 13) in the slave nodes.


# == Write the answers to these questions in the README.md doc of your GitHub repo:

# 1. How did changing values on the SparkSession property parameters affect the throughput and latency of the data?
Increaseing the spark.driver.memory and spark.executor.cores propperties increases the throughput and reduces latency of streaming app. 

# 2. What were the 2-3 most efficient SparkSession property key/value pairs? Through testing multiple variations on values, how can you tell these were the most optimal?
The 3 most efficeint SparkSession property key/value pairs are the spark.driver.memory, spark.executor.cores and spark.sql.shuffle.partitions. I can tell by experimenting on them.

