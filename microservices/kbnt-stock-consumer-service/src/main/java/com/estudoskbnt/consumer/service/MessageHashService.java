package com.estudoskbnt.consumer.service;

import com.estudoskbnt.consumer.model.StockUpdateMessage;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.springframework.stereotype.Service;
import java.security.MessageDigest;

@Service
public class MessageHashService {
    private final ObjectMapper objectMapper;

    public MessageHashService(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    /**
     * Calculate SHA-256 hash for message verification
     */
    public String calculateMessageHash(StockUpdateMessage message) {
        try {
            // Create a copy without the hash field for calculation
            StockUpdateMessage messageForHash = StockUpdateMessage.builder()
                    .correlationId(message.getCorrelationId())
                    .productId(message.getProductId())
                    .quantity(message.getQuantity())
                    .price(message.getPrice())
                    .operation(message.getOperation())
                    .category(message.getCategory())
                    .supplier(message.getSupplier())
                    .location(message.getLocation())
                    .publishedAt(message.getPublishedAt())
                    .priority(message.getPriority())
                    .deadline(message.getDeadline())
                    .build();

            String messageJson = objectMapper.writeValueAsString(messageForHash);
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hashBytes = digest.digest(messageJson.getBytes("UTF-8"));

            StringBuilder hexString = new StringBuilder();
            for (byte b : hashBytes) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) {
                    hexString.append('0');
                }
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (Exception e) {
            throw new RuntimeException("Hash calculation failed", e);
        }
    }

    /**
     * Generate unique message ID from consumer record
     */
    public String generateMessageId(ConsumerRecord<String, String> record) {
        return String.format("%s-%d-%d-%d",
                record.topic(),
                record.partition(),
                record.offset(),
                record.timestamp());
    }
}
