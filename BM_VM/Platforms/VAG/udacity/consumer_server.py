from kafka import KafkaConsumer 

def Consume():
    consumer = KafkaConsumer(bootstrap_servers='192.168.50.111:9011,192.168.50.112:9012,192.168.50.113:9013', auto_offset_reset='earliest')
    consumer.subscribe(["CrimeJsonTopic"])  # "RadioJsonTopic"  
    for message in consumer:
        print (message)  # print("Topic Name=%s,Message=%s"%(message.topic, message.value))

if __name__ == "__main__":
    Consume()
