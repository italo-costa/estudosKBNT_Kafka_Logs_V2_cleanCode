package com.kbnt.logproducer.application.usecase;

import com.kbnt.logproducer.domain.model.LogEntry;
import com.kbnt.logproducer.domain.port.input.LogProductionUseCase;
import com.kbnt.logproducer.domain.port.output.LogPublisherPort;
import com.kbnt.logproducer.domain.port.output.MetricsPort;
import com.kbnt.logproducer.domain.service.LogRoutingService;
import com.kbnt.logproducer.domain.service.LogValidationService;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Implementação do caso de uso de produção de logs
 */
@Service
public class LogProductionUseCaseImpl implements LogProductionUseCase {
    
    private final LogPublisherPort logPublisher;
    private final MetricsPort metricsPort;
    private final LogValidationService validationService;
    private final LogRoutingService routingService;
    
    public LogProductionUseCaseImpl(LogPublisherPort logPublisher,
                                  MetricsPort metricsPort,
                                  LogValidationService validationService,
                                  LogRoutingService routingService) {
        this.logPublisher = logPublisher;
        this.metricsPort = metricsPort;
        this.validationService = validationService;
        this.routingService = routingService;
    }
    
    @Override
    public void produceLog(LogEntry logEntry) {
        try {
            // 1. Validar o log
            List<String> validationErrors = validationService.validateLogEntry(logEntry);
            if (!validationErrors.isEmpty()) {
                metricsPort.incrementValidationErrors();
                throw new IllegalArgumentException("Log inválido: " + String.join(", ", validationErrors));
            }
            
            // 2. Verificar se deve processar
            if (!validationService.shouldProcessLog(logEntry)) {
                metricsPort.incrementSkippedLogs();
                return;
            }
            
            // 3. Determinar roteamento
            String topic = routingService.determineKafkaTopic(logEntry);
            String partitionKey = routingService.generatePartitionKey(logEntry);
            int priority = routingService.determinePriority(logEntry);
            
            // 4. Publicar no Kafka
            logPublisher.publishLog(logEntry, topic, partitionKey);
            
            // 5. Registrar métricas
            metricsPort.incrementPublishedLogs();
            metricsPort.recordLogLevel(logEntry.getLevel().toString());
            metricsPort.recordLogService(logEntry.getService().getValue());
            metricsPort.recordProcessingTime(System.currentTimeMillis() - logEntry.getTimestamp().toEpochMilli());
            
            // 6. Para logs de alta prioridade, registrar métrica especial
            if (priority == 1) {
                metricsPort.incrementHighPriorityLogs();
            }
            
        } catch (Exception e) {
            metricsPort.incrementPublishingErrors();
            throw new RuntimeException("Erro ao produzir log: " + e.getMessage(), e);
        }
    }
    
    @Override
    public void produceBatch(List<LogEntry> logEntries) {
        if (logEntries == null || logEntries.isEmpty()) {
            return;
        }
        
        long startTime = System.currentTimeMillis();
        int successCount = 0;
        int errorCount = 0;
        
        for (LogEntry logEntry : logEntries) {
            try {
                produceLog(logEntry);
                successCount++;
            } catch (Exception e) {
                errorCount++;
                // Log do erro sem interromper o batch
                System.err.println("Erro ao processar log do batch: " + e.getMessage());
            }
        }
        
        // Registrar métricas do batch
        metricsPort.recordBatchProcessing(logEntries.size(), successCount, errorCount);
        metricsPort.recordBatchProcessingTime(System.currentTimeMillis() - startTime);
    }
}
