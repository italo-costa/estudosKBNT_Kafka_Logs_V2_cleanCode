# 🔧 KBNT KAFKA LOGS - REQUIREMENTS E DEPENDÊNCIAS
*Sistema de Arquitetura Hexagonal com Event-Driven Microservices*

---

## 📋 **RESUMO DO SISTEMA**

### **Arquitetura**: Hexagonal (Ports & Adapters)
### **Padrão**: Event-Driven Microservices  
### **Tecnologias Core**: Spring Boot + Apache Kafka + PostgreSQL
### **Containerização**: Docker + Kubernetes (opcional)
### **Monitoramento**: ELK Stack + Micrometer

---

## 🎯 **REQUIREMENTS DE INFRAESTRUTURA**

### **1. 💻 AMBIENTE DE DESENVOLVIMENTO**

#### **Sistema Operacional**
- ✅ **Windows 10/11** (20H2 ou superior)
- ✅ **Linux** (Ubuntu 20.04+ / CentOS 8+)  
- ✅ **macOS** (Big Sur ou superior)

#### **Hardware Mínimo**
- **RAM**: 16 GB (recomendado 32 GB)
- **CPU**: 4 cores (recomendado 8 cores)
- **Disco**: 50 GB livres SSD
- **Rede**: Conexão estável para downloads

---

## 🛠️ **DEPENDÊNCIAS DE RUNTIME**

### **2. ☕ JAVA ECOSYSTEM** 
```bash
# Java Development Kit
OpenJDK 17 (LTS)
- Versão Mínima: 17.0.2
- Versão Recomendada: 17.0.8+
- Variável JAVA_HOME configurada

# Build Tool
Apache Maven
- Versão Mínima: 3.8.6
- Versão Recomendada: 3.9.4+
- Variável MAVEN_HOME configurada

# IDE (Opcional mas Recomendada)
IntelliJ IDEA / Eclipse / VS Code
- Plugins: Spring Boot, Lombok, Docker
```

### **3. 🐳 CONTAINERIZAÇÃO**
```bash
# Container Runtime
Docker Desktop / Docker Engine
- Versão Mínima: 20.10.0
- Versão Recomendada: 24.0.6+
- Docker Compose incluído
- 8 GB RAM dedicada ao Docker

# Orchestration (Opcional)
Kubernetes (kubectl)
- Versão: 1.27+
- Para deploy em cluster
```

### **4. 🗄️ BANCO DE DADOS**

#### **Desenvolvimento (Embedded)**
```yaml
# H2 Database (Embedded)
- Incluído via Maven dependency
- Configurado nos profiles: local, test
- Console Web: http://localhost:8080/h2-console
```

#### **Produção (Standalone)**
```bash
# PostgreSQL
- Versão: 15.4+
- Porta: 5432
- Databases necessários:
  - virtualstock (Virtual Stock Service)
  - kbnt_consumption_db (Consumer Service)
  - loganalytics (Log Service)

# Redis (Caching - Opcional)
- Versão: 7.0+
- Porta: 6379
```

### **5. 📡 MESSAGE BROKER**
```bash
# Apache Kafka
- Versão: 3.5.0+
- Porta: 9092
- Tópicos necessários:
  - virtual-stock-updates
  - virtual-stock-high-priority-updates  
  - kbnt-stock-events
  - application-logs

# Red Hat AMQ Streams (Kafka on OpenShift)
- Para ambiente Kubernetes
- Operator: Strimzi 0.38.0+
```

---

## 🚀 **DEPENDÊNCIAS DE BUILD**

### **6. 📦 MAVEN DEPENDENCIES** 

#### **Spring Boot Framework**
```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>2.7.18</version>
</parent>

<!-- Core Dependencies -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.kafka</groupId>
    <artifactId>spring-kafka</artifactId>
    <version>2.9.13</version>
</dependency>
```

#### **Database Drivers**
```xml
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
</dependency>
<dependency>
    <groupId>com.h2database</groupId>
    <artifactId>h2</artifactId>
    <scope>runtime</scope>
</dependency>
```

#### **Utilities & Tools**
```xml
<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <version>1.18.30</version>
</dependency>
<dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-ui</artifactId>
    <version>1.7.0</version>
</dependency>
```

#### **Testing**
```xml
<dependency>
    <groupId>org.testcontainers</groupId>
    <artifactId>junit-jupiter</artifactId>
    <version>1.19.3</version>
</dependency>
<dependency>
    <groupId>org.testcontainers</groupId>
    <artifactId>postgresql</artifactId>
    <version>1.19.3</version>
</dependency>
<dependency>
    <groupId>org.testcontainers</groupId>
    <artifactId>kafka</artifactId>
    <version>1.19.3</version>
</dependency>
```

---

## 🏗️ **MICROSERVIÇOS E PORTAS**

### **7. 🎪 APLICAÇÕES**

| Serviço | Porta | Contexto | Health Check |
|---------|-------|----------|--------------|
| **Virtual Stock Service** | 8080 | / | /actuator/health |
| **KBNT Stock Consumer** | 8081 | /api/consumer | /api/consumer/actuator/health |
| **Log Producer Service** | 8082 | / | /actuator/health |
| **KBNT Log Service** | 8083 | / | /actuator/health |

### **8. 🗄️ INFRAESTRUTURA**

| Serviço | Porta | Acesso |
|---------|-------|--------|
| **PostgreSQL** | 5432 | Database |
| **Kafka** | 9092 | Message Broker |
| **Zookeeper** | 2181 | Kafka Dependency |
| **Redis** | 6379 | Cache (opcional) |
| **H2 Console** | 8080/h2-console | Development DB |

---

## 📊 **PROFILES E CONFIGURAÇÕES**

### **9. 🔧 SPRING PROFILES**

#### **local** - Desenvolvimento Local
```yaml
spring:
  profiles:
    active: local
  datasource:
    url: jdbc:h2:mem:virtualstock
  kafka:
    bootstrap-servers: localhost:9092
```

#### **dev** - Ambiente de Desenvolvimento  
```yaml
spring:
  profiles:
    active: dev
  datasource:
    url: jdbc:postgresql://localhost:5432/virtualstock
  kafka:
    bootstrap-servers: localhost:9092
```

#### **prod** - Ambiente de Produção
```yaml
spring:
  profiles:
    active: prod
  datasource:
    url: jdbc:postgresql://postgres-service:5432/virtualstock
  kafka:
    bootstrap-servers: kafka-cluster-kafka-bootstrap:9092
```

#### **test** - Testes Automatizados
```yaml
spring:
  profiles:
    active: test
  datasource:
    url: jdbc:h2:mem:testdb
  kafka:
    bootstrap-servers: ${spring.embedded.kafka.brokers}
```

---

## 🚀 **SEQUÊNCIA DE INICIALIZAÇÃO**

### **10. 📋 ORDEM DE STARTUP**

#### **Fase 1: Infraestrutura Base**
```bash
1. PostgreSQL Database
2. Apache Kafka + Zookeeper  
3. Redis (opcional)
```

#### **Fase 2: Microserviços Core**
```bash
4. Virtual Stock Service (8080)
5. Log Producer Service (8082)
```

#### **Fase 3: Microserviços Consumidores**
```bash
6. KBNT Stock Consumer Service (8081)
7. KBNT Log Service (8083)
```

#### **Fase 4: Monitoramento (Opcional)**
```bash
8. Elasticsearch
9. Kibana
10. Prometheus + Grafana
```

---

## 🔗 **SCRIPTS DE INICIALIZAÇÃO**

### **11. 🚀 COMANDOS DE STARTUP**

#### **Ambiente Completo (Docker)**
```powershell
# Windows PowerShell
.\scripts\start-complete-environment.ps1

# Linux/macOS Bash  
./scripts/start-complete-environment.sh
```

#### **Apenas Microserviços (Local)**
```powershell
# Windows PowerShell
.\scripts\simple-startup.ps1

# Maven direto (em cada microservice)
cd microservices\virtual-stock-service
mvn spring-boot:run -Dspring.profiles.active=local
```

#### **Com Docker Compose**
```bash
cd microservices
docker-compose up -d postgres redis kafka zookeeper
docker-compose up virtual-stock-service log-producer-service
```

---

## 🧪 **TESTES E VALIDAÇÃO**

### **12. 🔍 SCRIPTS DE TESTE**

#### **Teste de Arquitetura Hexagonal**
```powershell
.\scripts\hexagonal-architecture-demo.ps1 -StockItems 10 -ReservationCount 5
```

#### **Teste de Carga (Traffic)**
```powershell
.\scripts\run-traffic-test.ps1 -TotalMessages 500 -ConcurrentThreads 10
```

#### **Demo Completo do Sistema**
```powershell
.\scripts\virtual-stock-architecture-demo.ps1
```

#### **Testes Unitários**
```bash
# Em cada microservice
mvn clean test

# Com relatórios de cobertura
mvn clean test jacoco:report
```

---

## 🌐 **ENDPOINTS E APIS**

### **13. 📡 REST ENDPOINTS**

#### **Virtual Stock Service (8080)**
```http
GET    /api/stocks              # Listar todos os stocks
GET    /api/stocks/{id}         # Buscar stock por ID
POST   /api/stocks              # Criar novo stock
PUT    /api/stocks/{id}/quantity # Atualizar quantidade
PUT    /api/stocks/{id}/price   # Atualizar preço  
POST   /api/stocks/{id}/reserve # Reservar stock
GET    /actuator/health         # Health check
```

#### **Stock Consumer Service (8081)**
```http
GET    /api/consumer/consumed-events    # Eventos consumidos
GET    /api/consumer/statistics         # Estatísticas de consumo
GET    /api/consumer/actuator/health    # Health check
```

### **14. 📋 SWAGGER/OpenAPI**
```http
# Documentação interativa da API
http://localhost:8080/swagger-ui/index.html   # Virtual Stock
http://localhost:8081/swagger-ui/index.html   # Consumer  
http://localhost:8082/swagger-ui/index.html   # Log Producer
```

---

## 📈 **MONITORAMENTO E OBSERVABILIDADE**

### **15. 📊 MÉTRICAS E HEALTH**

#### **Spring Boot Actuator**
```http
/actuator/health          # Status da aplicação
/actuator/metrics         # Métricas Micrometer
/actuator/prometheus      # Métricas para Prometheus
/actuator/info           # Informações da aplicação
/actuator/loggers        # Configuração de logs
```

#### **Business Metrics**
```yaml
# Custom metrics implementadas
- stock.operations.total
- stock.reservations.count
- kafka.messages.sent
- database.transactions.time
```

### **16. 🔍 LOGGING**
```yaml
# Configuração de logs estruturados
logging:
  level:
    com.kbnt: DEBUG
    org.springframework.kafka: INFO
  pattern:
    console: "%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n"
```

---

## 🚀 **SETUP RÁPIDO - GUIA DE INSTALAÇÃO**

### **17. ⚡ INSTALAÇÃO AUTOMÁTICA (Windows)**
```powershell
# 1. Instalar Chocolatey (Package Manager)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 2. Instalar todas as dependências
choco install openjdk17 maven docker-desktop git -y

# 3. Verificar instalações
java --version
mvn --version
docker --version

# 4. Clonar e inicializar projeto
git clone <repository-url>
cd estudosKBNT_Kafka_Logs
.\scripts\start-complete-environment.ps1
```

### **18. ⚡ INSTALAÇÃO MANUAL (Linux/macOS)**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install openjdk-17-jdk maven docker.io docker-compose -y

# CentOS/RHEL
sudo yum install java-17-openjdk maven docker docker-compose -y

# macOS
brew install openjdk@17 maven docker docker-compose

# Verificar e inicializar
java --version && mvn --version && docker --version
git clone <repository-url>
cd estudosKBNT_Kafka_Logs
chmod +x scripts/*.sh
./scripts/start-complete-environment.sh
```

---

## ✅ **CHECKLIST DE VALIDAÇÃO**

### **19. 🔍 VERIFICAÇÃO DE AMBIENTE**

#### **Pré-requisitos**
- [ ] Java 17 instalado e JAVA_HOME configurado
- [ ] Maven 3.8+ instalado e no PATH
- [ ] Docker instalado e rodando
- [ ] Portas 8080-8083, 5432, 9092 livres
- [ ] Pelo menos 8 GB RAM disponível

#### **Build e Compile**
- [ ] `mvn clean compile` executa sem erro
- [ ] Testes unitários passam: `mvn test`
- [ ] JARs são gerados: `mvn package`

#### **Execução Local**
- [ ] Virtual Stock Service inicia na porta 8080
- [ ] Health checks respondem OK
- [ ] H2 Console acessível (desenvolvimento)
- [ ] APIs REST funcionais

#### **Execução com Docker**
- [ ] PostgreSQL container sobe corretamente
- [ ] Kafka container funcional
- [ ] Microservices conectam ao PostgreSQL
- [ ] Eventos Kafka são produzidos/consumidos

#### **Testes End-to-End**
- [ ] Script de demo executa sem erro
- [ ] Operações CRUD de stock funcionam
- [ ] Eventos são publicados no Kafka
- [ ] Consumer processa eventos corretamente

---

## 🆘 **TROUBLESHOOTING COMUM**

### **20. 🔧 PROBLEMAS CONHECIDOS**

#### **Java não encontrado**
```bash
# Erro: 'java' não é reconhecido
# Solução: Configurar JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$PATH:$JAVA_HOME/bin
```

#### **Maven não encontrado**
```bash
# Erro: 'mvn' não é reconhecido
# Solução: Instalar Maven e configurar PATH
export MAVEN_HOME=/opt/maven
export PATH=$PATH:$MAVEN_HOME/bin
```

#### **Docker não conecta**
```bash
# Erro: Cannot connect to Docker daemon
# Solução: Iniciar Docker service
sudo systemctl start docker
# OU reiniciar Docker Desktop (Windows/Mac)
```

#### **Porta em uso**
```bash
# Erro: Port 8080 already in use
# Solução: Verificar processos na porta
netstat -tulpn | grep 8080
# Ou alterar porta no application.yml
server.port=8081
```

#### **PostgreSQL connection failed**
```bash
# Erro: Connection to localhost:5432 refused
# Solução: Verificar se PostgreSQL está rodando
docker ps | grep postgres
# Ou usar profile local (H2)
mvn spring-boot:run -Dspring.profiles.active=local
```

---

## 📚 **RECURSOS E DOCUMENTAÇÃO**

### **21. 📖 LINKS ÚTEIS**

- **Spring Boot**: https://spring.io/projects/spring-boot
- **Apache Kafka**: https://kafka.apache.org/
- **Docker**: https://docs.docker.com/
- **PostgreSQL**: https://www.postgresql.org/docs/
- **Testcontainers**: https://www.testcontainers.org/

### **22. 📁 ESTRUTURA DO PROJETO**
```
estudosKBNT_Kafka_Logs/
├── microservices/
│   ├── virtual-stock-service/        # Microserviço principal
│   ├── kbnt-stock-consumer-service/ # Consumer de eventos  
│   ├── log-producer-service/        # Producer de logs
│   └── kbnt-log-service/           # Analytics de logs
├── scripts/                        # Scripts de automação
├── docs/                          # Documentação
├── docker-compose.yml             # Orquestração local
└── README.md                      # Guia principal
```

---

*Requirements document gerado em: 2025-01-26*  
*Versão: 2.0.0*  
*Sistema: KBNT Kafka Logs - Hexagonal Architecture*
