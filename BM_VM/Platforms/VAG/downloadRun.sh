#!/usr/bin/env bash
# chmod u+x Platforms/VAG/downloadRun.sh && Platforms/VAG/downloadRun.sh

ARCH_DIR=Platforms/VAG/Archive
# library Versions
sparVer="3.2.2"
scalVer="2.12.16"
kafkVer="2.8.1"
zooVer="3.7.1" 
cassVer="3.11.13"
elasVer="7.14.2" 
janusVer="0.6.2"


downloadLibs(){
  echo -e "\nDownloading Spark ... 224.4mb"
  curl -Lko $ARCH_DIR/spark.tgz "https://dlcdn.apache.org/spark/spark-$sparVer/spark-$sparVer-bin-hadoop3.2.tgz"

  echo -e "\nDownloading Scala ... 153.8mb"
  curl -Lko $ARCH_DIR/scala.deb "https://downloads.lightbend.com/scala/$scalVer/scala-$scalVer.deb"

  echo -e "\nDownloading cassandra ... 38.8mb"
  curl -Lko $ARCH_DIR/cassandra.tar.gz "https://dlcdn.apache.org/cassandra/$cassVer/apache-cassandra-$cassVer-bin.tar.gz"

  echo -e "\nDownloading Kafka ... 65.7mb"
  curl -Lko $ARCH_DIR/kafka.tgz "https://archive.apache.org/dist/kafka/$kafkVer/kafka_2.12-$kafkVer.tgz"

  echo -e "\nDownloading Zookeeper ... 12.5mb"
  curl -Lko $ARCH_DIR/zookeeper.tar.gz "http://apache.mirror.digitalpacific.com.au/zookeeper/zookeeper-$zooVer/apache-zookeeper-$zooVer-bin.tar.gz"

  echo -e "\nDownloading elasticsearch ... 114.1mb"
  curl -Lko $ARCH_DIR/elasticsearch.tar.gz "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$elasVer-linux-x86_64.tar.gz"

  echo -e "\nDownloading Janusgraph ... 12.5mb"
  curl -Lko $ARCH_DIR/Janusgraph.tar.gz "http://apache.mirror.digitalpacific.com.au/zookeeper/zookeeper-$zooVer/apache-zookeeper-$zooVer-bin.tar.gz"
}

echo -e '\nChecking for folder existence ...'
if test -d $ARCH_DIR; then
  echo -e "OK! folder exists ...\nExiting ..."
  exit
else
  echo -e "Folder doesn't exist. \nCreating folder ..."
  if test ! -d $ARCH_DIR; then mkdir $ARCH_DIR ; fi
  echo -e "downloading libraries ..."
  downloadLibs
fi

