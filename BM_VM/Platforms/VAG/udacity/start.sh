#== 4-Vagrant-node Big Data cluster with:
# - Spark: master01, slave11, slave12, slave13
# - Kafka: slave11, slave12, slave13

grep MemTotal /proc/meminfo
chmod +x $SPARK_HOME/bin/check-status.sh && $SPARK_HOME/bin/check-status.sh

# Check if Spark cluster is working
pyspark --master spark://master01:7077
spark-shell --master spark://master01:7077

# sudo apt-get -y install python3-pip   ||  pip3 --version
pip3 install -r /vagrant/udacity/requirements.txt

# Check if Spark cluster can run custom codes
spark-submit --master spark://master01:7077 --class org.apache.spark.examples.SparkPi  $SPARK_HOME/examples/jars/spark-examples_2.12-3.1.2.jar 80
spark-submit --master spark://master01:7077 $SPARK_HOME/examples/src/main/python/pi.py 1000

# Change to a broker server: ssh slave11
kafka-topics.sh --create --topic CrimeJsonTopic --replication-factor 3  --partitions 5  --zookeeper $ZK_NODES
kafka-topics.sh --describe --topic CrimeJsonTopic --zookeeper $ZK_NODES # Describe TOPIC

# Change back to maser01 
python3 /vagrant/udacity/kafka_server.py
# Open another terminal for the cmd below
python3 /vagrant/udacity/consumer_server.py

# Open another terminal for the cmd below
#spark-submit --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.1.3 --master spark://master01:7077 /vagrant/udacity/data_stream.py

spark-submit --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.2.2 --master spark://master01:7077 /vagrant/udacity/data_stream.py


http://192.168.50.101:8080/ # http://master01:8080/ # 
http://192.168.50.101:4040/ # http://master01:4040/ # 
