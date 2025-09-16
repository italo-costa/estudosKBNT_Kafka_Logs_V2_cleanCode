# Diagnóstico e Solução - Timeout no Postman

## Status da Aplicação: ✅ FUNCIONANDO

A aplicação Virtual Stock Service está operacional e respondendo corretamente.

## Testes de Conectividade Realizados

### ✅ Funcionando - WSL2 curl
```bash
curl http://localhost:8084/api/v1/virtual-stock/stocks
curl http://172.30.221.62:8084/api/v1/virtual-stock/stocks
```
**Resultado**: Resposta HTTP 200 com dados JSON

### ❌ Problema - PowerShell Windows
```powershell
Invoke-RestMethod -Uri "http://172.30.221.62:8084/api/v1/virtual-stock/stocks"
```
**Resultado**: Timeout após 30 segundos

## Causa Provável do Timeout

O problema está relacionado à conectividade entre o Windows e o WSL2. O Postman, rodando no Windows, não consegue acessar diretamente os serviços no WSL2 sem configuração adicional.

## Soluções Recomendadas

### Solução 1: Port Forwarding WSL2 (Recomendada)

Execute como **Administrador** no PowerShell:

```powershell
# Obter IP do WSL2
$wslIP = (wsl hostname -I).Split()[0]

# Configurar port forwarding
netsh interface portproxy add v4tov4 listenport=8084 listenaddress=0.0.0.0 connectport=8084 connectaddress=$wslIP

# Configurar firewall
New-NetFireWallRule -DisplayName 'WSL2 Virtual Stock Port 8084' -Direction Inbound -LocalPort 8084 -Action Allow -Protocol TCP

# Verificar
netsh interface portproxy show all
```

Após essa configuração, use no Postman:
- **URL**: `http://localhost:8084/api/v1/virtual-stock/stocks`

### Solução 2: Usar IP do WSL2 com Timeout Maior

No Postman, configure:
- **URL**: `http://172.30.221.62:8084/api/v1/virtual-stock/stocks`
- **Timeout**: 60 segundos (em Settings > General > Request timeout)

### Solução 3: Acessar via WSL2 diretamente

Se você tem acesso ao WSL2, pode usar:
```bash
wsl curl http://localhost:8084/api/v1/virtual-stock/stocks
```

## Endpoints Disponíveis

### Teste de Conectividade
- `GET http://localhost:8084/` - Retorna "Virtual Stock Service is running!"
- `GET http://localhost:8084/ping` - Retorna "pong"

### API Endpoints
- `GET http://localhost:8084/api/v1/virtual-stock/stocks` - Lista todos os stocks
- `GET http://localhost:8084/actuator/health` - Health check

### Documentação
- `GET http://localhost:8084/swagger-ui.html` - Swagger UI
- `GET http://localhost:8084/v3/api-docs` - OpenAPI specs

## Configuração dos Serviços

### Aplicação Atual Rodando:
- **Virtual Stock Service**: localhost:8084 (Windows) / 172.30.221.62:8084 (WSL2)
- **PostgreSQL**: localhost:5432
- **Status**: Ambos healthy e operacionais

### Para Parar a Aplicação:
```bash
cd /mnt/c/workspace/estudosKBNT_Kafka_Logs_V2_cleanCode
docker-compose -f docker-compose-simple-test.yml down
```

### Para Reiniciar a Aplicação:
```bash
cd /mnt/c/workspace/estudosKBNT_Kafka_Logs_V2_cleanCode
docker-compose -f docker-compose-simple-test.yml up -d
```

## Exemplo de Resposta da API

```json
{
  "success": true,
  "data": [
    {
      "stockId": {"value": "8ca83ddd-b481-4eca-ae13-79f8c8d47eed"},
      "productId": {"value": "Gal-003"},
      "symbol": "X5 Galaxy",
      "productName": "X5 Pocco Galaxy 6S Inc Ltda",
      "quantity": 50,
      "unitPrice": 1400.80,
      "status": "AVAILABLE",
      "lastUpdated": "2025-09-13T13:23:45.730653",
      "lastUpdatedBy": "admin",
      "available": true,
      "totalValue": 70040.00,
      "lowStock": false
    }
  ],
  "message": "Stocks retrieved successfully",
  "timestamp": "2025-09-13T13:23:58.149368707"
}
```

---
**Data**: 13 de Setembro de 2025  
**Status**: Aplicação operacional, problema de conectividade Windows/WSL2 identificado
