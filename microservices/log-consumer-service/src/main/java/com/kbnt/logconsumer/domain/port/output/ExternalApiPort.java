package com.kbnt.logconsumer.domain.port.output;

import com.kbnt.logconsumer.domain.model.ConsumedLog;
import com.kbnt.logconsumer.domain.model.ApiEndpoint;
import com.kbnt.logconsumer.domain.model.ExternalApiResponse;

/**
 * Port de saída para chamadas de APIs externas
 */
public interface ExternalApiPort {
    
    /**
     * Faz chamada HTTP para API externa
     * @param endpoint o endpoint da API
     * @param payload o payload a ser enviado
     * @return resposta da API
     */
    ExternalApiResponse callApi(ApiEndpoint endpoint, String payload);
    
    /**
     * Envia notificação para sistema externo
     * @param consumedLog o log para notificação
     * @return resposta da API
     */
    ExternalApiResponse sendNotification(ConsumedLog consumedLog);
    
    /**
     * Envia dados de auditoria para sistema externo
     * @param consumedLog o log de auditoria
     * @return resposta da API
     */
    ExternalApiResponse sendAuditData(ConsumedLog consumedLog);
    
    /**
     * Processa transação financeira via API
     * @param consumedLog o log da transação
     * @return resposta da API
     */
    ExternalApiResponse processTransaction(ConsumedLog consumedLog);
    
    /**
     * Verifica o status de saúde da API externa
     * @param endpoint o endpoint para verificação
     * @return true se a API está saudável
     */
    boolean isApiHealthy(ApiEndpoint endpoint);
}
