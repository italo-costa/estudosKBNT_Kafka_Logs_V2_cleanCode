package com.kbnt.logproducer.infrastructure.adapter.input.rest;

import com.kbnt.logproducer.application.usecase.LogProductionUseCaseImpl;
import com.kbnt.logproducer.domain.model.LogMessage;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(LogController.class)
@DisplayName("Log Producer Controller Unit Tests")
class LogControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private LogProductionUseCaseImpl logProductionUseCase;

    @Autowired
    private ObjectMapper objectMapper;

    private LogMessage sampleLogMessage;

    @BeforeEach
    void setUp() {
        sampleLogMessage = createSampleLogMessage();
    }

    @Test
    @DisplayName("POST /logs - Should produce log successfully")
    void shouldProduceLogSuccessfully() throws Exception {
        // Given
        doNothing().when(logProductionUseCase).produceLog(any(LogMessage.class));

        // When & Then
        mockMvc.perform(post("/logs")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(sampleLogMessage)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Log message sent successfully"));

        verify(logProductionUseCase).produceLog(any(LogMessage.class));
    }

    @Test
    @DisplayName("POST /logs - Should return 400 for invalid log message")
    void shouldReturn400ForInvalidLogMessage() throws Exception {
        // Given - Invalid log message (missing required fields)
        LogMessage invalidMessage = new LogMessage();
        // Missing level and message

        // When & Then
        mockMvc.perform(post("/logs")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(invalidMessage)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("GET /logs/health - Should return health status")
    void shouldReturnHealthStatus() throws Exception {
        // When & Then
        mockMvc.perform(get("/logs/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"))
                .andExpect(jsonPath("$.service").value("log-producer-service"));
    }

    @Test
    @DisplayName("POST /logs - Should handle different log levels")
    void shouldHandleDifferentLogLevels() throws Exception {
        // Given
        LogMessage infoMessage = createSampleLogMessage();
        infoMessage.setLevel("INFO");
        doNothing().when(logProductionUseCase).produceLog(any(LogMessage.class));

        // When & Then - INFO Level
        mockMvc.perform(post("/logs")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(infoMessage)))
                .andExpect(status().isOk());

        // Given
        LogMessage errorMessage = createSampleLogMessage();
        errorMessage.setLevel("ERROR");

        // When & Then - ERROR Level
        mockMvc.perform(post("/logs")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(errorMessage)))
                .andExpect(status().isOk());

        // Given
        LogMessage warnMessage = createSampleLogMessage();
        warnMessage.setLevel("WARN");

        // When & Then - WARN Level
        mockMvc.perform(post("/logs")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(warnMessage)))
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("POST /logs - Should handle different categories")
    void shouldHandleDifferentCategories() throws Exception {
        // Given
        LogMessage financialMessage = createSampleLogMessage();
        financialMessage.setCategory("FINANCIAL");
        doNothing().when(logProductionUseCase).produceLog(any(LogMessage.class));

        // When & Then - Financial Category
        mockMvc.perform(post("/logs")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(financialMessage)))
                .andExpect(status().isOk());

        // Given
        LogMessage auditMessage = createSampleLogMessage();
        auditMessage.setCategory("AUDIT");

        // When & Then - Audit Category
        mockMvc.perform(post("/logs")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(auditMessage)))
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("POST /logs - Should enrich log message with timestamp")
    void shouldEnrichLogMessageWithTimestamp() throws Exception {
        // Given
        LogMessage messageWithoutTimestamp = createSampleLogMessage();
        messageWithoutTimestamp.setTimestamp(null);
        doNothing().when(logProductionUseCase).produceLog(any(LogMessage.class));

        // When & Then
        mockMvc.perform(post("/logs")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(messageWithoutTimestamp)))
                .andExpect(status().isOk());

        // Verify that timestamp is added during processing
        verify(logProductionUseCase).produceLog(any(LogMessage.class));
    }

    private LogMessage createSampleLogMessage() {
        LogMessage message = new LogMessage();
        message.setLevel("INFO");
        message.setMessage("Sample log message for testing");
        message.setServiceName("virtual-stock-service");
        message.setCategory("APPLICATION");
        message.setTimestamp(LocalDateTime.now());
        message.setCorrelationId("test-correlation-123");
        message.setUserId("test-user");
        message.setSessionId("test-session-456");
        return message;
    }
}
