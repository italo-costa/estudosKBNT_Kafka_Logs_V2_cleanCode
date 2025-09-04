# Microserviços Spring Boot + AMQ Streams

Esta seção contém microserviços Spring Boot integrados com Red Hat AMQ Streams para processamento de logs distribuídos.

## 🏗️ Arquitetura dos Microserviços

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   API Gateway   │────│  AMQ Streams     │────│  Log Analytics  │
│   (Spring Boot) │    │  (Kafka)         │    │  (Spring Boot)  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                        │                        │
         │                        │                        │
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ Log Producer    │────│     Topics:      │────│  Log Consumer   │
│ (Spring Boot)   │    │ - application-logs│    │ (Spring Boot)   │
│                 │    │ - error-logs     │    │                 │
└─────────────────┘    │ - audit-logs     │    └─────────────────┘
                       │ - metrics        │
                       └──────────────────┘
```

## 📦 Microserviços

### 1. **API Gateway** (`api-gateway/`)
- Spring Boot + Spring Cloud Gateway
- Roteamento de requisições
- Rate limiting e circuit breaker
- Logs de requisições para Kafka

### 2. **Log Producer Service** (`log-producer-service/`)
- Spring Boot + Spring Kafka
- REST API para receber logs
- Producer para AMQ Streams
- Validação e transformação de dados

### 3. **Log Consumer Service** (`log-consumer-service/`)
- Spring Boot + Spring Kafka
- Consumer de logs do AMQ Streams
- Processamento em tempo real
- Integração com banco de dados

### 4. **Log Analytics Service** (`log-analytics-service/`)
- Spring Boot + Spring Data
- Análise de logs consumidos
- APIs para consultas e dashboards
- Métricas e estatísticas

## 🚀 Tecnologias Utilizadas

- **Spring Boot 3.2** - Framework principal
- **Spring Kafka** - Integração com AMQ Streams
- **Spring Cloud Gateway** - API Gateway
- **Spring Data JPA** - Persistência
- **Spring Boot Actuator** - Monitoramento
- **Micrometer** - Métricas
- **Docker** - Containerização
- **PostgreSQL** - Banco de dados
- **Redis** - Cache distribuído

## 🔧 Configuração do VS Code

### Extensões Recomendadas:

```json
{
  "recommendations": [
    "vscjava.vscode-java-pack",
    "vmware.vscode-spring-boot",
    "vscjava.vscode-spring-initializr",
    "vscjava.vscode-spring-boot-dashboard",
    "ms-vscode.vscode-json",
    "redhat.vscode-yaml",
    "ms-kubernetes-tools.vscode-kubernetes-tools",
    "ms-vscode-remote.remote-containers",
    "gabrielbb.vscode-lombok"
  ]
}
```

### Workspace Settings:

```json
{
  "java.configuration.updateBuildConfiguration": "automatic",
  "java.compile.nullAnalysis.mode": "automatic",
  "spring-boot.ls.problem.application-properties.unknown-property": "warning",
  "files.exclude": {
    "**/.classpath": true,
    "**/.project": true,
    "**/.settings": true,
    "**/.factorypath": true
  }
}
```

## 🛠️ Setup do Ambiente

### 1. Pré-requisitos

```bash
# Java 17+
java --version

# Maven 3.8+
mvn --version

# Docker
docker --version

# AMQ Streams rodando
kubectl get kafka -n kafka
```

### 2. Build dos Microserviços

```bash
# Build de todos os serviços
cd microservices
./build-all.sh

# Ou individualmente
cd log-producer-service
mvn clean package -DskipTests
```

### 3. Executar com Docker Compose

```bash
cd microservices
docker-compose up -d
```

### 4. Executar no Kubernetes

```bash
# Deploy de todos os microserviços
kubectl apply -f kubernetes/microservices/
```

## 🧪 Testes e Desenvolvimento

### Executar Localmente no VS Code:

1. **Abrir workspace** no VS Code
2. **Spring Boot Dashboard** aparecerá automaticamente
3. **Run/Debug** cada microserviço individualmente
4. **Hot reload** automático durante desenvolvimento

### Perfis de Ambiente:

- `local` - Para desenvolvimento local
- `docker` - Para containers Docker  
- `kubernetes` - Para deploy em K8s
- `test` - Para testes automatizados

### Comandos Úteis:

```bash
# Executar com perfil específico
mvn spring-boot:run -Dspring-boot.run.profiles=local

# Executar testes
mvn test

# Build de imagem Docker
mvn spring-boot:build-image
```

## 📊 Monitoramento

### Actuator Endpoints:

- `/actuator/health` - Health checks
- `/actuator/metrics` - Métricas Micrometer
- `/actuator/prometheus` - Métricas para Prometheus
- `/actuator/info` - Informações da aplicação
- `/actuator/kafka` - Métricas do Kafka

### Distributed Tracing:

- **Spring Cloud Sleuth** para rastreamento
- **Zipkin** para visualização de traces
- **Correlation IDs** em todos os logs

## 🔐 Segurança

- **OAuth2/JWT** para autenticação
- **Spring Security** para autorização
- **ACLs** do Kafka para segurança de tópicos
- **TLS** para comunicação segura

## 📋 APIs Disponíveis

### Log Producer Service:
```
POST /api/v1/logs - Enviar logs
GET  /api/v1/logs/health - Health check
```

### Log Analytics Service:
```
GET /api/v1/analytics/summary - Resumo de logs
GET /api/v1/analytics/errors - Análise de erros
GET /api/v1/analytics/trends - Tendências
```

### API Gateway:
```
GET /health - Health check global
GET /routes - Rotas disponíveis
```

## 🐛 Troubleshooting

### Problemas Comuns:

1. **Kafka não conecta**:
   ```bash
   # Verificar conectividade
   kubectl port-forward -n kafka svc/kafka-cluster-kafka-bootstrap 9092:9092
   ```

2. **Microserviço não inicia**:
   ```bash
   # Verificar logs
   docker logs log-producer-service
   kubectl logs -f deployment/log-producer-service
   ```

3. **VS Code não reconhece Spring**:
   - Instalar Java Extension Pack
   - Reload Window (Ctrl+Shift+P)
   - Verificar JAVA_HOME

## 🎯 Próximos Passos

1. [Setup dos Microserviços](setup-microservices.md)
2. [Desenvolvimento com VS Code](vscode-development.md)
3. [Deploy no Kubernetes](kubernetes-microservices.md)
4. [Monitoramento e Observabilidade](monitoring-microservices.md)
5. [Testes e CI/CD](testing-cicd.md)

## 📚 Referências

- [Spring Boot Documentation](https://docs.spring.io/spring-boot/docs/current/reference/html/)
- [Spring Kafka](https://docs.spring.io/spring-kafka/docs/current/reference/html/)
- [Spring Cloud Gateway](https://docs.spring.io/spring-cloud-gateway/docs/current/reference/html/)
- [VS Code Java](https://code.visualstudio.com/docs/languages/java)
