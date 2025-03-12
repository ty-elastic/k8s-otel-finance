package com.example.processor;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.UUID;

@SpringBootApplication
public class Main  implements ApplicationRunner {
    private static final Logger log = LoggerFactory.getLogger(Main.class);

	public static void main(String[] args) {
		SpringApplication.run(Main.class, args);
	}

    @Override
    public void run(ApplicationArguments args) throws Exception {
		// get a reference to the current thread
        final Thread mainThread = Thread.currentThread();

        for (String opt : args.getOptionNames()) {
            log.info(opt + ":" + args.getOptionValues(opt));
        }

        String bootstrapServer = args.getOptionValues("bootstrap_server").get(0);

        Producer producer = null;
        if (args.containsOption("out_topic") && args.getOptionValues("out_topic").get(0).equals("") == false) {
            String outTopic = args.getOptionValues("out_topic").get(0);
            producer = new Producer(bootstrapServer, outTopic);
        }

        if (args.containsOption("in_topic") && args.getOptionValues("in_topic").get(0).equals("") == false) {
            String inTopic = args.getOptionValues("in_topic").get(0);
            String inGroup = args.getOptionValues("in_group").get(0);
            final Consumer consumer = new Consumer(bootstrapServer, inTopic, inGroup);

            Coordinator coordinator = null;
            if (args.containsOption("coordinator_host") && args.getOptionValues("coordinator_host").get(0).equals("") == false) {
                String coordinatorHost = args.getOptionValues("coordinator_host").get(0);
                coordinator = new Coordinator(coordinatorHost, inGroup);
                coordinator.start();
            }

            Runtime.getRuntime().addShutdownHook(new Thread() {
                public void run() {
                    log.info("Detected a shutdown, let's exit by calling consumer.wakeup()...");
                    consumer.wakeup();
    
                    // join the main thread to allow the execution of the code in the main thread
                    try {
                        mainThread.join();
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                }
            });

            consumer.run(coordinator, producer);
        }
        else if (producer != null) {
            int producerSleepMs = 1000;
            if (args.containsOption("producer_sleep_ms") && args.getOptionValues("producer_sleep_ms").get(0).equals("") == false) {
                producerSleepMs = Integer.parseInt(args.getOptionValues("producer_sleep_ms").get(0));
            }

            while (true) {
                UUID uuid = UUID.randomUUID();
                producer.notify(uuid.toString());
                Thread.sleep(producerSleepMs);
            }
        }
    }

	public Main() {

	}

}