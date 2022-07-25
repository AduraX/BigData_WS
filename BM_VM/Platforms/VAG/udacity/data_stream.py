import logging
import os, json, re
from pyspark.sql import SparkSession
from pyspark.sql.types import StructType,StructField, StringType, IntegerType
import pyspark.sql.functions as psf

# spark = SparkSession.builder.appName("TwitterSentimentAnalysis").config("spark.jars.packages", "org.apache.spark:spark-sql-kafka-0-10_2"  ".12:3.1.2").getOrCreate()

KF_NODES = "slave11:9011,slave12:9012,slave13:9013" # os.environ.get('KF_NODES')

# TODO Create a schema for incoming resources
#schema = StructType([ ]) ==> Included as an argument to run_spark_job function

def prettyPrint_jsonSparkSchema(dfSchema): # (json: str):
    parsed = json.loads(dfSchema.schema.json()) # parsed = json.loads(json_schema)
    raw = json.dumps(parsed, indent=1, sort_keys=False)

    str1 = raw

    # replace empty meta data
    str1 = re.sub('"metadata": {},\n +', '', str1)

    # replace enters between properties
    str1 = re.sub('",\n +"', '", "', str1)
    str1 = re.sub('e,\n +"', 'e, "', str1)

    # replace endings and beginnings of simple objects
    str1 = re.sub('"\n +},', '" },', str1)
    str1 = re.sub('{\n +"', '{ "', str1)

    # replace end of complex objects
    str1 = re.sub('"\n +}', '" }', str1)
    str1 = re.sub('e\n +}', 'e }', str1)

    # introduce the meta data on a different place
    str1 = re.sub('(, "type": "[^"]+")', '\\1, "metadata": {}', str1)
    str1 = re.sub('(, "type": {)', ', "metadata": {}\\1', str1)

    # make sure nested ending is not on a single line
    str1 = re.sub('}\n\s+},', '} },', str1)
    
    print("\n"); print(str1) ; print("\n") 
    return str1

def jsonSparkSchema_from_kafkaTopic(spark, topic, filePath=None):

    df_json = (spark.read
               .format("kafka")
               .option("kafka.bootstrap.servers", KF_NODES)
               .option("subscribe", topic)
               .option("startingOffsets", "earliest")
               .option("endingOffsets", "latest")
               .option("failOnDataLoss", "false")
               .load()
               # filter out empty values
               .withColumn("value", psf.expr("string(value)"))
               .filter(psf.col("value").isNotNull())
               # get latest version of each record
               .select("key", psf.expr("struct(offset, value) r"))
               .groupBy("key").agg(psf.expr("max(r) r")) 
               .select("r.value"))
    
    # decode the json values
    df_read = spark.read.json(
      df_json.rdd.map(lambda x: x.value), multiLine=True)
    
    # drop corrupt records
    if "_corrupt_record" in df_read.columns:
        df_read = (df_read
                   .filter(psf.col("_corrupt_record").isNotNull())
                   .drop("_corrupt_record"))


    dictSparkSchema = json.loads(prettyPrint_jsonSparkSchema(df_read))
    topicSchemaStructType = StructType.fromJson(dictSparkSchema)

    if filePath: 
        with open(filePath, 'w', encoding='utf-8') as f:
            json.dump(dictSparkSchema, f, ensure_ascii=False, indent=4)

    #print("\n"); print(topicSchemaStructType) ; print("\n")
    return topicSchemaStructType # return df_read

def run_spark_job(sparkP, schema):
    # DONE: Spark configurations with max offset of 200 per trigger. Set up correct bootstrap server and port
    df = (sparkP
        .readStream.format("kafka") 
        .option("kafka.bootstrap.servers", KF_NODES) 
        .option("subscribe", "CrimeJsonTopic") 
        .option("startingOffsets", "earliest") 
        .option("maxOffsetsPerTrigger", 200) 
        .option("stopGracefullyOnShutdown", "true") 
        .load())

    # Show schema for the incoming resources for checks
    df.printSchema()

    # Done: extract the correct column from the kafka input resources
    # Take only value and convert it to String
    kafka_df = df.selectExpr("CAST(value AS STRING)", "timestamp") 
    kafka_df.printSchema()

    service_table = (kafka_df 
        .select(psf.from_json(psf.col('value'), schema).alias("DF"), "timestamp").select("DF.*", "timestamp"))        
    service_table.printSchema()

    # TODO select original_crime_type_name and disposition ==> done
    distinct_table = service_table.select(psf.col("original_crime_type_name"), psf.col("disposition"), psf.col("timestamp"))
    distinct_table.printSchema()

    # count the number of original crime type
    agg_df = distinct_table.groupBy(psf.window("timestamp", "60 second"), "original_crime_type_name", "disposition").count() 
    agg_df.printSchema()
    
    # TODO Q1. Submit a screen shot of a batch ingestion of the aggregation ==> Done
    # TODO write output stream ==> done
    #query = agg_df.writeStream.outputMode("update").format("console").start() # outputMode("complete")

    # TODO attach a ProgressReporter
    #query.awaitTermination()

    # DONE: get the right radio code json path
    radio_code_json_filepath = "/vagrant/udacity/radio_code.json"
    radio_code_df = sparkPy.read.option("multiline","true").json(radio_code_json_filepath)

    # clean up your data so that the column names match on radio_code_df and agg_df
    # we will want to join on the disposition code
    # DONE: rename disposition_code column to disposition
    radio_code_df = radio_code_df.withColumnRenamed("disposition_code", "disposition")
    radio_code_df.show()

    # # TODO join on disposition column
    join_query = (agg_df.join(radio_code_df, "disposition") 
        .select(psf.col("window"), psf.col("original_crime_type_name"), psf.col("disposition"), psf.col("description"), psf.col("count"))
        .writeStream.outputMode("update").format("console").start()) 

    join_query.awaitTermination()


if __name__ == "__main__":
    logger = logging.getLogger(__name__)

    # TODO Create Spark in Standalone mode
    sparkPy = SparkSession \
        .builder \
        .appName("KafkaSparkStructuredStreaming") \
        .getOrCreate()

    logger.info("Spark started")

    # configs = sparkPy.sparkContext.getConf().getAll()
    # for config in configs:
    #     print(config) ; print("\n")

    topicSchemaStruct = jsonSparkSchema_from_kafkaTopic(sparkPy, "CrimeJsonTopic")

    run_spark_job(sparkPy, topicSchemaStruct)

    sparkPy.stop()
