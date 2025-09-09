# 🚀 KBNT Virtual Stock Service - Comandos Curl para Postman
# Aplicação está rodando com sucesso em ambiente Linux virtualizado Docker!

## ⚠️ IMPORTANTE - WSL2 Networking
**Se você está testando do Windows Postman e recebendo erro ECONNREFUSED:**
- 🔧 **Solução**: Execute `.\configure-wsl2-port-forwarding.ps1` como Administrador
- 📖 **Guia completo**: Veja `WSL2_NETWORKING_SOLUTION.md`
- 🎯 **Alternativa**: Use IP direto `http://172.30.221.62:8084` no Postman

## 📋 Informações da Aplicação
- **URL Base**: http://localhost:8084 (após port forwarding)
- **URL Alternativa**: http://172.30.221.62:8084 (IP direto WSL2)
- **API Version**: v1
- **Database**: PostgreSQL (conectado e funcionando)
- **Status**: ✅ ONLINE

## 🔧 Endpoints da API Virtual Stock Service

### 1. ✅ Listar todos os stocks (GET)
```bash
curl -X GET http://localhost:8084/api/v1/virtual-stock/stocks \
  -H "Content-Type: application/json"
```

### 2. ✅ Criar um novo stock (POST)
```bash
curl -X POST http://localhost:8084/api/v1/virtual-stock/stocks \
  -H "Content-Type: application/json" \
  -d '{
    "stockCode": "PROD001",
    "productName": "Smartphone Samsung Galaxy",
    "quantity": 100,
    "unitPrice": 1299.99
  }'
```

### 3. ✅ Buscar stock por ID (GET)
```bash
curl -X GET http://localhost:8084/api/v1/virtual-stock/stocks/1 \
  -H "Content-Type: application/json"
```

### 4. ✅ Atualizar quantidade do stock (PUT)
```bash
curl -X PUT http://localhost:8084/api/v1/virtual-stock/stocks/1/quantity \
  -H "Content-Type: application/json" \
  -d '{
    "quantity": 150
  }'
```

### 5. ✅ Health Check do Serviço
```bash
curl -X GET http://localhost:8084/actuator/health \
  -H "Content-Type: application/json"
```

## 📊 Outros Serviços Disponíveis

### 🎛️ Kafka UI (Interface Kafka)
```bash
curl -X GET http://localhost:8090
```

### 📈 Log Consumer Service
```bash
curl -X GET http://localhost:8082/actuator/health
```

### 📊 Log Analytics Service  
```bash
curl -X GET http://localhost:8083/actuator/health
```

## 🔄 Exemplos de Teste Completo

### Teste 1: Criar e listar stock
```bash
# 1. Criar stock
curl -X POST http://localhost:8084/api/v1/virtual-stock/stocks \
  -H "Content-Type: application/json" \
  -d '{
    "stockCode": "LAPTOP001",
    "productName": "Notebook Dell Inspiron",
    "quantity": 25,
    "unitPrice": 2499.90
  }'

# 2. Listar todos
curl -X GET http://localhost:8084/api/v1/virtual-stock/stocks
```

### Teste 2: Atualizar quantidade
```bash
# 1. Atualizar quantidade do stock ID 1
curl -X PUT http://localhost:8084/api/v1/virtual-stock/stocks/1/quantity \
  -H "Content-Type: application/json" \
  -d '{"quantity": 75}'

# 2. Verificar alteração
curl -X GET http://localhost:8084/api/v1/virtual-stock/stocks/1
```

## 🎯 Para uso no Postman:

### Configuração Base:
- **Base URL**: `http://localhost:8084`
- **Headers**: `Content-Type: application/json`

### Variáveis do Postman:
```
{{baseUrl}} = http://localhost:8084
{{apiVersion}} = v1
```

### Endpoints organizados:
1. **GET** `{{baseUrl}}/api/{{apiVersion}}/virtual-stock/stocks`
2. **POST** `{{baseUrl}}/api/{{apiVersion}}/virtual-stock/stocks`
3. **GET** `{{baseUrl}}/api/{{apiVersion}}/virtual-stock/stocks/{{stockId}}`
4. **PUT** `{{baseUrl}}/api/{{apiVersion}}/virtual-stock/stocks/{{stockId}}/quantity`

## ✅ Status dos Containers:
- ✅ PostgreSQL: Funcionando (localhost:5432)
- ✅ Kafka: Funcionando (localhost:9092)
- ✅ Zookeeper: Funcionando (localhost:2181)
- ✅ Virtual Stock Service: Funcionando (localhost:8084)
- ✅ Kafka UI: Funcionando (localhost:8090)

## 🔧 Comandos Docker Úteis:
```bash
# Ver status dos containers
wsl docker ps

# Ver logs do Virtual Stock Service
wsl docker logs virtual-stock-service --tail 20

# Parar aplicação
wsl docker compose -f docker-compose.complete.yml down

# Iniciar aplicação
wsl docker compose -f docker-compose.complete.yml up -d
```
