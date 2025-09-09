# 📊 Diagrama de Arquitetura KBNT Kafka Logs - Clean Architecture v2.1

## 🏗️ Visão Geral da Arquitetura

```mermaid
graph TB
    %% Definição de estilos
    classDef presentationLayer fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef applicationLayer fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px
    classDef domainLayer fill:#fff3e0,stroke:#ef6c00,stroke-width:2px
    classDef infrastructureLayer fill:#fce4ec,stroke:#c2185b,stroke-width:2px
    classDef externalSystems fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef technology fill:#e0f2f1,stroke:#00695c,stroke-width:2px

    %% Camada de Apresentação (Presentation Layer)
    subgraph PL ["🖥️ Presentation Layer - Port 8084"]
        REST_API["🌐 REST API Controller<br/>Virtual Stock Service<br/>@RestController<br/>Port: 8084"]
        POSTMAN["📱 Postman Client<br/>http://172.30.221.62:8084"]
        SWAGGER["📚 Swagger UI<br/>/swagger-ui.html"]
    end

    %% Camada de Aplicação (Application Layer)
    subgraph AL ["⚙️ Application Layer"]
        STOCK_SERVICE["📦 StockApplicationService<br/>Use Cases & Business Logic"]
        DTO_MAPPER["🔄 DTO Mappers<br/>Request/Response Transformation"]
        VALIDATION["✅ Input Validation<br/>Bean Validation"]
    end

    %% Camada de Domínio (Domain Layer)
    subgraph DL ["🏛️ Domain Layer - Core Business"]
        STOCK_ENTITY["📋 Stock Entity<br/>Domain Model"]
        STOCK_REPOSITORY["🗃️ StockRepository<br/>Domain Interface"]
        BUSINESS_RULES["⚖️ Business Rules<br/>Domain Services"]
        VALUE_OBJECTS["💎 Value Objects<br/>StockCode, Quantity"]
    end

    %% Camada de Infraestrutura (Infrastructure Layer)
    subgraph IL ["🔧 Infrastructure Layer"]
        JPA_REPOSITORY["🗄️ JPA Repository<br/>StockRepositoryImpl"]
        DATABASE_CONFIG["⚙️ Database Configuration<br/>DataSource, JPA Config"]
        KAFKA_PRODUCER["📤 Kafka Producer<br/>Message Publishing"]
        KAFKA_CONSUMER["📥 Kafka Consumer<br/>Message Consuming"]
    end

    %% Sistemas Externos (External Systems)
    subgraph ES ["🌐 External Systems"]
        POSTGRESQL["🐘 PostgreSQL 15<br/>Database<br/>Port: 5432<br/>Database: virtualstock"]
        KAFKA_CLUSTER["🔄 Apache Kafka<br/>Message Broker<br/>Port: 9092<br/>Zookeeper: 2181"]
        KAFKA_UI["🎛️ Kafka UI<br/>Management Interface<br/>Port: 8090"]
    end

    %% Tecnologias e Ferramentas
    subgraph TECH ["🛠️ Technologies & Tools"]
        DOCKER["🐳 Docker<br/>Containerization<br/>WSL2 Environment"]
        SPRING_BOOT["🍃 Spring Boot 2.7.18<br/>Framework"]
        HIBERNATE["🗄️ Hibernate<br/>ORM"]
        MAVEN["📦 Maven<br/>Build Tool"]
    end

    %% Conexões da Apresentação
    POSTMAN -->|HTTP Requests<br/>JSON| REST_API
    REST_API -->|DTO| DTO_MAPPER
    REST_API -->|Swagger Docs| SWAGGER

    %% Conexões da Aplicação
    DTO_MAPPER -->|Validated Input| VALIDATION
    VALIDATION -->|Business Operations| STOCK_SERVICE
    STOCK_SERVICE -->|Domain Calls| STOCK_ENTITY

    %% Conexões do Domínio
    STOCK_ENTITY -->|Uses| VALUE_OBJECTS
    STOCK_ENTITY -->|Validates via| BUSINESS_RULES
    STOCK_SERVICE -->|Repository Pattern| STOCK_REPOSITORY

    %% Conexões da Infraestrutura
    STOCK_REPOSITORY -.->|Implementation| JPA_REPOSITORY
    JPA_REPOSITORY -->|JPA/Hibernate| DATABASE_CONFIG
    DATABASE_CONFIG -->|JDBC Connection| POSTGRESQL

    %% Conexões Kafka
    STOCK_SERVICE -->|Publish Events| KAFKA_PRODUCER
    KAFKA_PRODUCER -->|Messages| KAFKA_CLUSTER
    KAFKA_CLUSTER -->|Consume Events| KAFKA_CONSUMER
    KAFKA_CONSUMER -->|Process Messages| STOCK_SERVICE

    %% Conexões de Tecnologia
    REST_API -.->|Powered by| SPRING_BOOT
    JPA_REPOSITORY -.->|Powered by| HIBERNATE
    STOCK_SERVICE -.->|Built with| MAVEN
    POSTGRESQL -.->|Runs on| DOCKER
    KAFKA_CLUSTER -.->|Managed by| KAFKA_UI

    %% Aplicação de estilos
    class PL presentationLayer
    class AL applicationLayer
    class DL domainLayer
    class IL infrastructureLayer
    class ES externalSystems
    class TECH technology
```

## 🔄 Fluxo de Mensagens e Dados

```mermaid
sequenceDiagram
    participant Client as 📱 Postman Client
    participant API as 🌐 REST API (8084)
    participant App as ⚙️ Application Service
    participant Domain as 🏛️ Domain Layer
    participant Infra as 🔧 Infrastructure
    participant DB as 🐘 PostgreSQL (5432)
    participant Kafka as 🔄 Kafka (9092)

    Note over Client,Kafka: Virtual Stock Creation Flow

    Client->>+API: POST /api/v1/virtual-stock/stocks
    Note right of Client: HTTP Request<br/>Content-Type: application/json<br/>{"stockCode": "PROD001", "quantity": 100}

    API->>+App: createStock(StockRequest)
    Note right of API: DTO Validation<br/>Bean Validation

    App->>+Domain: Stock.create(stockCode, quantity)
    Note right of App: Business Logic<br/>Domain Rules

    Domain->>+Domain: validate()
    Note right of Domain: Business Rules<br/>- Quantity > 0<br/>- StockCode format

    Domain->>+Infra: stockRepository.save(stock)
    Note right of Domain: Repository Pattern<br/>Interface Implementation

    Infra->>+DB: INSERT INTO stocks
    Note right of Infra: JPA/Hibernate<br/>SQL Generation
    DB-->>-Infra: Stock Saved

    Infra->>+Kafka: publishStockCreatedEvent()
    Note right of Infra: Event Publishing<br/>Topic: stock-events
    Kafka-->>-Infra: Event Published

    Infra-->>-Domain: Stock Entity
    Domain-->>-App: Stock Created
    App-->>-API: StockResponse
    API-->>-Client: HTTP 201 Created

    Note over Client,Kafka: {"success": true, "data": {...}, "timestamp": "..."}
```

## 🏗️ Arquitetura Hexagonal (Ports & Adapters)

```mermaid
graph TB
    %% Definição de estilos
    classDef coreStyle fill:#fff3e0,stroke:#ef6c00,stroke-width:3px
    classDef portStyle fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px
    classDef adapterStyle fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef externalStyle fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px

    %% Core Domain (Hexagon Center)
    subgraph CORE ["🏛️ CORE DOMAIN"]
        ENTITIES["📋 Entities<br/>Stock, StockCode"]
        SERVICES["⚙️ Domain Services<br/>Business Logic"]
        RULES["⚖️ Business Rules<br/>Validation Logic"]
    end

    %% Primary Ports (Left Side - Driving)
    subgraph PRIMARY_PORTS ["🚪 Primary Ports (Driving)"]
        STOCK_USE_CASE["📦 StockUseCase<br/>Interface"]
        QUERY_PORT["🔍 QueryPort<br/>Interface"]
    end

    %% Secondary Ports (Right Side - Driven)
    subgraph SECONDARY_PORTS ["🔌 Secondary Ports (Driven)"]
        PERSISTENCE_PORT["🗄️ PersistencePort<br/>Repository Interface"]
        MESSAGING_PORT["📤 MessagingPort<br/>Event Publisher Interface"]
        NOTIFICATION_PORT["🔔 NotificationPort<br/>Interface"]
    end

    %% Primary Adapters (Left Side)
    subgraph PRIMARY_ADAPTERS ["🌐 Primary Adapters"]
        REST_CONTROLLER["🌍 REST Controller<br/>@RestController<br/>Port 8084"]
        WEB_UI["🖥️ Web UI<br/>Future Implementation"]
    end

    %% Secondary Adapters (Right Side)
    subgraph SECONDARY_ADAPTERS ["🔧 Secondary Adapters"]
        JPA_ADAPTER["🗃️ JPA Adapter<br/>PostgreSQL<br/>Port 5432"]
        KAFKA_ADAPTER["📨 Kafka Adapter<br/>Message Broker<br/>Port 9092"]
        EMAIL_ADAPTER["📧 Email Adapter<br/>SMTP Service"]
    end

    %% External Systems
    subgraph EXTERNAL ["🌍 External Systems"]
        POSTMAN_CLIENT["📱 Postman<br/>172.30.221.62:8084"]
        POSTGRES_DB["🐘 PostgreSQL<br/>virtualstock DB"]
        KAFKA_BROKER["🔄 Kafka Cluster<br/>Topics & Partitions"]
    end

    %% Primary Flow (Left to Right)
    POSTMAN_CLIENT -->|HTTP Requests| REST_CONTROLLER
    REST_CONTROLLER -->|Implements| STOCK_USE_CASE
    STOCK_USE_CASE -->|Uses| CORE
    
    %% Secondary Flow (Right to Left)
    CORE -->|Requires| PERSISTENCE_PORT
    CORE -->|Requires| MESSAGING_PORT
    PERSISTENCE_PORT -.->|Implemented by| JPA_ADAPTER
    MESSAGING_PORT -.->|Implemented by| KAFKA_ADAPTER
    
    %% External Connections
    JPA_ADAPTER -->|JDBC| POSTGRES_DB
    KAFKA_ADAPTER -->|TCP| KAFKA_BROKER

    %% Styling
    class CORE coreStyle
    class PRIMARY_PORTS,SECONDARY_PORTS portStyle
    class PRIMARY_ADAPTERS,SECONDARY_ADAPTERS adapterStyle
    class EXTERNAL externalStyle
```

## 🐳 Infraestrutura Docker & WSL2

```mermaid
graph TB
    %% Definição de estilos
    classDef hostStyle fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef wslStyle fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef containerStyle fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef networkStyle fill:#fce4ec,stroke:#c2185b,stroke-width:2px

    %% Windows Host
    subgraph WINDOWS ["💻 Windows Host"]
        POSTMAN_WIN["📱 Postman<br/>localhost:8084<br/>(via WSL2 bridge)"]
        BROWSER["🌐 Browser<br/>Kafka UI: 8090"]
        VS_CODE["💻 VS Code<br/>Development"]
    end

    %% WSL2 Environment
    subgraph WSL2 ["🐧 WSL2 Ubuntu"]
        DOCKER_ENGINE["🐳 Docker Engine<br/>Container Runtime"]
        
        subgraph DOCKER_NETWORK ["🌐 Docker Network: kbnt-network"]
            
            subgraph CONTAINERS ["📦 Containers"]
                POSTGRES_CONTAINER["🐘 PostgreSQL Container<br/>Name: kbnt-postgres-simple<br/>Internal: postgres:5432<br/>External: 172.30.221.62:5432"]
                
                STOCK_CONTAINER["📦 Virtual Stock Service<br/>Name: virtual-stock-simple<br/>Internal: app:8080<br/>External: 172.30.221.62:8084"]
                
                KAFKA_CONTAINER["🔄 Kafka Container<br/>Name: kbnt-kafka<br/>Internal: kafka:9092<br/>External: 172.30.221.62:9092"]
                
                ZOOKEEPER_CONTAINER["🏗️ Zookeeper Container<br/>Name: kbnt-zookeeper<br/>Internal: zookeeper:2181<br/>External: 172.30.221.62:2181"]
            end
        end
    end

    %% Port Mappings & Network Flow
    POSTMAN_WIN -.->|WSL2 Bridge<br/>172.30.221.62:8084| STOCK_CONTAINER
    BROWSER -.->|WSL2 Bridge<br/>172.30.221.62:8090| KAFKA_CONTAINER
    
    STOCK_CONTAINER -->|Internal Network<br/>postgres:5432| POSTGRES_CONTAINER
    STOCK_CONTAINER -->|Internal Network<br/>kafka:9092| KAFKA_CONTAINER
    KAFKA_CONTAINER -->|Internal Network<br/>zookeeper:2181| ZOOKEEPER_CONTAINER

    %% Health Checks & Dependencies
    STOCK_CONTAINER -.->|Health Check<br/>depends_on| POSTGRES_CONTAINER
    KAFKA_CONTAINER -.->|Health Check<br/>depends_on| ZOOKEEPER_CONTAINER

    %% Docker Compose Management
    VS_CODE -->|docker-compose.simple.yml<br/>Build & Deploy| DOCKER_ENGINE
    DOCKER_ENGINE -->|Manages| CONTAINERS

    %% Styling
    class WINDOWS hostStyle
    class WSL2 wslStyle
    class CONTAINERS containerStyle
    class DOCKER_NETWORK networkStyle
```

## 📊 Métricas e Monitoramento

```mermaid
graph LR
    %% Definição de estilos
    classDef metricsStyle fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px
    classDef alertStyle fill:#ffebee,stroke:#c62828,stroke-width:2px
    classDef dashStyle fill:#e1f5fe,stroke:#0277bd,stroke-width:2px

    subgraph MONITORING ["📊 Monitoring & Observability"]
        ACTUATOR["🏥 Spring Actuator<br/>/actuator/health<br/>/actuator/metrics"]
        LOGS["📋 Application Logs<br/>Structured Logging"]
        METRICS["📈 Performance Metrics<br/>Response Time, Throughput"]
    end

    subgraph KAFKA_MONITORING ["🔍 Kafka Monitoring"]
        KAFKA_UI_MONITOR["🎛️ Kafka UI<br/>Topic Management<br/>Consumer Groups<br/>Message Browsing"]
        KAFKA_METRICS["📊 Kafka Metrics<br/>Partition Status<br/>Lag Monitoring"]
    end

    subgraph DATABASE_MONITORING ["🐘 Database Monitoring"]
        PG_HEALTH["🏥 PostgreSQL Health<br/>Connection Pool<br/>Query Performance"]
        PG_LOGS["📋 Database Logs<br/>Query Logging<br/>Error Tracking"]
    end

    ACTUATOR -->|Exposes| METRICS
    STOCK_CONTAINER -->|Publishes| LOGS
    KAFKA_CONTAINER -->|Monitored by| KAFKA_UI_MONITOR
    POSTGRES_CONTAINER -->|Health via| PG_HEALTH

    class MONITORING metricsStyle
    class KAFKA_MONITORING dashStyle
    class DATABASE_MONITORING dashStyle
```

## 🚀 Status da Implementação

### ✅ Componentes Implementados
- ✅ Clean Architecture com 4 camadas bem definidas
- ✅ Arquitetura Hexagonal (Ports & Adapters)
- ✅ PostgreSQL configurado e funcionando
- ✅ Virtual Stock Service API REST completa
- ✅ Docker containerização com WSL2
- ✅ Kafka para mensageria (infraestrutura pronta)
- ✅ Health checks e monitoramento
- ✅ Testes de conectividade WSL2 ↔ Windows

### 🎯 Endpoints Funcionais
- **GET** `/api/v1/virtual-stock/stocks` - Listar stocks
- **POST** `/api/v1/virtual-stock/stocks` - Criar stock
- **GET** `/api/v1/virtual-stock/stocks/{id}` - Buscar por ID
- **PUT** `/api/v1/virtual-stock/stocks/{id}/quantity` - Atualizar quantidade

### 🌐 Acesso
- **API URL**: `http://172.30.221.62:8084`
- **Database**: PostgreSQL na porta 5432
- **Kafka**: Disponível na porta 9092
- **Status**: 🟢 ONLINE e FUNCIONAL
