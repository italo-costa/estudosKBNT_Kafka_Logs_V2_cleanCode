# Kafka Topics Configuration

This directory contains topic-specific configurations that can be deployed independently of microservices.

## Topic Structure

```
kafka/topics/
├── application-logs/
│   ├── topic-config.yaml
│   ├── consumer-groups.yaml
│   └── schemas/
├── error-logs/
├── audit-logs/
└── financial-logs/
```

## Deployment Order

1. **Infrastructure First**: Deploy Kafka cluster and Zookeeper
2. **Topics Configuration**: Create topics with specific configurations
3. **Microservices**: Deploy producer/consumer services independently

## Topic Specifications

| Topic | Partitions | Replication | Retention | Cleanup Policy |
|-------|------------|-------------|-----------|----------------|
| application-logs | 3 | 2 | 3 days | delete |
| error-logs | 3 | 2 | 7 days | delete |
| audit-logs | 2 | 2 | 30 days | compact |
| financial-logs | 3 | 2 | 90 days | compact |
