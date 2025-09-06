# 🔌 CONFIGURAÇÃO PADRÃO DE PORTAS - MICROSERVIÇOS KAFKA

## 📋 Mapeamento de Portas Padronizado

### 🏗️ **Infraestrutura**
| Serviço | Porta Externa | Porta Interna | Descrição |
|---------|---------------|---------------|-----------|
| PostgreSQL | 5432 | 5432 | Database principal |
| Redis | 6379 | 6379 | Cache e sessões |
| Zookeeper | 2181 | 2181 | Coordenação Kafka |
| Kafka | 9092, 29092 | 9092, 29092 | Message Broker |

### 🚀 **Microserviços**
| Serviço | Porta App | Porta Mgmt | URL Interna | Descrição |
|---------|-----------|------------|-------------|-----------|
| API Gateway | 8080 | 9080 | http://api-gateway:8080 | Gateway principal |
| Log Producer | 8081 | 9081 | http://log-producer-service:8080 | Produção de logs |
| Log Consumer | 8082 | 9082 | http://log-consumer-service:8080 | Consumo de logs |
| Log Analytics | 8083 | 9083 | http://log-analytics-service:8080 | Análise de logs |
| Virtual Stock | 8084 | 9084 | http://virtual-stock-service:8080 | Estoque virtual |
| KBNT Consumer | 8085 | 9085 | http://kbnt-stock-consumer-service:8080 | Consumidor KBNT |

## 🔧 **Convenções de Configuração**

### **Padrão de Portas Externas**
- **80XX**: Aplicação principal (8080, 8081, 8082, etc.)
- **90XX**: Management/Actuator (9080, 9081, 9082, etc.)

### **Padrão de Portas Internas (Container)**
- **8080**: Aplicação Spring Boot (padrão)
- **9090**: Management/Actuator (padrão)

### **Variáveis de Ambiente Padrão**
```yaml
environment:
  - SERVER_PORT=8080
  - MANAGEMENT_SERVER_PORT=9090
```

## 🎯 **URLs de Acesso**

### **Aplicações**
- API Gateway: http://localhost:8080
- Log Producer: http://localhost:8081
- Log Consumer: http://localhost:8082
- Log Analytics: http://localhost:8083
- Virtual Stock: http://localhost:8084
- KBNT Consumer: http://localhost:8085

### **Health Checks**
- API Gateway: http://localhost:8080/actuator/health
- Log Producer: http://localhost:8081/actuator/health
- Log Consumer: http://localhost:8082/actuator/health
- Log Analytics: http://localhost:8083/actuator/health
- Virtual Stock: http://localhost:8084/actuator/health
- KBNT Consumer: http://localhost:8085/actuator/health

### **Management Endpoints**
- API Gateway: http://localhost:9080/actuator
- Log Producer: http://localhost:9081/actuator
- Log Consumer: http://localhost:9082/actuator
- Log Analytics: http://localhost:9083/actuator
- Virtual Stock: http://localhost:9084/actuator
- KBNT Consumer: http://localhost:9085/actuator

## ⚡ **Benefícios da Padronização**

### ✅ **Vantagens**
1. **Previsibilidade**: Cada serviço tem porta conhecida
2. **Sem Conflitos**: Mapeamento único por serviço
3. **Debugging Fácil**: URLs consistentes para testes
4. **Documentação Clara**: Fácil referência para desenvolvedores
5. **Automação**: Scripts podem referenciar portas fixas

### 🛡️ **Proteções Implementadas**
1. **Portas Fixas**: Nenhuma porta aleatória
2. **Separação de Contexto**: App vs Management
3. **Mapeamento Consistente**: Externa:Interna padronizado
4. **Health Checks**: Verificação automática de saúde
5. **Restart Policy**: Reinicialização automática

## 🔍 **Verificação de Conflitos**

### **Comando para Verificar Portas em Uso**
```bash
# Windows
netstat -an | findstr ":8080"
netstat -an | findstr ":8081"

# Linux/WSL
netstat -tulpn | grep ":8080"
lsof -i :8080
```

### **Docker Compose Ports Check**
```bash
docker-compose ps
docker port <container_name>
```

## 🚨 **Resolução de Problemas**

### **Se uma porta estiver em uso:**
1. Verificar processos: `netstat -ano | findstr :8080`
2. Parar processo conflitante
3. Ou alterar porta no docker-compose.yml

### **Para resetar completamente:**
```bash
docker-compose down -v
docker system prune -f
docker-compose up -d
```

---
*Configuração aplicada em: 06/09/2025*  
*Ambiente: Docker WSL Ubuntu + Windows*  
*Arquitetura: Clean Architecture + Microservices*
