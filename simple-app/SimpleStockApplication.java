package com.kbnt.virtualstock;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.context.annotation.Bean;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

import javax.annotation.PostConstruct;
import java.util.HashMap;
import java.util.Map;
import java.util.logging.Logger;

@SpringBootApplication
@RestController
@CrossOrigin(origins = "*")
public class SimpleStockApplication {

    private static final Logger logger = Logger.getLogger(SimpleStockApplication.class.getName());

    public static void main(String[] args) {
        System.setProperty("server.address", "0.0.0.0");
        System.setProperty("server.port", "8080");
        System.out.println("=== INICIANDO VIRTUAL STOCK SERVICE ===");
        System.out.println("Porta: 8080");
        System.out.println("Endereco: 0.0.0.0 (todas as interfaces)");
        SpringApplication.run(SimpleStockApplication.class, args);
    }

    @PostConstruct
    public void init() {
        logger.info("=== VIRTUAL STOCK SERVICE INICIADO ===");
        logger.info("Endpoints disponíveis:");
        logger.info("  GET  http://localhost:8080/api/v1/stocks");
        logger.info("  GET  http://localhost:8080/actuator/health");
        logger.info("  GET  http://localhost:8080/actuator/info");
        logger.info("  GET  http://localhost:8080/test");
        System.out.println("\n=== APLICACAO PRONTA PARA RECEBER REQUESTS ===");
        System.out.println("URL Base: http://localhost:8080");
        System.out.println("Health Check: http://localhost:8080/actuator/health");
        System.out.println("===============================================\n");
    }

    @Bean
    public FilterRegistrationBean<CorsFilter> corsFilter() {
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowCredentials(true);
        config.addAllowedOriginPattern("*");
        config.addAllowedHeader("*");
        config.addAllowedMethod("*");
        source.registerCorsConfiguration("/**", config);
        FilterRegistrationBean<CorsFilter> bean = new FilterRegistrationBean<>(new CorsFilter(source));
        bean.setOrder(0);
        return bean;
    }

    @GetMapping("/test")
    public Map<String, Object> test() {
        logger.info("Endpoint /test foi chamado");
        Map<String, Object> response = new HashMap<>();
        response.put("status", "OK");
        response.put("message", "Aplicacao funcionando corretamente!");
        response.put("timestamp", System.currentTimeMillis());
        response.put("server", "Virtual Stock Service");
        return response;
    }

    @GetMapping("/api/v1/stocks")
    public Map<String, Object> getStocks() {
        logger.info("Endpoint /api/v1/stocks foi chamado");
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Virtual Stock Service API");
        response.put("stocks", new Object[]{});
        response.put("total", 0);
        response.put("timestamp", System.currentTimeMillis());
        return response;
    }

    @GetMapping("/actuator/health")
    public Map<String, String> health() {
        logger.info("Health check foi chamado");
        Map<String, String> response = new HashMap<>();
        response.put("status", "UP");
        response.put("service", "virtual-stock-service");
        response.put("version", "1.0.0");
        System.out.println("[HEALTH CHECK] Aplicacao funcionando - Status: UP");
        return response;
    }

    @GetMapping("/actuator/info")
    public Map<String, String> info() {
        logger.info("Info endpoint foi chamado");
        Map<String, String> response = new HashMap<>();
        response.put("app", "Virtual Stock Service");
        response.put("version", "1.0.0");
        response.put("description", "Hexagonal Architecture Demo");
        response.put("java.version", System.getProperty("java.version"));
        response.put("os.name", System.getProperty("os.name"));
        return response;
    }
}
