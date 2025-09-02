package com.kbnt.logproducer.infrastructure.config;

import com.kbnt.logproducer.domain.service.LogRoutingService;
import com.kbnt.logproducer.domain.service.LogValidationService;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Configuração dos serviços de domínio
 */
@Configuration
public class DomainConfig {
    
    @Bean
    public LogValidationService logValidationService() {
        return new LogValidationService();
    }
    
    @Bean
    public LogRoutingService logRoutingService() {
        return new LogRoutingService();
    }
}
