# 🚀 Guia Completo - Virtual Stock Service API via API Gateway

## 📋 Resumo da Arquitetura

Nossa aplicação está configurada com a seguinte arquitetura:

```
Windows Host (Postman) 
    ↓ HTTP Requests
API Gateway (172.30.221.62:8080)
    ↓ Internal Routing
Virtual Stock Service (Container Port 8080)
    ↓ Database Queries  
PostgreSQL Database (Container Port 5432)
```

### 🔧 Configuração de Rede
- **IP WSL2**: `172.30.221.62`
- **API Gateway**: Porta `8080` (externa)
- **Virtual Stock Service**: Porta `8080` (interna via Docker Network)
- **Roteamento**: `/api/v1/virtual-stock/**` → `http://virtual-stock-service-1:8080`

---

## �️ **COMANDOS PARA LEVANTAR O AMBIENTE**

### 1. Preparar Ambiente
```bash
# Limpar containers existentes
wsl -d Ubuntu bash -c "docker container prune -f"

# Verificar IP do WSL
wsl hostname -I
```

### 2. Iniciar Infraestrutura Base
```bash
# PostgreSQL Database
wsl -d Ubuntu bash -c "docker run -d --name postgres-db -p 5432:5432 -e POSTGRES_DB=kbnt_db -e POSTGRES_USER=kbnt_user -e POSTGRES_PASSWORD=kbnt_password postgres:15"

# Aguardar 15 segundos
Start-Sleep -Seconds 15
```

### 3. Iniciar Virtual Stock Service  
```bash
# Virtual Stock Service na porta 8084
wsl -d Ubuntu bash -c "docker run -d --name virtual-stock-svc -p 8084:8080 -e SERVER_PORT=8080 -e SPRING_DATASOURCE_URL=jdbc:postgresql://host.docker.internal:5432/kbnt_db -e SPRING_DATASOURCE_USERNAME=kbnt_user -e SPRING_DATASOURCE_PASSWORD=kbnt_password -e SPRING_PROFILES_ACTIVE=docker estudoskbnt_kafka_logs_v2_cleancode_virtual-stock-service-1"

# Aguardar 30 segundos
Start-Sleep -Seconds 30
```

### 4. Verificar Serviços
```bash
# Verificar se está rodando
wsl -d Ubuntu bash -c "docker ps"

# Testar Virtual Stock Service
Invoke-WebRequest -Uri "http://172.30.221.62:8084/actuator/health" -UseBasicParsing
```

### 5. Iniciar API Gateway (Opcional)
```bash
# API Gateway na porta 8080
wsl -d Ubuntu bash -c "docker run -d --name api-gateway-svc -p 8080:8080 -e SERVER_PORT=8080 -e SPRING_PROFILES_ACTIVE=simple estudoskbnt_kafka_logs_v2_cleancode_api-gateway-1"
```

---

## �📦 Como Importar a Coleção no Postman

### Passo 1: Baixar a Coleção
1. A coleção está salva em: `Virtual_Stock_API_Postman_Collection.json`
2. Localize o arquivo no diretório: `c:\workspace\estudosKBNT_Kafka_Logs_V2_cleanCode\`

### Passo 2: Importar no Postman
1. **Abra o Postman** no Windows
2. Clique em **"Import"** (botão superior esquerdo)
3. Selecione **"File"** 
4. Navegue até `c:\workspace\estudosKBNT_Kafka_Logs_V2_cleanCode\Virtual_Stock_API_Postman_Collection.json`
5. Clique **"Import"**

### Passo 3: Verificar Variáveis de Ambiente
A coleção inclui as seguintes variáveis (atualizadas):
- `base_url`: `http://172.30.221.62:8084` (Virtual Stock Service diretamente)
- `api_path`: `/api/v1/virtual-stock`

---

## 🧪 Endpoints Disponíveis

### 1. Health Check
| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/actuator/health` | GET | Status do Virtual Stock Service |

### 2. Gerenciamento de Stocks
| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/api/v1/virtual-stock/stocks` | POST | Criar novo stock |
| `/api/v1/virtual-stock/stocks` | GET | Listar todos os stocks |
| `/api/v1/virtual-stock/stocks/{id}` | GET | Buscar stock por ID |
| `/api/v1/virtual-stock/stocks/{id}/price` | PUT | Atualizar preço |
| `/api/v1/virtual-stock/stocks/{id}/quantity` | PUT | Atualizar quantidade |

**🔥 URLs COMPLETAS PARA TESTE:**
- Health: `http://172.30.221.62:8084/actuator/health`
- Create Stock: `http://172.30.221.62:8084/api/v1/virtual-stock/stocks`
- List Stocks: `http://172.30.221.62:8084/api/v1/virtual-stock/stocks`

---

## 📝 Exemplos de Requisições

### Criar Stock
```json
POST http://172.30.221.62:8084/api/v1/virtual-stock/stocks
Content-Type: application/json

{
  "productId": "PROD-001",
  "symbol": "AAPL", 
  "productName": "Apple Inc. Stock",
  "quantity": 100,
  "unitPrice": 150.25,
  "createdBy": "admin"
}
```

### Atualizar Preço
```json
PUT http://172.30.221.62:8084/api/v1/virtual-stock/stocks/PROD-001/price
Content-Type: application/json

{
  "newPrice": 155.75,
  "updatedBy": "admin"
}
```

### Atualizar Quantidade
```json
PUT http://172.30.221.62:8084/api/v1/virtual-stock/stocks/PROD-001/quantity
Content-Type: application/json

{
  "newQuantity": 75,
  "updatedBy": "admin"
}
```

---

## 🔍 Estrutura da Resposta

Todas as respostas seguem o padrão `ApiResponse`:

### Sucesso (200/201)
```json
{
  "success": true,
  "data": {
    "stockId": "550e8400-e29b-41d4-a716-446655440000",
    "productId": "PROD-001",
    "symbol": "AAPL",
    "productName": "Apple Inc. Stock",
    "quantity": 100,
    "unitPrice": 150.25,
    "status": "ACTIVE",
    "createdBy": "admin",
    "createdAt": "2025-09-10T18:30:00Z",
    "updatedAt": "2025-09-10T18:30:00Z"
  },
  "message": "Stock created successfully",
  "timestamp": "2025-09-10T18:30:00Z"
}
```

### Erro (400/404/500)
```json
{
  "success": false,
  "data": null,
  "message": "Stock not found",
  "timestamp": "2025-09-10T18:30:00Z"
}
```

---

## 🚨 Troubleshooting

### Problema: "Impossível conectar-se ao servidor remoto"
**Solução:**
1. Verificar se WSL2 está rodando: `wsl -l -v`
2. Confirmar IP do WSL2: `wsl hostname -I`
3. Verificar se serviços estão rodando: 
   ```bash
   wsl -d Ubuntu bash -c "docker ps"
   ```

### Problema: Container para de funcionar
**Solução:**
1. Verificar logs do container:
   ```bash
   wsl -d Ubuntu bash -c "docker logs virtual-stock-svc --tail 20"
   ```
2. Restart o container:
   ```bash
   wsl -d Ubuntu bash -c "docker restart virtual-stock-svc"
   ```

### Problema: "Connection refused" no banco
**Solução:**
1. Verificar se PostgreSQL está rodando:
   ```bash
   wsl -d Ubuntu bash -c "docker ps | grep postgres"
   ```
2. Restart PostgreSQL:
   ```bash
   wsl -d Ubuntu bash -c "docker restart postgres-db"
   ```

---

## 🔧 Comandos Úteis

### Verificar Status dos Serviços
```bash
# Verificar containers rodando
wsl -d Ubuntu bash -c "docker ps"

# Verificar logs do Virtual Stock Service  
wsl -d Ubuntu bash -c "docker logs virtual-stock-svc --tail 20"

# Verificar logs do PostgreSQL
wsl -d Ubuntu bash -c "docker logs postgres-db --tail 20"

# Testar conectividade
Invoke-WebRequest -Uri "http://172.30.221.62:8084/actuator/health" -UseBasicParsing
```

### Reiniciar Serviços
```bash
# Reiniciar Virtual Stock Service
wsl -d Ubuntu bash -c "docker restart virtual-stock-svc"

# Reiniciar PostgreSQL
wsl -d Ubuntu bash -c "docker restart postgres-db"

# Parar todos os containers
wsl -d Ubuntu bash -c "docker stop \$(docker ps -q)"
```

---

## 📊 Monitoramento

### Endpoints de Monitoramento
- **Virtual Stock Health**: `http://172.30.221.62:8084/actuator/health`
- **Virtual Stock Info**: `http://172.30.221.62:8084/actuator/info`

### Métricas Disponíveis
- Status dos serviços (UP/DOWN)
- Informações de conectividade com banco de dados
- Memória e CPU utilização

---

## 🎉 Resultado Esperado

Após seguir os comandos e importar a coleção, você deve conseguir:

1. ✅ **Conectar** ao Virtual Stock Service via WSL2
2. ✅ **Criar** novos stocks via POST
3. ✅ **Listar** stocks existentes via GET  
4. ✅ **Atualizar** preços e quantidades via PUT
5. ✅ **Testar** cenários de erro e validação
6. ✅ **Monitorar** a saúde dos serviços

---

## ⚡ **QUICK START**

```bash
# 1. Limpar ambiente
wsl -d Ubuntu bash -c "docker container prune -f"

# 2. PostgreSQL
wsl -d Ubuntu bash -c "docker run -d --name postgres-db -p 5432:5432 -e POSTGRES_DB=kbnt_db -e POSTGRES_USER=kbnt_user -e POSTGRES_PASSWORD=kbnt_password postgres:15"

# 3. Aguardar
Start-Sleep -Seconds 15

# 4. Virtual Stock Service
wsl -d Ubuntu bash -c "docker run -d --name virtual-stock-svc -p 8084:8080 -e SERVER_PORT=8080 -e SPRING_DATASOURCE_URL=jdbc:postgresql://host.docker.internal:5432/kbnt_db -e SPRING_DATASOURCE_USERNAME=kbnt_user -e SPRING_DATASOURCE_PASSWORD=kbnt_password -e SPRING_PROFILES_ACTIVE=docker estudoskbnt_kafka_logs_v2_cleancode_virtual-stock-service-1"

# 5. Aguardar
Start-Sleep -Seconds 30

# 6. Testar
Invoke-WebRequest -Uri "http://172.30.221.62:8084/actuator/health" -UseBasicParsing
```

**🔗 Próximos Passos:**
1. Execute o QUICK START acima
2. Importe a coleção `Virtual_Stock_API_Postman_Collection.json` no Postman
3. Teste o endpoint "Virtual Stock Service Health" primeiro
4. Execute os cenários de criação e gestão de stocks

**📞 Suporte:** Em caso de problemas, verifique os logs dos containers e utilize os comandos de troubleshooting fornecidos.

---

## 🧪 Endpoints Disponíveis

### 1. Health Check
| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/actuator/health` | GET | Status do API Gateway |
| `/api/v1/virtual-stock/actuator/health` | GET | Status do Virtual Stock Service |

### 2. Gerenciamento de Stocks
| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/api/v1/virtual-stock/stocks` | POST | Criar novo stock |
| `/api/v1/virtual-stock/stocks` | GET | Listar todos os stocks |
| `/api/v1/virtual-stock/stocks/{id}` | GET | Buscar stock por ID |
| `/api/v1/virtual-stock/stocks/{id}/price` | PUT | Atualizar preço |
| `/api/v1/virtual-stock/stocks/{id}/quantity` | PUT | Atualizar quantidade |

---

## 📝 Exemplos de Requisições

### Criar Stock
```json
POST /api/v1/virtual-stock/stocks
Content-Type: application/json

{
  "productId": "PROD-001",
  "symbol": "AAPL", 
  "productName": "Apple Inc. Stock",
  "quantity": 100,
  "unitPrice": 150.25,
  "createdBy": "admin"
}
```

### Atualizar Preço
```json
PUT /api/v1/virtual-stock/stocks/PROD-001/price
Content-Type: application/json

{
  "newPrice": 155.75,
  "updatedBy": "admin"
}
```

### Atualizar Quantidade
```json
PUT /api/v1/virtual-stock/stocks/PROD-001/quantity
Content-Type: application/json

{
  "newQuantity": 75,
  "updatedBy": "admin"
}
```

---

## 🔍 Estrutura da Resposta

Todas as respostas seguem o padrão `ApiResponse`:

### Sucesso (200/201)
```json
{
  "success": true,
  "data": {
    "stockId": "550e8400-e29b-41d4-a716-446655440000",
    "productId": "PROD-001",
    "symbol": "AAPL",
    "productName": "Apple Inc. Stock",
    "quantity": 100,
    "unitPrice": 150.25,
    "status": "ACTIVE",
    "createdBy": "admin",
    "createdAt": "2025-09-10T18:30:00Z",
    "updatedAt": "2025-09-10T18:30:00Z"
  },
  "message": "Stock created successfully",
  "timestamp": "2025-09-10T18:30:00Z"
}
```

### Erro (400/404/500)
```json
{
  "success": false,
  "data": null,
  "message": "Stock not found",
  "timestamp": "2025-09-10T18:30:00Z"
}
```

---

## 🎯 Cenários de Teste Incluídos

### 1. **Health Check**
- Verificar se API Gateway está respondendo
- Verificar se Virtual Stock Service está acessível

### 2. **CRUD Básico**
- Criar stock com dados válidos
- Listar todos os stocks
- Buscar stock específico
- Atualizar preço
- Atualizar quantidade

### 3. **Cenários de Negócio**
- Criar stock de tecnologia (Google)
- Criar stock financeiro (JPMorgan)
- Simular atualizações de mercado

### 4. **Testes de Erro**
- Buscar stock inexistente
- Criar stock com dados inválidos
- Atualizar com valores negativos

---

## 🚨 Troubleshooting

### Problema: "Impossível conectar-se ao servidor remoto"
**Solução:**
1. Verificar se WSL2 está rodando: `wsl -l -v`
2. Confirmar IP do WSL2: `wsl hostname -I`
3. Verificar se API Gateway está rodando: 
   ```bash
   wsl -d Ubuntu bash -c "docker ps | grep api-gateway"
   ```

### Problema: "404 Not Found" 
**Solução:**
1. Verificar se a rota está correta: `/api/v1/virtual-stock/**`
2. Confirmar se Virtual Stock Service está no mesmo network do API Gateway

### Problema: "500 Internal Server Error"
**Solução:**
1. Verificar logs do Virtual Stock Service:
   ```bash
   wsl -d Ubuntu bash -c "docker logs virtual-stock-service-1 --tail 20"
   ```
2. Confirmar se PostgreSQL está rodando e acessível

---

## 🔧 Comandos Úteis

### Verificar Status dos Serviços
```bash
# Verificar containers rodando
wsl -d Ubuntu bash -c "docker ps"

# Verificar logs do API Gateway
wsl -d Ubuntu bash -c "docker logs api-gateway-manual --tail 20"

# Verificar logs do Virtual Stock Service  
wsl -d Ubuntu bash -c "docker logs virtual-stock-service-1 --tail 20"

# Verificar conectividade interna
wsl -d Ubuntu bash -c "docker exec api-gateway-manual curl -s http://virtual-stock-service-1:8080/actuator/health"
```

### Reiniciar Serviços
```bash
# Reiniciar API Gateway
wsl -d Ubuntu bash -c "docker restart api-gateway-manual"

# Reiniciar Virtual Stock Service
wsl -d Ubuntu bash -c "docker restart virtual-stock-service-1"
```

---

## 📊 Monitoramento

### Endpoints de Monitoramento
- **API Gateway Health**: `http://172.30.221.62:8080/actuator/health`
- **Gateway Routes**: `http://172.30.221.62:8080/actuator/gateway/routes`
- **Virtual Stock Health**: `http://172.30.221.62:8080/api/v1/virtual-stock/actuator/health`

### Métricas Disponíveis
- Status dos serviços (UP/DOWN)
- Informações de conectividade com banco de dados
- Detalhes das rotas configuradas no Gateway

---

## 🎉 Resultado Esperado

Após importar a coleção e executar os testes, você deve conseguir:

1. ✅ **Conectar** ao API Gateway via WSL2
2. ✅ **Rotear** requisições para o Virtual Stock Service
3. ✅ **Criar** novos stocks via POST
4. ✅ **Listar** stocks existentes via GET  
5. ✅ **Atualizar** preços e quantidades via PUT
6. ✅ **Testar** cenários de erro e validação
7. ✅ **Monitorar** a saúde dos serviços

Esta configuração demonstra uma **arquitetura completa de microserviços** com:
- API Gateway para roteamento
- Arquitetura Hexagonal/Clean Architecture  
- Integração com PostgreSQL
- Docker containerization
- Ambiente WSL2 Linux virtualizado
- Testes via Postman no Windows

---

**🔗 Próximos Passos:**
1. Importe a coleção no Postman
2. Execute o teste "API Gateway Health" primeiro
3. Siga a sequência: Health → Create Stock → Get All Stocks → Update Operations
4. Explore os cenários de teste avançados conforme necessário

**📞 Suporte:** Qualquer erro ou dúvida, verifique os logs dos containers e utilize os comandos de troubleshooting fornecidos acima.
