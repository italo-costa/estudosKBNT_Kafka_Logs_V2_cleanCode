# KBNT Virtual Stock Service - Guia de Testes com Postman

## 📋 Resumo do Projeto

A aplicação **KBNT Virtual Stock Service** foi levantada com sucesso no ambiente Linux virtualizado (WSL2) utilizando Docker Compose. Todo o stack está funcionando e pronto para testes.

## 🏗️ Arquitetura Implementada

- **Arquitetura Hexagonal/Clean**: Separação clara entre domínio, aplicação e infraestrutura
- **Spring Boot**: Framework principal com auto-configuração
- **PostgreSQL**: Banco de dados principal para persistência 
- **Apache Kafka**: Sistema de mensageria para eventos
- **Docker Compose**: Orquestração de todos os serviços
- **Spring Cloud Gateway**: API Gateway (planejado)

## 🌐 Acesso aos Serviços

### Endereços de Acesso do Windows
- **Virtual Stock Service**: `http://172.30.221.62:8080`
- **PostgreSQL**: `172.30.221.62:5432`
- **Kafka**: `172.30.221.62:9092`
- **Elasticsearch**: `http://172.30.221.62:9200`
- **Grafana**: `http://172.30.221.62:3000`
- **Prometheus**: `http://172.30.221.62:9090`

## 📊 Status dos Serviços

✅ **Virtual Stock Service**: Operacional na porta 8080  
✅ **PostgreSQL**: Operacional na porta 5432  
✅ **Apache Kafka**: Cluster operacional (portas 9092-9094)  
✅ **Elasticsearch**: Operacional na porta 9200  
✅ **Monitoring Stack**: Prometheus (9090) e Grafana (3000)  

## 🔧 Importando a Coleção no Postman

### Passo 1: Baixar o Arquivo da Coleção
1. Navegue até: `c:\\workspace\\estudosKBNT_Kafka_Logs_V2_cleanCode\\`
2. Localize o arquivo: `KBNT_Virtual_Stock_Service_API.postman_collection.json`

### Passo 2: Importar no Postman
1. Abra o **Postman** no Windows
2. Clique em **Import** (botão no canto superior esquerdo)
3. Selecione **Upload Files**
4. Navegue e selecione o arquivo `KBNT_Virtual_Stock_Service_API.postman_collection.json`
5. Clique em **Import**

### Passo 3: Verificar Configuração
Após a importação, você deve ver:
- **Collection**: "KBNT Virtual Stock Service API"
- **Environment Variable**: `baseUrl = http://172.30.221.62:8080`

## 🧪 Sequência de Testes Recomendada

### 1. Verificação de Saúde dos Serviços
```
GET /actuator/health
```
**Resultado Esperado**: Status UP com componentes detalhados

### 2. Criação de Dados de Teste
Execute as requisições na pasta "Sample Test Data":
- **Create Apple Stock** (AAPL)
- **Create Microsoft Stock** (MSFT)  
- **Create Google Stock** (GOOGL)

### 3. Operações CRUD
- **Get All Stocks**: Listar todos os estoques
- **Get Stock by ID**: Buscar estoque específico
- **Update Stock Price**: Atualizar preço
- **Update Stock Quantity**: Atualizar quantidade

## 📄 Exemplos de Requisições

### Criar Novo Estoque
```json
POST /api/v1/virtual-stock/stocks
Content-Type: application/json

{
  "productId": "PROD-001",
  "symbol": "AAPL",
  "productName": "Apple Inc. Stock",
  "quantity": 100,
  "unitPrice": 150.75,
  "createdBy": "admin"
}
```

### Listar Todos os Estoques
```json
GET /api/v1/virtual-stock/stocks
```

### Atualizar Preço do Estoque
```json
PUT /api/v1/virtual-stock/stocks/{stockId}/price
Content-Type: application/json

{
  "newPrice": 155.50,
  "updatedBy": "trader"
}
```

## 🔍 Validação e Monitoramento

### Endpoints de Monitoramento Disponíveis:
- **Health Check**: `/actuator/health`
- **Metrics**: `/actuator/metrics`
- **Info**: `/actuator/info`

### Logs de Aplicação:
```bash
# Acessar logs via WSL
docker-compose -f docker-compose.scalable-simple.yml logs virtual-stock-service-1
```

## 🛠️ Resolução de Problemas

### Se a aplicação não responder:
1. Verificar se o WSL está executando:
   ```cmd
   wsl --list --verbose
   ```

2. Verificar serviços Docker:
   ```bash
   docker-compose -f docker-compose.scalable-simple.yml ps
   ```

3. Reiniciar serviço específico:
   ```bash
   docker-compose -f docker-compose.scalable-simple.yml restart virtual-stock-service-1
   ```

### Se houver problemas de conectividade:
1. Verificar IP do WSL:
   ```bash
   wsl hostname -I
   ```

2. Testar conectividade local:
   ```bash
   curl http://localhost:8080/actuator/health
   ```

## 📈 Próximos Passos

1. **API Gateway**: Configurar roteamento centralizado
2. **Autenticação**: Implementar JWT/OAuth2
3. **Circuit Breaker**: Adicionar resilência
4. **Distributed Tracing**: Implementar observabilidade completa
5. **Load Testing**: Testar escalabilidade

## 🎯 Endpoints Principais Disponíveis

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/actuator/health` | Verificação de saúde |
| GET | `/api/v1/virtual-stock/stocks` | Listar estoques |
| POST | `/api/v1/virtual-stock/stocks` | Criar estoque |
| GET | `/api/v1/virtual-stock/stocks/{id}` | Buscar estoque |
| PUT | `/api/v1/virtual-stock/stocks/{id}/price` | Atualizar preço |
| PUT | `/api/v1/virtual-stock/stocks/{id}/quantity` | Atualizar quantidade |

## ✅ Confirmação de Sucesso

A aplicação está **100% operacional** e pronta para testes. Todos os componentes da arquitetura de microserviços estão funcionando conforme especificado.

**Status**: ✅ **DEPLOYADO COM SUCESSO**  
**Ambiente**: WSL2 Ubuntu + Docker Compose  
**Acesso**: Windows via IP 172.30.221.62  
**Coleção Postman**: Pronta para importação e testes  

---

*Desenvolvido seguindo princípios de Clean Architecture e Domain-Driven Design*
