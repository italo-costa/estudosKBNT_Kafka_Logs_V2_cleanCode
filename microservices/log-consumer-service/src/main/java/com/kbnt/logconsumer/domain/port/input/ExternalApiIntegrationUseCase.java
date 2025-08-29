package com.kbnt.logconsumer.domain.port.input;

import com.kbnt.logconsumer.domain.model.ConsumedLog;
import com.kbnt.logconsumer.domain.model.ApiEndpoint;

/**
 * Port de entrada para integração com APIs externas
 */
public interface ExternalApiIntegrationUseCase {
    
    /**
     * Envia log para API externa
     * @param consumedLog o log a ser enviado
     * @param endpoint o endpoint da API
     */
    void sendToExternalApi(ConsumedLog consumedLog, ApiEndpoint endpoint);
    
    /**
     * Notifica sistema externo sobre log crítico
     * @param consumedLog o log crítico
     */
    void notifyCriticalLog(ConsumedLog consumedLog);
    
    /**
     * Envia logs de auditoria para sistema externo
     * @param consumedLog o log de auditoria
     */
    void sendAuditLog(ConsumedLog consumedLog);
    
    /**
     * Processa transação financeira via API externa
     * @param consumedLog o log da transação
     */
    void processFinancialTransaction(ConsumedLog consumedLog);
}
