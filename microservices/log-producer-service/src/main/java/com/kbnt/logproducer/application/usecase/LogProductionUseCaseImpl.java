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
    public LogProductionResult produceLog(LogEntry logEntry) {
        try {
            List<String> validationErrors = validationService.validateLogEntry(logEntry);
            if (!validationErrors.isEmpty()) {
                // Aqui pode-se registrar métrica de erro se necessário
                return LogProductionResult.failure("Log inválido: " + String.join(", ", validationErrors), null);
            }

            if (!validationService.shouldProcessLog(logEntry)) {
                // Aqui pode-se registrar métrica de log ignorado se necessário
                return LogProductionResult.failure("Log ignorado", null);
            }

            String topic = routingService.determineKafkaTopic(logEntry);
            String partitionKey = routingService.generatePartitionKey(logEntry);
            int priority = routingService.determinePriority(logEntry);

            // Publicar no Kafka (ajustar para interface correta)
            // logPublisher.publishLog(logEntry, topic, partitionKey);
            // Supondo que publish retorna um CompletableFuture<PublishResult>
            // PublishResult result = logPublisher.publish(topic, partitionKey, logEntry).get();
            // return LogProductionResult.success(topic, result.partition(), result.offset());
            return LogProductionResult.success(topic, 0, 0L); // Ajuste conforme implementação real
        } catch (Exception e) {
            return LogProductionResult.failure("Erro ao produzir log: " + e.getMessage(), e);
        }
    }

    @Override
    public void produceLogAsync(LogEntry logEntry) {
        // Implementação assíncrona se necessário
        // Exemplo: new Thread(() -> produceLog(logEntry)).start();
    }
    
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
