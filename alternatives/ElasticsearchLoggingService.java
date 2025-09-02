package com.estudoskbnt.consumer.service;

import co.elastic.clients.elasticsearch.ElasticsearchClient;
import co.elastic.clients.elasticsearch._types.query_dsl.Query;
import co.elastic.clients.elasticsearch.core.IndexRequest;
import co.elastic.clients.elasticsearch.core.SearchRequest;
import co.elastic.clients.elasticsearch.core.SearchResponse;
import co.elastic.clients.elasticsearch.core.search.Hit;
import com.estudoskbnt.consumer.document.ConsumptionLogDocument;
import com.estudoskbnt.consumer.model.ProcessingStatistics;
import com.estudoskbnt.consumer.model.SearchResults;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.stream.Collectors;

/**
 * Elasticsearch Logging Service
 * 
 * Handles all Elasticsearch operations for consumption logging including
 * indexing, searching, and analytics operations.
 * 
 * @author KBNT Development Team
 * @version 1.0.0
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ElasticsearchLoggingService {
    
    private final ElasticsearchClient elasticsearchClient;
    private final ObjectMapper objectMapper;
    
    @Value("${elasticsearch.index.pattern:kbnt-consumption-logs}")
    private String indexPattern;
    
    @Value("${elasticsearch.enabled:true}")
    private boolean elasticsearchEnabled;
    
    @Value("${spring.application.name:kbnt-consumer}")
    private String applicationName;
    
    @Value("${spring.profiles.active:unknown}")
    private String environment;
    
    private static final DateTimeFormatter INDEX_DATE_FORMAT = DateTimeFormatter.ofPattern("yyyy.MM.dd");
    
    /**
     * Log consumption event to Elasticsearch
     */
    @Async
    public CompletableFuture<Boolean> logConsumption(ConsumptionLogDocument logDocument) {
        if (!elasticsearchEnabled) {
            log.debug("Elasticsearch disabled, logging to application log instead");
            logToApplicationLog(logDocument);
            return CompletableFuture.completedFuture(true);
        }
        
        return CompletableFuture.supplyAsync(() -> {
            try {
                // Enrich document with environment information
                enrichDocument(logDocument);
                
                // Create index request
                IndexRequest<ConsumptionLogDocument> indexRequest = IndexRequest.of(i -> i
                    .index(getCurrentIndex())
                    .document(logDocument)
                    .id(generateDocumentId(logDocument))
                );
                
                // Execute indexing
                var response = elasticsearchClient.index(indexRequest);
                
                if (response.result().name().equals("CREATED") || response.result().name().equals("UPDATED")) {
                    log.debug("Successfully logged consumption event to Elasticsearch: {}", 
                            logDocument.getCorrelationId());
                    return true;
                } else {
                    log.warn("Unexpected Elasticsearch response: {}", response.result());
                    return false;
                }
                
            } catch (Exception e) {
                log.error("Failed to log consumption to Elasticsearch: {}", logDocument.getCorrelationId(), e);
                // Fallback to application log
                logToApplicationLog(logDocument);
                return false;
            }
        });
    }
    
    /**
     * Get processing statistics for a given time period
     */
    public CompletableFuture<ProcessingStatistics> getProcessingStatistics(Duration period) {
        return CompletableFuture.supplyAsync(() -> {
            try {
                LocalDateTime since = LocalDateTime.now().minus(period);
                String sinceStr = since.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME);
                
                SearchRequest searchRequest = SearchRequest.of(s -> s
                    .index(indexPattern + "-*")
                    .size(0) // We only want aggregations
                    .query(q -> q.range(r -> r
                        .field("@timestamp")
                        .gte(sinceStr)
                    ))
                    .aggregations("status_counts", a -> a
                        .terms(t -> t
                            .field("status.keyword")
                            .size(10)
                        )
                    )
                    .aggregations("avg_processing_time", a -> a
                        .avg(avg -> avg
                            .field("processing_time_ms")
                        )
                    )
                    .aggregations("max_processing_time", a -> a
                        .max(max -> max
                            .field("processing_time_ms")
                        )
                    )
                    .aggregations("product_distribution", a -> a
                        .terms(t -> t
                            .field("product_id.keyword")
                            .size(20)
                        )
                    )
                );
                
                SearchResponse<ConsumptionLogDocument> response = 
                    elasticsearchClient.search(searchRequest, ConsumptionLogDocument.class);
                
                return buildStatisticsFromResponse(response, period);
                
            } catch (Exception e) {
                log.error("Failed to get processing statistics from Elasticsearch", e);
                return ProcessingStatistics.empty();
            }
        });
    }
    
    /**
     * Check if a message was already processed (duplicate detection)
     */
    public CompletableFuture<Boolean> checkDuplicateMessage(String correlationId, String messageHash) {
        return CompletableFuture.supplyAsync(() -> {
            try {
                SearchRequest searchRequest = SearchRequest.of(s -> s
                    .index(indexPattern + "-*")
                    .size(1)
                    .query(q -> q.bool(b -> b
                        .must(m -> m.term(t -> t.field("correlation_id.keyword").value(correlationId)))
                        .must(m -> m.term(t -> t.field("message_hash.keyword").value(messageHash)))
                        .must(m -> m.term(t -> t.field("status.keyword").value("SUCCESS")))
                    ))
                );
                
                SearchResponse<ConsumptionLogDocument> response = 
                    elasticsearchClient.search(searchRequest, ConsumptionLogDocument.class);
                
                boolean isDuplicate = response.hits().total().value() > 0;
                
                if (isDuplicate) {
                    log.info("Duplicate message detected - Correlation ID: {}, Hash: {}", 
                            correlationId, messageHash);
                }
                
                return isDuplicate;
                
            } catch (Exception e) {
                log.error("Failed to check duplicate message in Elasticsearch", e);
                // Fail-safe: allow processing if we can't check
                return false;
            }
        });
    }
    
    /**
     * Search logs with flexible query
     */
    public CompletableFuture<SearchResults> searchLogs(String queryString, int from, int size) {
        return CompletableFuture.supplyAsync(() -> {
            try {
                SearchRequest.Builder searchBuilder = new SearchRequest.Builder()
                    .index(indexPattern + "-*")
                    .from(from)
                    .size(size)
                    .sort(so -> so.field(f -> f.field("@timestamp").order(co.elastic.clients.elasticsearch._types.SortOrder.Desc)));
                
                // Add query if provided
                if (queryString != null && !queryString.trim().isEmpty()) {
                    searchBuilder.query(q -> q.queryString(qs -> qs.query(queryString)));
                } else {
                    searchBuilder.query(q -> q.matchAll(ma -> ma));
                }
                
                SearchRequest searchRequest = searchBuilder.build();
                
                SearchResponse<ConsumptionLogDocument> response = 
                    elasticsearchClient.search(searchRequest, ConsumptionLogDocument.class);
                
                List<ConsumptionLogDocument> documents = response.hits().hits().stream()
                    .map(Hit::source)
                    .collect(Collectors.toList());
                
                return SearchResults.builder()
                    .documents(documents)
                    .totalHits(response.hits().total().value())
                    .from(from)
                    .size(size)
                    .queryString(queryString)
                    .build();
                
            } catch (Exception e) {
                log.error("Failed to search logs in Elasticsearch", e);
                return SearchResults.empty();
            }
        });
    }
    
    /**
     * Get recent error logs
     */
    public CompletableFuture<List<ConsumptionLogDocument>> getRecentErrors(Duration period) {
        return CompletableFuture.supplyAsync(() -> {
            try {
                LocalDateTime since = LocalDateTime.now().minus(period);
                String sinceStr = since.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME);
                
                SearchRequest searchRequest = SearchRequest.of(s -> s
                    .index(indexPattern + "-*")
                    .size(100)
                    .query(q -> q.bool(b -> b
                        .must(m -> m.range(r -> r
                            .field("@timestamp")
                            .gte(sinceStr)
                        ))
                        .must(m -> m.terms(t -> t
                            .field("status.keyword")
                            .terms(tv -> tv.value("FAILED"), tv -> tv.value("RETRY_EXHAUSTED"))
                        ))
                    ))
                    .sort(so -> so.field(f -> f.field("@timestamp").order(co.elastic.clients.elasticsearch._types.SortOrder.Desc)))
                );
                
                SearchResponse<ConsumptionLogDocument> response = 
                    elasticsearchClient.search(searchRequest, ConsumptionLogDocument.class);
                
                return response.hits().hits().stream()
                    .map(Hit::source)
                    .collect(Collectors.toList());
                
            } catch (Exception e) {
                log.error("Failed to get recent errors from Elasticsearch", e);
                return List.of();
            }
        });
    }
    
    /**
     * Get slowest processing operations
     */
    public CompletableFuture<List<ConsumptionLogDocument>> getSlowestOperations(Duration period, int limit) {
        return CompletableFuture.supplyAsync(() -> {
            try {
                LocalDateTime since = LocalDateTime.now().minus(period);
                String sinceStr = since.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME);
                
                SearchRequest searchRequest = SearchRequest.of(s -> s
                    .index(indexPattern + "-*")
                    .size(limit)
                    .query(q -> q.bool(b -> b
                        .must(m -> m.range(r -> r
                            .field("@timestamp")
                            .gte(sinceStr)
                        ))
                        .must(m -> m.exists(e -> e.field("processing_time_ms")))
                    ))
                    .sort(so -> so.field(f -> f.field("processing_time_ms").order(co.elastic.clients.elasticsearch._types.SortOrder.Desc)))
                );
                
                SearchResponse<ConsumptionLogDocument> response = 
                    elasticsearchClient.search(searchRequest, ConsumptionLogDocument.class);
                
                return response.hits().hits().stream()
                    .map(Hit::source)
                    .collect(Collectors.toList());
                
            } catch (Exception e) {
                log.error("Failed to get slowest operations from Elasticsearch", e);
                return List.of();
            }
        });
    }
    
    /**
     * Get current index name based on date
     */
    private String getCurrentIndex() {
        String dateSuffix = LocalDateTime.now().format(INDEX_DATE_FORMAT);
        return indexPattern + "-" + dateSuffix;
    }
    
    /**
     * Generate unique document ID
     */
    private String generateDocumentId(ConsumptionLogDocument logDocument) {
        return String.format("%s_%s_%d_%d", 
                logDocument.getCorrelationId(),
                logDocument.getTopic(),
                logDocument.getPartition(),
                logDocument.getOffset()
        );
    }
    
    /**
     * Enrich document with environment information
     */
    private void enrichDocument(ConsumptionLogDocument logDocument) {
        logDocument.setEnvironment(environment);
        logDocument.setVersion("1.0.0");
        
        if (logDocument.getTimestamp() == null) {
            logDocument.setTimestamp(LocalDateTime.now());
        }
        
        // Set consumer instance information
        if (logDocument.getConsumerInstance() == null) {
            logDocument.setConsumerInstance(applicationName + "-" + getHostname());
        }
    }
    
    /**
     * Build statistics from Elasticsearch response
     */
    private ProcessingStatistics buildStatisticsFromResponse(SearchResponse<ConsumptionLogDocument> response, Duration period) {
        var statusCounts = response.aggregations().get("status_counts").sterms();
        var avgProcessingTime = response.aggregations().get("avg_processing_time").avg();
        var maxProcessingTime = response.aggregations().get("max_processing_time").max();
        var productDistribution = response.aggregations().get("product_distribution").sterms();
        
        ProcessingStatistics.Builder statsBuilder = ProcessingStatistics.builder()
                .periodHours((int) period.toHours())
                .totalMessages(response.hits().total().value())
                .generatedAt(LocalDateTime.now());
        
        // Process status counts
        statusCounts.buckets().array().forEach(bucket -> {
            String status = bucket.key().stringValue();
            long count = bucket.docCount();
            
            switch (status) {
                case "SUCCESS":
                    statsBuilder.successfulMessages(count);
                    break;
                case "FAILED":
                case "RETRY_EXHAUSTED":
                    statsBuilder.failedMessages(count);
                    break;
            }
        });
        
        // Set processing times
        if (avgProcessingTime.value() != null) {
            statsBuilder.averageProcessingTimeMs(avgProcessingTime.value().longValue());
        }
        if (maxProcessingTime.value() != null) {
            statsBuilder.maxProcessingTimeMs(maxProcessingTime.value().longValue());
        }
        
        return statsBuilder.build();
    }
    
    /**
     * Fallback to application logging
     */
    private void logToApplicationLog(ConsumptionLogDocument logDocument) {
        log.info("CONSUMPTION_LOG: correlationId={}, status={}, productId={}, processingTimeMs={}, topic={}, partition={}, offset={}", 
                logDocument.getCorrelationId(),
                logDocument.getStatus(),
                logDocument.getProductId(),
                logDocument.getProcessingTimeMs(),
                logDocument.getTopic(),
                logDocument.getPartition(),
                logDocument.getOffset()
        );
    }
    
    /**
     * Get hostname for consumer instance identification
     */
    private String getHostname() {
        try {
            return java.net.InetAddress.getLocalHost().getHostName();
        } catch (Exception e) {
            return "unknown";
        }
    }
}
