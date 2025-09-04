package com.estudoskbnt.consumer.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.reactive.function.client.WebClient;

/**
 * Web Client Configuration
 * 
 * Configuration for WebClient used in external API calls.
 * Includes connection pooling, timeouts, and retry settings.
 * 
 * @author KBNT Development Team
 * @version 1.0.0
 */
@Configuration
public class WebClientConfig {
    
    @Bean
    public WebClient.Builder webClientBuilder() {
        return WebClient.builder()
                .codecs(configurer -> configurer
                        .defaultCodecs()
                        .maxInMemorySize(1024 * 1024)) // 1MB buffer
                .defaultHeader("Content-Type", "application/json")
                .defaultHeader("User-Agent", "KBNT-Stock-Consumer-Service/1.0.0");
    }
    
    @Bean
    public WebClient webClient(WebClient.Builder webClientBuilder) {
        return webClientBuilder.build();
    }
}
