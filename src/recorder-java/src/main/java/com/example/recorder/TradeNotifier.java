package com.example.recorder;

import com.example.recorder.TradeRepo;
import com.example.recorder.Trade;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.HttpResponse.BodyHandlers;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import java.util.Properties;
import java.util.UUID;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;
import java.util.concurrent.ExecutionException;

import org.apache.kafka.clients.admin.AdminClientConfig;
import org.apache.kafka.clients.admin.NewTopic;
import org.apache.kafka.clients.producer.Callback;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.producer.RecordMetadata;
import org.apache.kafka.common.KafkaException;
import org.apache.kafka.common.errors.AuthorizationException;
import org.apache.kafka.common.errors.FencedInstanceIdException;
import org.apache.kafka.common.errors.OutOfOrderSequenceException;
import org.apache.kafka.common.errors.ProducerFencedException;
import org.apache.kafka.common.errors.RetriableException;
import org.apache.kafka.common.errors.SerializationException;
import org.apache.kafka.common.errors.TopicExistsException;
import org.apache.kafka.common.errors.UnknownTopicOrPartitionException;
import org.apache.kafka.common.errors.UnsupportedVersionException;
import org.apache.kafka.common.serialization.IntegerSerializer;
import org.apache.kafka.common.serialization.StringSerializer;
import org.apache.kafka.clients.admin.Admin;
import org.apache.kafka.clients.admin.AdminClientConfig;
import org.apache.kafka.clients.admin.NewTopic;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.producer.RecordMetadata;
import org.apache.kafka.common.errors.TopicExistsException;
import org.apache.kafka.common.errors.UnknownTopicOrPartitionException;

/**
 * Service layer is where all the business logic lies
 */
@Service
@Slf4j
public class TradeNotifier {
    private static final int KAFKA_TIMEOUT_MS = 1000;
    private static final String BOOTSTRAP_SERVER = "kafka:9093";
    public static final String TOPIC_NAME = "notifications_q";
    public static final String GROUP_NAME = "recorder-java";
    private static final int KAFKA_NUM_PARITIONS = 1;
    private boolean enableKafka;

    private ObjectMapper mapper = new ObjectMapper();
    private KafkaProducer<Integer, String> kafkaProducer;
    private int key;

    public TradeNotifier() {
        try {
            enableKafka = Boolean.valueOf(System.getenv("KAFKA_ENABLED"));
            if (enableKafka) {
                recreateTopics(TOPIC_NAME);
                kafkaProducer = createKafkaProducer();
            }
        }
        catch(Exception e) {

        }
    }

    public void notify(Trade trade) {
        try {
            String body = mapper.writeValueAsString(trade);

            if (enableKafka)
                asyncSend(kafkaProducer, key++, body);

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(new URI("http://notifier:5000/notify"))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(body))
                    .build();

            HttpResponse<String> response = HttpClient.newBuilder()
                    .build()
                    .send(request, BodyHandlers.ofString());
        }
        catch (Exception e) {
            log.warn("unable to notify", e);
        }
    }


    public KafkaProducer<Integer, String> createKafkaProducer() {
        Properties props = new Properties();
        // bootstrap server config is required for producer to connect to brokers
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, BOOTSTRAP_SERVER);
        // client id is not required, but it's good to track the source of requests beyond just ip/port
        // by allowing a logical application name to be included in server-side request logging
        props.put(ProducerConfig.CLIENT_ID_CONFIG, "client-" + UUID.randomUUID());
        // key and value are just byte arrays, so we need to set appropriate serializers
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, IntegerSerializer.class);
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        if (KAFKA_TIMEOUT_MS > 0) {
            // max time before the transaction coordinator proactively aborts the ongoing transaction
            props.put(ProducerConfig.TRANSACTION_TIMEOUT_CONFIG, KAFKA_TIMEOUT_MS);
        }
        return new KafkaProducer<>(props);
    }

    private void asyncSend(KafkaProducer<Integer, String> producer, int key, String value) {
        // send the record asynchronously, setting a callback to be notified of the result
        // note that, even if you set a small batch.size with linger.ms=0, the send operation
        // will still be blocked when buffer.memory is full or metadata are not available
        producer.send(new ProducerRecord<>(TOPIC_NAME, key, value), new ProducerCallback(key, value));
    }

    class ProducerCallback implements Callback {
        private final int key;
        private final String value;

        public ProducerCallback(int key, String value) {
            this.key = key;
            this.value = value;
        }

        /**
         * A callback method the user can implement to provide asynchronous handling of request completion. This method will
         * be called when the record sent to the server has been acknowledged. When exception is not null in the callback,
         * metadata will contain the special -1 value for all fields except for topicPartition, which will be valid.
         *
         * @param metadata The metadata for the record that was sent (i.e. the partition and offset). An empty metadata
         *                 with -1 value for all fields except for topicPartition will be returned if an error occurred.
         * @param exception The exception thrown during processing of this record. Null if no error occurred.
         */
        public void onCompletion(RecordMetadata metadata, Exception exception) {
            if (exception != null) {
                log.warn(exception.getMessage());
                if (!(exception instanceof RetriableException)) {
                    // we can't recover from these exceptions
                    log.error("cannot recover", exception);
                }
            } else {
                log.info("Sample: record({}, {}), partition({}-{}), offset({})", key, value, metadata.topic(), metadata.partition(), metadata.offset());
            }
        }
    }

    public static void recreateTopics(String... topicNames) {
        Properties props = new Properties();
        props.put(AdminClientConfig.BOOTSTRAP_SERVERS_CONFIG, BOOTSTRAP_SERVER);
        props.put(AdminClientConfig.CLIENT_ID_CONFIG, "client-" + UUID.randomUUID());
        
        try (Admin admin = Admin.create(props)) {

            // delete topics if present
            // try {
            //     admin.deleteTopics(Arrays.asList(topicNames)).all().get();
            // } catch (ExecutionException e) {
            //     if (!(e.getCause() instanceof UnknownTopicOrPartitionException)) {
            //         throw e;
            //     }
            //     log.warn("Topics deletion error: {}", e.getCause());
            // }
            // log.info("Deleted topics: {}", Arrays.toString(topicNames));

            // create topics in a retry loop
            while (true) {
                // use default RF to avoid NOT_ENOUGH_REPLICAS error with minISR > 1
                short replicationFactor = -1;
                List<NewTopic> newTopics = Arrays.stream(topicNames)
                    .map(name -> new NewTopic(name, KAFKA_NUM_PARITIONS, replicationFactor))
                    .collect(Collectors.toList());
                try {
                    admin.createTopics(newTopics).all().get();
                    log.info("Created topics: {}", Arrays.toString(topicNames));
                    break;
                } 
                catch (ExecutionException e) {
                    if (!(e.getCause() instanceof TopicExistsException)) {
                        throw e;
                    }
                    log.warn("Waiting for topics metadata cleanup");
                    break;
                    //TimeUnit.MILLISECONDS.sleep(1_000);
                }
            }
        } catch (Throwable e) {
            throw new RuntimeException("Topics creation error", e);
        }
    }
}
