package com.estudoskbnt.consumer.repository;

import com.estudoskbnt.consumer.entity.ConsumptionLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Repository for Consumption Log entities
 * 
 * Provides data access methods for consumption audit logs with
 * custom queries for monitoring and reporting.
 * 
 * @author KBNT Development Team
 * @version 1.0.0
 */
@Repository
public interface ConsumptionLogRepository extends JpaRepository<ConsumptionLog, Long> {
    
    /**
     * Find consumption log by correlation ID
     */
    Optional<ConsumptionLog> findByCorrelationId(String correlationId);
    
    /**
     * Find all logs for a specific product
     */
    List<ConsumptionLog> findByProductIdOrderByConsumedAtDesc(String productId);
    
    /**
     * Find logs by processing status
     */
    List<ConsumptionLog> findByStatusOrderByConsumedAtDesc(ConsumptionLog.ProcessingStatus status);
    
    /**
     * Find logs within a time range
     */
    List<ConsumptionLog> findByConsumedAtBetweenOrderByConsumedAtDesc(
            LocalDateTime startTime, LocalDateTime endTime);
    
    /**
     * Find logs by topic and partition
     */
    List<ConsumptionLog> findByTopicAndPartitionIdOrderByOffsetDesc(String topic, Integer partitionId);
    
    /**
     * Count successful processings in the last period
     */
    @Query("SELECT COUNT(cl) FROM ConsumptionLog cl " +
           "WHERE cl.status = 'SUCCESS' AND cl.consumedAt >= :since")
    long countSuccessfulProcessingsSince(@Param("since") LocalDateTime since);
    
    /**
     * Count failed processings in the last period
     */
    @Query("SELECT COUNT(cl) FROM ConsumptionLog cl " +
           "WHERE cl.status IN ('FAILED', 'RETRY_EXHAUSTED') AND cl.consumedAt >= :since")
    long countFailedProcessingsSince(@Param("since") LocalDateTime since);
    
    /**
     * Calculate average processing time for successful operations
     */
    @Query("SELECT AVG(cl.totalProcessingTimeMs) FROM ConsumptionLog cl " +
           "WHERE cl.status = 'SUCCESS' AND cl.totalProcessingTimeMs IS NOT NULL " +
           "AND cl.consumedAt >= :since")
    Double getAverageProcessingTimeSince(@Param("since") LocalDateTime since);
    
    /**
     * Find slowest processings (top N by processing time)
     */
    @Query("SELECT cl FROM ConsumptionLog cl " +
           "WHERE cl.totalProcessingTimeMs IS NOT NULL " +
           "AND cl.consumedAt >= :since " +
           "ORDER BY cl.totalProcessingTimeMs DESC")
    Page<ConsumptionLog> findSlowestProcessingsSince(@Param("since") LocalDateTime since, Pageable pageable);
    
    /**
     * Find logs with API errors
     */
    @Query("SELECT cl FROM ConsumptionLog cl " +
           "WHERE cl.apiResponseCode >= 400 " +
           "AND cl.consumedAt >= :since " +
           "ORDER BY cl.consumedAt DESC")
    List<ConsumptionLog> findApiErrorsSince(@Param("since") LocalDateTime since);
    
    /**
     * Count messages by product in the last period
     */
    @Query("SELECT cl.productId, COUNT(cl) FROM ConsumptionLog cl " +
           "WHERE cl.consumedAt >= :since " +
           "GROUP BY cl.productId " +
           "ORDER BY COUNT(cl) DESC")
    List<Object[]> countMessagesByProductSince(@Param("since") LocalDateTime since);
    
    /**
     * Find logs requiring retry
     */
    @Query("SELECT cl FROM ConsumptionLog cl " +
           "WHERE cl.status = 'RETRY_SCHEDULED' " +
           "AND cl.retryCount < :maxRetries " +
           "ORDER BY cl.consumedAt ASC")
    List<ConsumptionLog> findLogsRequiringRetry(@Param("maxRetries") int maxRetries);
    
    /**
     * Get processing statistics for monitoring
     */
    @Query("SELECT " +
           "COUNT(cl) as total, " +
           "SUM(CASE WHEN cl.status = 'SUCCESS' THEN 1 ELSE 0 END) as successful, " +
           "SUM(CASE WHEN cl.status IN ('FAILED', 'RETRY_EXHAUSTED') THEN 1 ELSE 0 END) as failed, " +
           "AVG(cl.totalProcessingTimeMs) as avgProcessingTime, " +
           "MAX(cl.totalProcessingTimeMs) as maxProcessingTime " +
           "FROM ConsumptionLog cl " +
           "WHERE cl.consumedAt >= :since")
    Object[] getProcessingStatisticsSince(@Param("since") LocalDateTime since);
    
    /**
     * Find recent logs for a specific topic
     */
    @Query("SELECT cl FROM ConsumptionLog cl " +
           "WHERE cl.topic = :topic " +
           "AND cl.consumedAt >= :since " +
           "ORDER BY cl.consumedAt DESC")
    Page<ConsumptionLog> findRecentLogsByTopic(
            @Param("topic") String topic, 
            @Param("since") LocalDateTime since, 
            Pageable pageable);
    
    /**
     * Delete old logs (for cleanup)
     */
    @Query("DELETE FROM ConsumptionLog cl WHERE cl.consumedAt < :cutoffDate")
    void deleteLogsOlderThan(@Param("cutoffDate") LocalDateTime cutoffDate);
    
    /**
     * Check if a message was already processed (idempotency check)
     */
    @Query("SELECT CASE WHEN COUNT(cl) > 0 THEN true ELSE false END " +
           "FROM ConsumptionLog cl " +
           "WHERE cl.correlationId = :correlationId " +
           "AND cl.messageHash = :messageHash " +
           "AND cl.status = 'SUCCESS'")
    boolean isMessageAlreadyProcessed(
            @Param("correlationId") String correlationId,
            @Param("messageHash") String messageHash);
}
