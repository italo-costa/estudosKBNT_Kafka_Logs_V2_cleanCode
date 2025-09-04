# ⚙️ Configuration Layer (Camada de Configuração)

A camada de configuração centraliza todas as configurações da aplicação KBNT Kafka Logs, fornecendo um ponto único para gerenciar propriedades, variáveis de ambiente e configurações específicas por ambiente.

## 📋 Índice

- [Visão Geral](#-visão-geral)
- [Estrutura](#-estrutura)
- [Configurações de Aplicação](#-configurações-de-aplicação)
- [Configurações por Ambiente](#-configurações-por-ambiente)
- [Variáveis de Ambiente](#-variáveis-de-ambiente)
- [Configurações de Segurança](#-configurações-de-segurança)
- [Performance Settings](#-performance-settings)
- [Monitoramento](#-monitoramento)
- [Validação](#-validação)
- [Best Practices](#-best-practices)

## 🎯 Visão Geral

Esta camada implementa o padrão de Externalized Configuration, permitindo que a aplicação seja configurada sem necessidade de rebuild. Suporta múltiplos ambientes e fontes de configuração.

### Características Principais:
- **Externalized Configuration**: Configurações fora do código
- **Environment-Specific**: Configurações por ambiente
- **Hierarchical Loading**: Ordem de precedência definida
- **Validation**: Validação de configurações na inicialização
- **Hot Reload**: Recarga dinâmica quando possível
- **Security**: Configurações sensíveis protegidas

## 🏗️ Estrutura

```
08-configuration/
├── application.properties         # Configurações base
├── application-dev.properties     # Desenvolvimento
├── application-test.properties    # Teste
├── application-staging.properties # Staging
├── application-prod.properties    # Produção
├── bootstrap.properties          # Configurações de bootstrap
├── logback-spring.xml            # Configuração de logs
├── requirements.txt              # Dependências Python
├── docker.env                   # Variáveis Docker
├── kubernetes.yaml              # ConfigMaps Kubernetes
└── README.md                    # Este arquivo
```

## ⚙️ Configurações de Aplicação

### application.properties (Base)
```properties
# Application Info
spring.application.name=kbnt-kafka-logs
spring.profiles.active=@spring.profiles.active@
server.port=8080

# Management & Actuator
management.endpoints.web.exposure.include=health,info,metrics,prometheus
management.endpoint.health.show-details=when-authorized
management.metrics.export.prometheus.enabled=true

# Database Configuration
spring.datasource.driver-class-name=org.postgresql.Driver
spring.datasource.hikari.maximum-pool-size=20
spring.datasource.hikari.minimum-idle=5
spring.datasource.hikari.connection-timeout=30000
spring.datasource.hikari.idle-timeout=600000
spring.datasource.hikari.max-lifetime=1800000

# JPA Configuration
spring.jpa.hibernate.ddl-auto=validate
spring.jpa.show-sql=false
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect
spring.jpa.properties.hibernate.format_sql=true
spring.jpa.properties.hibernate.jdbc.batch_size=25
spring.jpa.properties.hibernate.order_inserts=true
spring.jpa.properties.hibernate.order_updates=true

# Kafka Base Configuration
spring.kafka.bootstrap-servers=localhost:9092
spring.kafka.producer.acks=all
spring.kafka.producer.retries=3
spring.kafka.producer.batch-size=32768
spring.kafka.producer.linger-ms=5
spring.kafka.producer.buffer-memory=67108864
spring.kafka.consumer.group-id=kbnt-consumer-group
spring.kafka.consumer.auto-offset-reset=earliest
spring.kafka.consumer.enable-auto-commit=false

# Redis Configuration
spring.redis.host=localhost
spring.redis.port=6379
spring.redis.timeout=2000ms
spring.redis.lettuce.pool.max-active=20
spring.redis.lettuce.pool.max-idle=10
spring.redis.lettuce.pool.min-idle=5

# Logging Configuration
logging.level.root=INFO
logging.level.com.kbnt=DEBUG
logging.pattern.console=%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n
logging.pattern.file=%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n

# Custom Application Properties
app.version=@project.version@
app.build-time=@maven.build.timestamp@
app.stock.default-quantity=100
app.stock.max-quantity=1000000
app.kafka.topics.stock-events=stock-events
app.kafka.topics.log-events=log-events
app.kafka.topics.dead-letter=dead-letter-queue
```

### application-dev.properties (Desenvolvimento)
```properties
# Development Database
spring.datasource.url=jdbc:postgresql://localhost:5432/kbnt_dev
spring.datasource.username=dev_user
spring.datasource.password=dev_pass

# Development Kafka
spring.kafka.bootstrap-servers=localhost:9092

# Development Redis
spring.redis.host=localhost
spring.redis.port=6379

# Development Logging
logging.level.com.kbnt=DEBUG
logging.level.org.springframework.kafka=DEBUG
spring.jpa.show-sql=true

# Development Features
app.features.debug-mode=true
app.features.mock-external-apis=true
app.cache.ttl-seconds=300
app.performance.metrics-enabled=true
```

### application-prod.properties (Produção)
```properties
# Production Database
spring.datasource.url=${DATABASE_URL}
spring.datasource.username=${DATABASE_USERNAME}
spring.datasource.password=${DATABASE_PASSWORD}

# Production Kafka
spring.kafka.bootstrap-servers=${KAFKA_BOOTSTRAP_SERVERS}
spring.kafka.producer.compression-type=snappy
spring.kafka.producer.max-in-flight-requests-per-connection=5
spring.kafka.producer.enable-idempotence=true
spring.kafka.consumer.fetch-min-size=50000
spring.kafka.consumer.max-poll-records=5000

# Production Redis
spring.redis.cluster.nodes=${REDIS_CLUSTER_NODES}
spring.redis.cluster.max-redirects=3
spring.redis.password=${REDIS_PASSWORD}

# Production Logging
logging.level.root=WARN
logging.level.com.kbnt=INFO
logging.file.name=/app/logs/application.log
logging.file.max-size=100MB
logging.file.max-history=30

# Production Features
app.features.debug-mode=false
app.features.mock-external-apis=false
app.cache.ttl-seconds=3600
app.performance.metrics-enabled=true
app.security.encryption-key=${ENCRYPTION_KEY}

# Production Performance
server.tomcat.max-threads=200
server.tomcat.min-spare-threads=20
spring.datasource.hikari.maximum-pool-size=50
spring.kafka.producer.batch-size=65536
spring.kafka.producer.linger-ms=10
```

## 🔐 Configurações de Segurança

### Security Properties
```properties
# Security Configuration
spring.security.oauth2.resourceserver.jwt.issuer-uri=${JWT_ISSUER_URI}
spring.security.oauth2.resourceserver.jwt.jwk-set-uri=${JWK_SET_URI}

# CORS Configuration
app.security.cors.allowed-origins=${CORS_ALLOWED_ORIGINS:http://localhost:3000}
app.security.cors.allowed-methods=GET,POST,PUT,DELETE,OPTIONS
app.security.cors.allowed-headers=*
app.security.cors.allow-credentials=true

# Rate Limiting
app.security.rate-limit.requests-per-minute=1000
app.security.rate-limit.burst-capacity=1500

# API Security
app.security.api-key.header-name=X-API-Key
app.security.api-key.required-for-admin=true

# SSL/TLS Configuration
server.ssl.enabled=${SSL_ENABLED:false}
server.ssl.key-store=${SSL_KEYSTORE_PATH}
server.ssl.key-store-password=${SSL_KEYSTORE_PASSWORD}
server.ssl.key-store-type=PKCS12
```

## ⚡ Performance Settings

### Performance Configuration
```properties
# JVM Performance
-Xms2g
-Xmx4g
-XX:+UseG1GC
-XX:MaxGCPauseMillis=200
-XX:+UseStringDeduplication

# Application Performance
spring.task.execution.pool.core-size=10
spring.task.execution.pool.max-size=50
spring.task.execution.pool.queue-capacity=1000
spring.task.scheduling.pool.size=5

# Cache Configuration
spring.cache.type=redis
spring.cache.redis.time-to-live=PT30M
spring.cache.redis.cache-null-values=false

# Connection Pooling
spring.datasource.hikari.maximum-pool-size=${DB_POOL_SIZE:30}
spring.datasource.hikari.minimum-idle=${DB_POOL_MIN_IDLE:10}
spring.datasource.hikari.connection-timeout=${DB_CONNECTION_TIMEOUT:30000}
spring.datasource.hikari.validation-timeout=5000
spring.datasource.hikari.leak-detection-threshold=60000

# Kafka Performance
spring.kafka.producer.batch-size=${KAFKA_BATCH_SIZE:32768}
spring.kafka.producer.linger-ms=${KAFKA_LINGER_MS:5}
spring.kafka.producer.compression-type=${KAFKA_COMPRESSION:snappy}
spring.kafka.consumer.max-poll-records=${KAFKA_MAX_POLL_RECORDS:500}
spring.kafka.consumer.fetch-min-size=${KAFKA_FETCH_MIN_SIZE:1024}
```

## 📊 Monitoramento

### Monitoring Configuration
```properties
# Metrics Configuration
management.metrics.tags.application=${spring.application.name}
management.metrics.tags.environment=${spring.profiles.active}
management.metrics.distribution.percentiles-histogram.http.server.requests=true
management.metrics.distribution.percentiles.http.server.requests=0.5,0.95,0.99
management.metrics.distribution.slo.http.server.requests=50ms,100ms,200ms,500ms

# Prometheus Configuration
management.metrics.export.prometheus.enabled=true
management.endpoint.prometheus.enabled=true

# Health Checks
management.health.kafka.enabled=true
management.health.redis.enabled=true
management.health.db.enabled=true
management.health.custom.enabled=true

# Tracing Configuration
management.tracing.enabled=true
management.tracing.sampling.probability=0.1
spring.application.name=${spring.application.name}
```

### logback-spring.xml
```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <springProfile name="!prod">
        <include resource="org/springframework/boot/logging/logback/base.xml"/>
    </springProfile>
    
    <springProfile name="prod">
        <include resource="org/springframework/boot/logging/logback/file-appender.xml"/>
        
        <appender name="KAFKA" class="com.github.danielwegener.logback.kafka.KafkaAppender">
            <encoder class="net.logstash.logback.encoder.LoggingEventCompositeJsonEncoder">
                <providers>
                    <timestamp/>
                    <logLevel/>
                    <loggerName/>
                    <mdc/>
                    <arguments/>
                    <message/>
                    <stackTrace/>
                </providers>
            </encoder>
            <topic>application-logs</topic>
            <keyingStrategy class="com.github.danielwegener.logback.kafka.keying.HostNameKeyingStrategy"/>
            <deliveryStrategy class="com.github.danielwegener.logback.kafka.delivery.AsynchronousDeliveryStrategy"/>
            <producerConfig>bootstrap.servers=${KAFKA_BOOTSTRAP_SERVERS}</producerConfig>
        </appender>
        
        <root level="INFO">
            <appender-ref ref="FILE"/>
            <appender-ref ref="KAFKA"/>
        </root>
    </springProfile>
    
    <!-- Application specific loggers -->
    <logger name="com.kbnt" level="${KBNT_LOG_LEVEL:INFO}"/>
    <logger name="org.springframework.kafka" level="WARN"/>
    <logger name="org.apache.kafka" level="WARN"/>
    <logger name="org.hibernate.SQL" level="DEBUG"/>
    <logger name="org.hibernate.type.descriptor.sql.BasicBinder" level="TRACE"/>
</configuration>
```

## 🐳 Docker Environment

### docker.env
```bash
# Application
SPRING_PROFILES_ACTIVE=docker
JAVA_OPTS=-Xms1g -Xmx2g -XX:+UseG1GC

# Database
DATABASE_URL=jdbc:postgresql://postgres:5432/kbnt_db
DATABASE_USERNAME=kbnt_user
DATABASE_PASSWORD=kbnt_secure_password

# Kafka
KAFKA_BOOTSTRAP_SERVERS=kafka1:9092,kafka2:9092,kafka3:9092

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=redis_secure_password

# Security
JWT_ISSUER_URI=https://auth.kbnt.com
JWK_SET_URI=https://auth.kbnt.com/.well-known/jwks.json
ENCRYPTION_KEY=secure_encryption_key_here

# Monitoring
PROMETHEUS_ENABLED=true
JAEGER_AGENT_HOST=jaeger
JAEGER_AGENT_PORT=6831
```

## ☸️ Kubernetes ConfigMap

### kubernetes.yaml
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: kbnt-config
  namespace: kbnt-kafka-logs
data:
  application.properties: |
    spring.profiles.active=kubernetes
    spring.kafka.bootstrap-servers=kafka-service:9092
    spring.datasource.url=jdbc:postgresql://postgres-service:5432/kbnt_db
    spring.redis.host=redis-service
    management.metrics.export.prometheus.enabled=true
  
  logback-spring.xml: |
    <?xml version="1.0" encoding="UTF-8"?>
    <configuration>
        <include resource="org/springframework/boot/logging/logback/defaults.xml"/>
        <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
            <encoder class="net.logstash.logback.encoder.LoggingEventCompositeJsonEncoder">
                <providers>
                    <timestamp/>
                    <logLevel/>
                    <loggerName/>
                    <mdc/>
                    <message/>
                    <stackTrace/>
                </providers>
            </encoder>
        </appender>
        <root level="INFO">
            <appender-ref ref="STDOUT"/>
        </root>
    </configuration>

---
apiVersion: v1
kind: Secret
metadata:
  name: kbnt-secrets
  namespace: kbnt-kafka-logs
type: Opaque
data:
  database-password: a2JudF9zZWN1cmVfcGFzc3dvcmQ=  # base64 encoded
  redis-password: cmVkaXNfc2VjdXJlX3Bhc3N3b3Jk      # base64 encoded
  encryption-key: c2VjdXJlX2VuY3J5cHRpb25fa2V5X2hlcmU=  # base64 encoded
```

## ✅ Validação de Configurações

### Configuration Validation
```java
@Configuration
@ConfigurationProperties(prefix = "app")
@Validated
public class AppProperties {
    
    @NotNull
    @Size(min = 3, max = 50)
    private String version;
    
    @Valid
    private Stock stock = new Stock();
    
    @Valid
    private Kafka kafka = new Kafka();
    
    @Valid
    private Security security = new Security();
    
    @Data
    @Validated
    public static class Stock {
        @Min(1)
        @Max(1000000)
        private Integer defaultQuantity = 100;
        
        @Min(1)
        private Integer maxQuantity = 1000000;
    }
    
    @Data
    @Validated
    public static class Kafka {
        @NotEmpty
        private Map<String, String> topics = new HashMap<>();
        
        @Min(1)
        @Max(32)
        private Integer retries = 3;
    }
    
    @Data
    @Validated
    public static class Security {
        @NotNull
        private Boolean debugMode = false;
        
        @Pattern(regexp = "^[A-Za-z0-9+/=]{32,}$")
        private String encryptionKey;
    }
}
```

## 📚 Best Practices

### 1. **Hierarquia de Configurações**
```
1. application.properties (base)
2. application-{profile}.properties
3. Environment Variables
4. Command Line Arguments
5. External Config Server
```

### 2. **Sensitive Data**
- ✅ Use variáveis de ambiente para senhas
- ✅ Use Spring Cloud Config para secrets
- ✅ Use Kubernetes Secrets
- ❌ Nunca commitar senhas no código

### 3. **Naming Conventions**
```properties
# Good
app.feature.cache-enabled=true
app.security.jwt.expiration-time=3600

# Bad
cacheEnabled=true
jwtExp=3600
```

### 4. **Documentation**
```properties
# Stock Management Configuration
# Default quantity assigned to new stock items
app.stock.default-quantity=100

# Maximum allowed quantity per stock item
# Must be positive integer <= 1,000,000
app.stock.max-quantity=1000000
```

## 🔧 Configuration Management Tools

### Scripts Úteis:
```bash
# Validar configurações
./scripts/validate-config.sh

# Gerar configurações para ambiente
./scripts/generate-config.sh --env=prod

# Aplicar configurações no Kubernetes
kubectl apply -f kubernetes/configmaps/

# Reload configurações (quando suportado)
curl -X POST http://localhost:8080/actuator/refresh
```

---

**Autor**: KBNT Development Team  
**Versão**: 2.1.0  
**Última Atualização**: Janeiro 2025
