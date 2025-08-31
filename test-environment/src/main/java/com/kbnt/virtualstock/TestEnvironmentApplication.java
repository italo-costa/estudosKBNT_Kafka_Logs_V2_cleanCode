package com.kbnt.virtualstock;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Test Environment Application
 * For testing Lombok and JPA fixes
 */
@SpringBootApplication
public class TestEnvironmentApplication {
    
    public static void main(String[] args) {
        SpringApplication.run(TestEnvironmentApplication.class, args);
    }
}
