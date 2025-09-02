package com.kbnt.logconsumer;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.kafka.annotation.EnableKafka;

/**
 * Log Consumer Service Application
 * Microserviço para consumo de logs do Kafka
 */
@SpringBootApplication
@EnableKafka
public class LogConsumerApplication {

    public static void main(String[] args) {
        SpringApplication.run(LogConsumerApplication.class, args);
    }

}
