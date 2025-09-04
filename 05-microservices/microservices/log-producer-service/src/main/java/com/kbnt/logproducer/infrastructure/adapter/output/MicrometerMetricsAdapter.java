package com.kbnt.logproducer.infrastructure.adapter.output;

import com.kbnt.logproducer.domain.port.output.MetricsPort;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Adaptador para métricas usando Micrometer
 */
@Component
public class MicrometerMetricsAdapter implements MetricsPort {
    @Override
    public void incrementLogCounter(String service, String level, String topic) {
        Counter.builder("logs.counter")
            .tag("service", service)
            .tag("level", level)
            .tag("topic", topic)
            .description("Contador de logs por serviço, nível e tópico")
            .register(meterRegistry)
            .increment();
    }
    @Override
    public void recordProcessingTime(String service, long processingTimeMs) {
        Timer.builder("logs.processing.time")
            .tag("service", service)
            .description("Tempo de processamento de logs individuais por serviço")
            .register(meterRegistry)
            .record(java.time.Duration.ofMillis(processingTimeMs));
    }
    @Override
    public void incrementErrorCounter(String service, String errorType) {
        Counter.builder("logs.error.counter")
            .tag("service", service)
            .tag("errorType", errorType)
            .description("Contador de erros por serviço e tipo")
            .register(meterRegistry)
            .increment();
    }
    @Override
    public void recordPayloadSize(String service, int payloadSize) {
        Counter.builder("logs.payload.size")
            .tag("service", service)
            .description("Tamanho do payload de logs")
            .register(meterRegistry)
            .increment(payloadSize);
    }
    // Implementação dos métodos da interface MetricsPort já está presente.
    // Se algum método estiver faltando, adicione métodos vazios para compatibilidade.
    
    private final Counter publishedLogsCounter;
    private final Counter validationErrorsCounter;
    private final Counter publishingErrorsCounter;
    private final Counter skippedLogsCounter;
    private final Counter highPriorityLogsCounter;
    private final Timer processingTimeTimer;
    private final Timer batchProcessingTimeTimer;
    private final MeterRegistry meterRegistry;
    
    // Contadores por nível de log
    private final Counter debugLogsCounter;
    private final Counter infoLogsCounter;
    private final Counter warnLogsCounter;
    private final Counter errorLogsCounter;
    private final Counter fatalLogsCounter;
    
    public MicrometerMetricsAdapter(MeterRegistry meterRegistry) {
        this.meterRegistry = meterRegistry;
        
        // Inicializar contadores
        this.publishedLogsCounter = Counter.builder("logs.published.total")
                .description("Total de logs publicados")
                .register(meterRegistry);
                
        this.validationErrorsCounter = Counter.builder("logs.validation.errors.total")
                .description("Total de erros de validação")
                .register(meterRegistry);
                
        this.publishingErrorsCounter = Counter.builder("logs.publishing.errors.total")
                .description("Total de erros de publicação")
                .register(meterRegistry);
                
        this.skippedLogsCounter = Counter.builder("logs.skipped.total")
                .description("Total de logs ignorados")
                .register(meterRegistry);
                
        this.highPriorityLogsCounter = Counter.builder("logs.high_priority.total")
                .description("Total de logs de alta prioridade")
                .register(meterRegistry);
        
        // Timers
        this.processingTimeTimer = Timer.builder("logs.processing.time")
                .description("Tempo de processamento de logs individuais")
                .register(meterRegistry);
                
        this.batchProcessingTimeTimer = Timer.builder("logs.batch.processing.time")
                .description("Tempo de processamento de batches")
                .register(meterRegistry);
        
        // Contadores por nível
        this.debugLogsCounter = Counter.builder("logs.level.debug.total")
                .description("Total de logs DEBUG")
                .register(meterRegistry);
                
        this.infoLogsCounter = Counter.builder("logs.level.info.total")
                .description("Total de logs INFO")
                .register(meterRegistry);
                
        this.warnLogsCounter = Counter.builder("logs.level.warn.total")
                .description("Total de logs WARN")
                .register(meterRegistry);
                
        this.errorLogsCounter = Counter.builder("logs.level.error.total")
                .description("Total de logs ERROR")
                .register(meterRegistry);
                
        this.fatalLogsCounter = Counter.builder("logs.level.fatal.total")
                .description("Total de logs FATAL")
                .register(meterRegistry);
    }
    
    @Override
    public void incrementPublishedLogs() {
        publishedLogsCounter.increment();
    }
    
    @Override
    public void incrementValidationErrors() {
        validationErrorsCounter.increment();
    }
    
    @Override
    public void incrementPublishingErrors() {
        publishingErrorsCounter.increment();
    }
    
    @Override
    public void incrementSkippedLogs() {
        skippedLogsCounter.increment();
    }
    
    @Override
    public void incrementHighPriorityLogs() {
        highPriorityLogsCounter.increment();
    }
    
    @Override
    public void recordLogLevel(String level) {
        switch (level.toUpperCase()) {
            case "DEBUG":
                debugLogsCounter.increment();
                break;
            case "INFO":
                infoLogsCounter.increment();
                break;
            case "WARN":
                warnLogsCounter.increment();
                break;
            case "ERROR":
                errorLogsCounter.increment();
                break;
            case "FATAL":
                fatalLogsCounter.increment();
                break;
            default:
                // Para níveis desconhecidos, usar um contador genérico
                Counter.builder("logs.level.unknown.total")
                        .tag("level", level)
                        .description("Total de logs de nível desconhecido")
                        .register(meterRegistry)
                        .increment();
        }
    }
    
    @Override
    public void recordLogService(String serviceName) {
        Counter.builder("logs.service.total")
                .tag("service", serviceName)
                .description("Total de logs por serviço")
                .register(meterRegistry)
                .increment();
    }
    
    @Override
    public void recordProcessingTime(long durationMillis) {
        processingTimeTimer.record(Duration.ofMillis(durationMillis));
    }
    
    @Override
    public void recordBatchProcessing(int totalLogs, int successCount, int errorCount) {
        // Registrar métricas do batch
        Counter.builder("logs.batch.total")
                .description("Total de batches processados")
                .register(meterRegistry)
                .increment();
                
        Counter.builder("logs.batch.items.total")
                .description("Total de itens em batches")
                .register(meterRegistry)
                .increment(totalLogs);
                
        Counter.builder("logs.batch.success.total")
                .description("Total de itens processados com sucesso em batches")
                .register(meterRegistry)
                .increment(successCount);
                
        Counter.builder("logs.batch.errors.total")
                .description("Total de erros em batches")
                .register(meterRegistry)
                .increment(errorCount);
        
        // Registrar taxa de sucesso como gauge
        meterRegistry.gauge("logs.batch.success.rate", (double) successCount / totalLogs);
    }
    
    @Override
    public void recordBatchProcessingTime(long durationMillis) {
        batchProcessingTimeTimer.record(Duration.ofMillis(durationMillis));
    }
}
