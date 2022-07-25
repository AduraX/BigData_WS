import producer_server

def run_kafka_server():
    # TODO get the json file path ==> done
    input_file ="/vagrant/udacity/police-department-calls-for-service.json" #"/vagrant/udacity/radio_code.json" 

    # TODO fill in blanks ==> done
    producer = producer_server.ProducerServer(
        input_file=input_file,
        topic="CrimeJsonTopic", #"RadioJsonTopic", 
        bootstrap_servers='192.168.50.111:9011,192.168.50.112:9012,192.168.50.113:9013', 
        client_id="kafka_server"
    )

    return producer


def feed():
    producer = run_kafka_server()
    producer.generate_data()


if __name__ == "__main__":
    feed()
