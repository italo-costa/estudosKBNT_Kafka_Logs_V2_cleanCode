# Instalação do Red Hat AMQ Streams

Este documento explica como instalar e configurar o Red Hat AMQ Streams (versão community/gratuita).

## 🔴 Sobre as Versões

### AMQ Streams Community (Gratuita)
- Baseada no projeto Strimzi
- Totalmente funcional
- Sem suporte oficial da Red Hat
- Ideal para estudos e desenvolvimento

### AMQ Streams Supported (Paga)
- Inclui suporte enterprise da Red Hat
- SLA garantido
- Para ambientes de produção

## 📋 Opções de Instalação

### Opção 1: Strimzi (Recomendado para Estudos)

```bash
# Instalar operador Strimzi
kubectl create namespace kafka
kubectl apply -f 'https://strimzi.io/install/latest?namespace=kafka' -n kafka

# Verificar instalação
kubectl get pod -n kafka -l=name=strimzi-cluster-operator
```

### Opção 2: OperatorHub (OpenShift)

```bash
# Via interface web do OpenShift
# Console → Operators → OperatorHub → AMQ Streams

# Ou via CLI
oc new-project kafka
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: amq-streams
  namespace: kafka
spec:
  channel: stable
  name: amq-streams
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF
```

### Opção 3: Red Hat Registry (Precisa de login)

```bash
# Login no registry da Red Hat
podman login registry.redhat.io

# Pull das imagens
podman pull registry.redhat.io/amq7/amq-streams-rhel8-operator:2.4.0
```

## 🚀 Deploy do Cluster Kafka

### 1. Deploy usando Custom Resources

```bash
# Aplicar manifesto do cluster
kubectl apply -f kubernetes/kafka/kafka-cluster.yaml

# Verificar status
kubectl get kafka -n kafka
kubectl get pods -n kafka
```

### 2. Aguardar cluster estar pronto

```bash
# Monitorar deploy
kubectl wait kafka/kafka-cluster --for=condition=Ready --timeout=300s -n kafka

# Verificar status detalhado
kubectl describe kafka kafka-cluster -n kafka
```

### 3. Criar tópicos

```bash
# Via Custom Resources
kubectl apply -f kubernetes/kafka/kafka-topics.yaml

# Ou via linha de comando
kubectl exec -it kafka-cluster-kafka-0 -n kafka -- /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --create --topic application-logs \
  --partitions 3 --replication-factor 3
```

## 🔧 Configurações Importantes

### Cluster Kafka
```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: kafka-cluster
spec:
  kafka:
    version: 3.4.0
    replicas: 3
    listeners:
      - name: plain
        port: 9092
        type: internal
        tls: false
    config:
      # Configurações específicas para logs
      log.retention.hours: 168
      compression.type: "snappy"
      auto.create.topics.enable: true
```

### Tópicos Otimizados para Logs
```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaTopic
metadata:
  name: application-logs
spec:
  partitions: 6
  replicas: 3
  config:
    retention.ms: 604800000  # 7 dias
    compression.type: "snappy"
    cleanup.policy: "delete"
```

## 📊 Monitoramento

### Habilitar Métricas Prometheus

```yaml
# No spec do Kafka
metricsConfig:
  type: jmxPrometheusExporter
  valueFrom:
    configMapKeyRef:
      name: kafka-metrics
      key: kafka-metrics-config.yml
```

### Grafana Dashboards

O AMQ Streams/Strimzi fornece dashboards prontos:
- Cluster Overview
- Kafka Broker Metrics
- Topic Metrics
- Consumer Lag

## 🔍 Troubleshooting

### Verificar Status do Operador

```bash
kubectl get pods -n kafka -l=name=strimzi-cluster-operator
kubectl logs -n kafka -l=name=strimzi-cluster-operator
```

### Verificar Status do Cluster

```bash
kubectl get kafka -n kafka -o yaml
kubectl describe kafka kafka-cluster -n kafka
```

### Verificar Pods

```bash
kubectl get pods -n kafka
kubectl logs kafka-cluster-kafka-0 -n kafka
```

### Comandos de Debug

```bash
# Entrar em um pod Kafka
kubectl exec -it kafka-cluster-kafka-0 -n kafka -- bash

# Testar conectividade
kubectl exec -it kafka-cluster-kafka-0 -n kafka -- /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 --list

# Ver configurações
kubectl exec -it kafka-cluster-kafka-0 -n kafka -- cat /tmp/strimzi.properties
```

## 🎯 Próximos Passos

1. [Configurar Produtores e Consumidores](kafka-clients.md)
2. [Implementar Monitoramento](monitoring.md)
3. [Configurar Segurança](security.md)
4. [Performance Tuning](performance.md)

## 📚 Referências

- [Strimzi Documentation](https://strimzi.io/docs/operators/latest/overview.html)
- [Red Hat AMQ Streams](https://access.redhat.com/documentation/en-us/red_hat_amq_streams/)
- [Kafka Custom Resources](https://strimzi.io/docs/operators/latest/using.html#type-Kafka-reference)
