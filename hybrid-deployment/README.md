# Configuração Híbrida: Microserviços Local + AMQ Streams Red Hat

Esta configuração permite que os microserviços Spring Boot rodem no seu cluster Kubernetes local, enquanto se conectam a um cluster AMQ Streams hospedado em ambiente Red Hat (OpenShift, RHEL, etc.).

## 🏗️ Arquitetura Híbrida

```
┌─────────────────────────────────────┐    ┌──────────────────────────────────┐
│        SEU KUBERNETES LOCAL         │    │      AMBIENTE RED HAT            │
│                                     │    │                                  │
│  ┌─────────────────────────────┐    │    │  ┌─────────────────────────┐     │
│  │    Producer Service         │    │    │  │     AMQ Streams         │     │
│  │    (Spring Boot)            │────┼────┼──│     (Kafka Cluster)     │     │
│  │    Port: 8081               │    │    │  │     Bootstrap: host:9092 │     │
│  └─────────────────────────────┘    │    │  │                         │     │
│                                     │    │  │  Topics:                │     │
│  ┌─────────────────────────────┐    │    │  │  - application-logs     │     │
│  │    Consumer Service         │    │    │  │  - error-logs           │     │
│  │    (Spring Boot)            │────┼────┼──│  - audit-logs           │     │
│  │    Port: 8082               │    │    │  └─────────────────────────┘     │
│  └─────────────────────────────┘    │    │                                  │
│                                     │    │  Red Hat OpenShift / RHEL        │
│  ┌─────────────────────────────┐    │    │  ou Red Hat Managed Kafka        │
│  │    PostgreSQL               │    │    │                                  │
│  │    (Database)               │    │    │                                  │
│  └─────────────────────────────┘    │    │                                  │
└─────────────────────────────────────┘    └──────────────────────────────────┘
```

## 🔧 Configurações Necessárias

### 1. Conectividade de Rede

#### Opção A: VPN/Túnel Seguro
```yaml
# Para ambientes corporativos
apiVersion: v1
kind: ConfigMap
metadata:
  name: kafka-connection-config
data:
  bootstrap-servers: "kafka-cluster.redhat-env.company.com:9092"
  security-protocol: "SASL_SSL"
  sasl-mechanism: "SCRAM-SHA-512"
```

#### Opção B: Exposição Pública (Desenvolvimento)
```yaml
# AMQ Streams com LoadBalancer/NodePort
apiVersion: v1
kind: ConfigMap
metadata:
  name: kafka-connection-config
data:
  bootstrap-servers: "203.0.113.100:9092" # IP público do ambiente Red Hat
  security-protocol: "PLAINTEXT"
```

### 2. Configuração de Segurança

#### Para Ambiente Corporativo (Recomendado):
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: kafka-credentials
type: Opaque
stringData:
  username: "microservices-user"
  password: "your-secure-password"
  truststore.jks: |
    # Base64 encoded truststore
  keystore.jks: |
    # Base64 encoded keystore
```

## 📋 Implementação

### 1. Configuração do Producer Service

#### application-hybrid.yml:
```yaml
spring:
  kafka:
    bootstrap-servers: ${KAFKA_EXTERNAL_BOOTSTRAP_SERVERS:kafka-cluster.redhat-env.com:9092}
    producer:
      acks: all
      retries: 5
      batch-size: 16384
      linger-ms: 10
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.springframework.kafka.support.serializer.JsonSerializer
      properties:
        # Configurações de segurança
        security.protocol: ${KAFKA_SECURITY_PROTOCOL:SASL_SSL}
        sasl.mechanism: ${KAFKA_SASL_MECHANISM:SCRAM-SHA-512}
        sasl.jaas.config: >
          org.apache.kafka.common.security.scram.ScramLoginModule required
          username="${KAFKA_USERNAME}"
          password="${KAFKA_PASSWORD}";
        # TLS Configuration
        ssl.truststore.location: ${KAFKA_TRUSTSTORE_LOCATION:/etc/kafka/truststore.jks}
        ssl.truststore.password: ${KAFKA_TRUSTSTORE_PASSWORD}
        # Timeout configurations para rede externa
        request.timeout.ms: 60000
        delivery.timeout.ms: 300000
        retry.backoff.ms: 1000
```

### 2. Configuração do Consumer Service

#### application-hybrid.yml:
```yaml
spring:
  kafka:
    bootstrap-servers: ${KAFKA_EXTERNAL_BOOTSTRAP_SERVERS:kafka-cluster.redhat-env.com:9092}
    consumer:
      group-id: ${KAFKA_CONSUMER_GROUP:microservices-consumer-group}
      auto-offset-reset: earliest
      key-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      value-deserializer: org.springframework.kafka.support.serializer.JsonDeserializer
      properties:
        # Configurações de segurança
        security.protocol: ${KAFKA_SECURITY_PROTOCOL:SASL_SSL}
        sasl.mechanism: ${KAFKA_SASL_MECHANISM:SCRAM-SHA-512}
        sasl.jaas.config: >
          org.apache.kafka.common.security.scram.ScramLoginModule required
          username="${KAFKA_USERNAME}"
          password="${KAFKA_PASSWORD}";
        # TLS Configuration
        ssl.truststore.location: ${KAFKA_TRUSTSTORE_LOCATION:/etc/kafka/truststore.jks}
        ssl.truststore.password: ${KAFKA_TRUSTSTORE_PASSWORD}
        # Consumer specific
        fetch.min.bytes: 1024
        fetch.max.wait.ms: 500
        max.poll.records: 500
        session.timeout.ms: 30000
        heartbeat.interval.ms: 10000
```

## 🚀 Deploy no Kubernetes Local

### 1. ConfigMap para Conexão Externa
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: kafka-external-config
  namespace: microservices
data:
  bootstrap-servers: "kafka-cluster.your-redhat-env.com:9092"
  security-protocol: "SASL_SSL"
  sasl-mechanism: "SCRAM-SHA-512"
  consumer-group: "microservices-logs-consumer"
  topics-application-logs: "application-logs"
  topics-error-logs: "error-logs"
  topics-audit-logs: "audit-logs"
```

### 2. Secret para Credenciais
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: kafka-external-credentials
  namespace: microservices
type: Opaque
stringData:
  kafka-username: "microservices-user"
  kafka-password: "your-secure-password"
  truststore-password: "truststore-pass"
data:
  truststore.jks: LS0tLS1CRUdJTi... # base64 encoded
```

### 3. Deployment do Producer
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: log-producer-service
  namespace: microservices
spec:
  replicas: 2
  selector:
    matchLabels:
      app: log-producer-service
  template:
    metadata:
      labels:
        app: log-producer-service
    spec:
      containers:
      - name: log-producer-service
        image: kbnt/log-producer-service:1.0.0
        ports:
        - containerPort: 8081
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "hybrid"
        - name: KAFKA_EXTERNAL_BOOTSTRAP_SERVERS
          valueFrom:
            configMapKeyRef:
              name: kafka-external-config
              key: bootstrap-servers
        - name: KAFKA_SECURITY_PROTOCOL
          valueFrom:
            configMapKeyRef:
              name: kafka-external-config
              key: security-protocol
        - name: KAFKA_USERNAME
          valueFrom:
            secretKeyRef:
              name: kafka-external-credentials
              key: kafka-username
        - name: KAFKA_PASSWORD
          valueFrom:
            secretKeyRef:
              name: kafka-external-credentials
              key: kafka-password
        volumeMounts:
        - name: kafka-truststore
          mountPath: /etc/kafka
          readOnly: true
      volumes:
      - name: kafka-truststore
        secret:
          secretName: kafka-external-credentials
          items:
          - key: truststore.jks
            path: truststore.jks
```

### 4. Deployment do Consumer
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: log-consumer-service
  namespace: microservices
spec:
  replicas: 2
  selector:
    matchLabels:
      app: log-consumer-service
  template:
    metadata:
      labels:
        app: log-consumer-service
    spec:
      containers:
      - name: log-consumer-service
        image: kbnt/log-consumer-service:1.0.0
        ports:
        - containerPort: 8082
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "hybrid"
        - name: KAFKA_EXTERNAL_BOOTSTRAP_SERVERS
          valueFrom:
            configMapKeyRef:
              name: kafka-external-config
              key: bootstrap-servers
        - name: KAFKA_CONSUMER_GROUP
          valueFrom:
            configMapKeyRef:
              name: kafka-external-config
              key: consumer-group
        - name: KAFKA_USERNAME
          valueFrom:
            secretKeyRef:
              name: kafka-external-credentials
              key: kafka-username
        - name: KAFKA_PASSWORD
          valueFrom:
            secretKeyRef:
              name: kafka-external-credentials
              key: kafka-password
        volumeMounts:
        - name: kafka-truststore
          mountPath: /etc/kafka
          readOnly: true
      volumes:
      - name: kafka-truststore
        secret:
          secretName: kafka-external-credentials
```

## 🔍 Monitoramento da Conectividade

### Health Checks Personalizados:
```java
@Component
public class KafkaConnectivityHealthIndicator implements HealthIndicator {
    
    @Value("${spring.kafka.bootstrap-servers}")
    private String bootstrapServers;
    
    @Override
    public Health health() {
        try {
            // Testar conectividade com cluster externo
            Properties props = new Properties();
            props.put(AdminClientConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
            props.put(AdminClientConfig.REQUEST_TIMEOUT_MS_CONFIG, 10000);
            
            try (AdminClient adminClient = AdminClient.create(props)) {
                adminClient.listTopics().names().get(10, TimeUnit.SECONDS);
                return Health.up()
                    .withDetail("kafka-cluster", bootstrapServers)
                    .withDetail("status", "connected")
                    .build();
            }
        } catch (Exception e) {
            return Health.down()
                .withDetail("kafka-cluster", bootstrapServers)
                .withDetail("error", e.getMessage())
                .build();
        }
    }
}
```

## 🚨 Considerações de Segurança

### 1. Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: kafka-external-access
spec:
  podSelector:
    matchLabels:
      app: log-producer-service
  policyTypes:
  - Egress
  egress:
  - to: []
    ports:
    - protocol: TCP
      port: 9092  # Kafka port
    - protocol: TCP
      port: 443   # HTTPS
```

### 2. TLS/SSL Configuration
```bash
# Gerar truststore para ambiente Red Hat
keytool -import -alias kafka-ca -file ca-cert.pem -keystore truststore.jks -storepass changeit

# Base64 encode para Secret
base64 -w 0 truststore.jks > truststore.jks.base64
```

## 🧪 Testes de Conectividade

### Script de Teste:
```bash
#!/bin/bash
echo "🧪 Testing Kafka connectivity..."

# Test 1: Network connectivity
echo "Testing network connectivity..."
nc -zv kafka-cluster.redhat-env.com 9092

# Test 2: SSL handshake
echo "Testing SSL handshake..."
openssl s_client -connect kafka-cluster.redhat-env.com:9092 -verify_return_error

# Test 3: Kafka client connectivity
echo "Testing Kafka client..."
kubectl exec -it deployment/log-producer-service -- \
  java -cp /app/lib/* kafka.tools.GetOffsetShell \
  --broker-list kafka-cluster.redhat-env.com:9092 \
  --topic application-logs
```

## 📋 Checklist de Implementação

- [ ] Configurar conectividade de rede (VPN/Firewall)
- [ ] Obter credenciais do ambiente Red Hat
- [ ] Configurar certificados TLS
- [ ] Criar ConfigMaps e Secrets
- [ ] Deploy dos microserviços
- [ ] Testar conectividade
- [ ] Configurar monitoramento
- [ ] Documentar troubleshooting

## 🎯 Próximos Passos

1. [Configurar Credenciais Red Hat](setup-redhat-credentials.md)
2. [Deploy Híbrido Kubernetes](hybrid-kubernetes-deploy.md)
3. [Monitoramento Cross-Cluster](cross-cluster-monitoring.md)
4. [Troubleshooting Conectividade](connectivity-troubleshooting.md)
