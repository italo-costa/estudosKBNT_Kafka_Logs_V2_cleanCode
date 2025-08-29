# 🏗️ Arquitetura Hexagonal - Microserviços

## 📋 Visão Geral da Arquitetura Hexagonal

A Arquitetura Hexagonal (também conhecida como Ports and Adapters) separa a lógica de negócio dos detalhes de infraestrutura, criando uma aplicação mais testável e flexível.

```
                    🏗️ ARQUITETURA HEXAGONAL
    
    ┌─────────────────────────────────────────────────────────────┐
    │                     ADAPTADORES PRIMÁRIOS                  │
    │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
    │  │   REST API   │  │  GraphQL API │  │   gRPC API   │     │
    │  │  Controller  │  │   Resolver   │  │   Service    │     │
    │  └──────────────┘  └──────────────┘  └──────────────┘     │
    └─────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────▼───────────────┐
                    │           PORTAS              │
                    │  ┌─────────────────────────┐  │
                    │  │    APPLICATION CORE     │  │
                    │  │                         │  │
                    │  │  ┌─────────────────┐    │  │
                    │  │  │   DOMAIN        │    │  │
                    │  │  │   ENTITIES      │    │  │
                    │  │  │   SERVICES      │    │  │
                    │  │  │   PORTS         │    │  │
                    │  │  └─────────────────┘    │  │
                    │  │                         │  │
                    │  │  ┌─────────────────┐    │  │
                    │  │  │   USE CASES     │    │  │
                    │  │  │   APPLICATION   │    │  │
                    │  │  │   SERVICES      │    │  │
                    │  │  └─────────────────┘    │  │
                    │  └─────────────────────────┘  │
                    └───────────────┬───────────────┘
                                    │
    ┌─────────────────────────────────────────────────────────────┐
    │                   ADAPTADORES SECUNDÁRIOS                  │
    │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
    │  │    Kafka     │  │  PostgreSQL  │  │ External API │     │
    │  │   Adapter    │  │   Adapter    │  │   Adapter    │     │
    │  └──────────────┘  └──────────────┘  └──────────────┘     │
    └─────────────────────────────────────────────────────────────┘
```

## 🔧 Estrutura dos Microserviços

### **Log Producer Service - Arquitetura Hexagonal**
```
src/main/java/com/kbnt/logproducer/
├── domain/                              # 🏛️ DOMÍNIO
│   ├── model/
│   │   ├── LogEntry.java               # Entidade de domínio
│   │   ├── LogLevel.java               # Value Object
│   │   └── RequestId.java              # Value Object
│   ├── port/
│   │   ├── input/                      # Portas de entrada
│   │   │   ├── LogProductionUseCase.java
│   │   │   └── LogValidationUseCase.java
│   │   └── output/                     # Portas de saída
│   │       ├── LogPublisherPort.java
│   │       ├── LogValidatorPort.java
│   │       └── MetricsPort.java
│   └── service/                        # Serviços de domínio
│       ├── LogDomainService.java
│       └── LogRoutingService.java
├── application/                         # 📋 APLICAÇÃO
│   ├── usecase/
│   │   ├── LogProductionUseCaseImpl.java
│   │   └── LogValidationUseCaseImpl.java
│   └── service/
│       └── LogApplicationService.java
└── infrastructure/                      # 🔧 INFRAESTRUTURA
    ├── adapter/
    │   ├── input/                      # Adaptadores primários
    │   │   ├── rest/
    │   │   │   ├── LogController.java
    │   │   │   └── LogDto.java
    │   │   └── messaging/
    │   │       └── LogEventListener.java
    │   └── output/                     # Adaptadores secundários
    │       ├── kafka/
    │       │   ├── KafkaLogPublisher.java
    │       │   └── KafkaConfig.java
    │       ├── validation/
    │       │   └── LogValidatorAdapter.java
    │       └── metrics/
    │           └── MetricsAdapter.java
    └── config/
        ├── BeanConfiguration.java
        └── HexagonalArchitectureConfig.java
```

### **Log Consumer Service - Arquitetura Hexagonal**
```
src/main/java/com/kbnt/logconsumer/
├── domain/                              # 🏛️ DOMÍNIO
│   ├── model/
│   │   ├── ProcessedLog.java           # Entidade de domínio
│   │   ├── ExternalApiRequest.java     # Value Object
│   │   └── ProcessingResult.java       # Value Object
│   ├── port/
│   │   ├── input/                      # Portas de entrada
│   │   │   ├── LogProcessingUseCase.java
│   │   │   └── LogTransformationUseCase.java
│   │   └── output/                     # Portas de saída
│   │       ├── ExternalApiPort.java
│   │       ├── LogStoragePort.java
│   │       └── NotificationPort.java
│   └── service/                        # Serviços de domínio
│       ├── LogTransformationService.java
│       └── ErrorHandlingService.java
├── application/                         # 📋 APLICAÇÃO
│   ├── usecase/
│   │   ├── LogProcessingUseCaseImpl.java
│   │   └── LogTransformationUseCaseImpl.java
│   └── service/
│       └── LogConsumerApplicationService.java
└── infrastructure/                      # 🔧 INFRAESTRUTURA
    ├── adapter/
    │   ├── input/                      # Adaptadores primários
    │   │   ├── kafka/
    │   │   │   ├── KafkaLogConsumer.java
    │   │   │   └── KafkaConfig.java
    │   │   └── rest/
    │   │       └── LogConsumerController.java
    │   └── output/                     # Adaptadores secundários
    │       ├── api/
    │       │   ├── ExternalApiAdapter.java
    │       │   └── ExternalApiClient.java
    │       ├── storage/
    │       │   └── LogStorageAdapter.java
    │       └── notification/
    │           └── NotificationAdapter.java
    └── config/
        ├── BeanConfiguration.java
        └── HexagonalArchitectureConfig.java
```
