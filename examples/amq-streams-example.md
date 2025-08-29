# Exemplo AMQ Streams - Red Hat Kafka

Este exemplo mostra como usar o Red Hat AMQ Streams (versão community) para processamento de logs.

## 🔴 Sobre o AMQ Streams

O Red Hat AMQ Streams é baseado no projeto open-source **Strimzi** e oferece:
- Apache Kafka com recursos enterprise
- Operadores Kubernetes nativos
- Configuração declarativa
- **Versão community gratuita**

## 🚀 Setup Rápido

### 1. Usando Kubernetes com Operador

```powershell
# Instalar operador Strimzi
kubectl create namespace kafka
kubectl apply -f 'https://strimzi.io/install/latest?namespace=kafka' -n kafka

# Deploy do cluster via Custom Resource
kubectl apply -f kubernetes/kafka/kafka-cluster.yaml

# Aguardar estar pronto
kubectl wait kafka/kafka-cluster --for=condition=Ready -n kafka --timeout=600s

# Criar tópicos
kubectl apply -f kubernetes/kafka/kafka-topics.yaml

# Port-forward para acesso local
kubectl port-forward -n kafka svc/kafka-cluster-kafka-bootstrap 9092:9092
```

### 2. Usando Docker com Imagens Red Hat

```powershell
# Navegar para docker
cd docker

# Subir ambiente com AMQ Streams
docker-compose up -d

# Verificar status
docker-compose ps
```

## 📋 Recursos do AMQ Streams vs Kafka Vanilla

| Recurso | Kafka Vanilla | AMQ Streams |
|---------|---------------|-------------|
| Instalação | Manual | Operador Kubernetes |
| Configuração | Arquivos properties | Custom Resources YAML |
| Scaling | Manual | Declarativo |
| Monitoramento | Configuração manual | Métricas integradas |
| Backup | Scripts customizados | Operadores integrados |
| Security | Configuração manual | Templates prontos |
| Updates | Processo manual | Rolling updates automáticos |

## 🔧 Comandos Úteis

### Verificar Cluster
```powershell
# Status do cluster
kubectl get kafka -n kafka

# Detalhes do cluster
kubectl describe kafka kafka-cluster -n kafka

# Pods do cluster
kubectl get pods -n kafka
```

### Gerenciar Tópicos
```powershell
# Listar tópicos (via Custom Resources)
kubectl get kafkatopics -n kafka

# Criar tópico novo
kubectl apply -f - <<EOF
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaTopic
metadata:
  name: new-topic
  namespace: kafka
  labels:
    strimzi.io/cluster: kafka-cluster
spec:
  partitions: 3
  replicas: 3
EOF

# Via linha de comando (dentro do pod)
kubectl exec -n kafka kafka-cluster-kafka-0 -- /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 --list
```

### Monitorar Métricas
```powershell
# Verificar métricas JMX
kubectl exec -n kafka kafka-cluster-kafka-0 -- curl -s http://localhost:9999/metrics

# Port-forward para Prometheus metrics
kubectl port-forward -n kafka kafka-cluster-kafka-0 9404:9404
```

## 🧪 Testar Produção/Consumo

### Terminal 1: Producer
```powershell
python producers/python/log-producer.py --bootstrap-servers localhost:9092 --topic application-logs --count 50
```

### Terminal 2: Consumer
```powershell
python consumers/python/log-consumer.py --bootstrap-servers localhost:9092 --topic application-logs
```

## 📊 Vantagens do AMQ Streams

### Para Estudos:
- ✅ **Declarativo**: Configuração via YAML
- ✅ **Versionado**: Controle de versão das configurações
- ✅ **Reproducível**: Mesmo ambiente sempre
- ✅ **Enterprise-ready**: Recursos profissionais
- ✅ **Gratuito**: Versão community sem limitações funcionais

### Para Produção (versão paga):
- ✅ **Suporte Red Hat**: SLA garantido
- ✅ **Certificação**: Testado para enterprise
- ✅ **Integração**: Com ecossistema Red Hat
- ✅ **Compliance**: Certificações de segurança

## 🔍 Troubleshooting

### Problemas Comuns:

1. **Operador não instala**:
   ```bash
   # Verificar CRDs
   kubectl get crd | grep strimzi
   
   # Logs do operador
   kubectl logs -n kafka -l=name=strimzi-cluster-operator
   ```

2. **Cluster não fica pronto**:
   ```bash
   # Status detalhado
   kubectl describe kafka kafka-cluster -n kafka
   
   # Logs dos pods
   kubectl logs -n kafka kafka-cluster-kafka-0
   ```

3. **Conectividade**:
   ```bash
   # Testar dentro do cluster
   kubectl exec -n kafka kafka-cluster-kafka-0 -- /opt/kafka/bin/kafka-broker-api-versions.sh --bootstrap-server localhost:9092
   ```

## 🎯 Próximos Experimentos

1. **Configurar autenticação SCRAM-SHA-512**
2. **Implementar autorização via ACLs**
3. **Configurar criptografia TLS**
4. **Setup de cluster multi-AZ**
5. **Backup e disaster recovery**
6. **Integração com Prometheus/Grafana**

## 📚 Referências

- [Strimzi Quickstart](https://strimzi.io/quickstarts/)
- [Red Hat AMQ Streams Documentation](https://access.redhat.com/documentation/en-us/red_hat_amq_streams/)
- [Kafka Custom Resources](https://strimzi.io/docs/operators/latest/using.html)
