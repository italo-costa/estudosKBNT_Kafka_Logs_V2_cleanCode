# Estudos KBNT - Kafka & Kubernetes para Logs

Este projeto contém estudos e exemplos práticos de como usar Apache Kafka e Kubernetes para processamento e gerenciamento de logs.

## 📋 Índice

- [Sobre o Projeto](#sobre-o-projeto)
- [Tecnologias](#tecnologias)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Pré-requisitos](#pré-requisitos)
- [Como Executar](#como-executar)
- [Exemplos](#exemplos)
- [Documentação](#documentação)

## 🎯 Sobre o Projeto

Este repositório foi criado para estudar e demonstrar:
- Configuração do Apache Kafka em Kubernetes
- Coleta e processamento de logs usando Kafka
- Implementação de produtores e consumidores de logs
- Monitoramento e observabilidade
- Padrões de arquitetura para logs distribuídos

## 🚀 Tecnologias

- **Apache Kafka** - Plataforma de streaming distribuída
- **Kubernetes** - Orquestração de containers
- **Docker** - Containerização
- **Python** - Aplicações de exemplo
- **Java** - Aplicações Kafka nativas
- **Helm** - Gerenciamento de pacotes Kubernetes
- **Prometheus & Grafana** - Monitoramento
- **ELK Stack** - Elasticsearch, Logstash, Kibana

## 📁 Estrutura do Projeto

```
estudosKBNT_Kafka_Logs/
├── kafka/                     # Configurações do Kafka
│   ├── configs/              # Configurações do broker
│   ├── topics/               # Definições de tópicos
│   └── schemas/              # Schemas Avro/JSON
├── kubernetes/               # Manifestos Kubernetes
│   ├── kafka/               # Deployment do Kafka
│   ├── zookeeper/           # Deployment do Zookeeper
│   ├── monitoring/          # Prometheus, Grafana
│   └── elk/                 # ElasticSearch, Logstash, Kibana
├── producers/               # Aplicações produtoras
│   ├── python/             # Produtores em Python
│   ├── java/               # Produtores em Java
│   └── logs-generator/     # Gerador de logs sintéticos
├── consumers/              # Aplicações consumidoras
│   ├── python/            # Consumidores em Python
│   ├── java/              # Consumidores em Java
│   └── processors/        # Processadores de logs
├── docker/                # Dockerfiles e compose
├── helm-charts/           # Charts Helm personalizados
├── scripts/               # Scripts de automação
├── docs/                  # Documentação detalhada
└── examples/              # Exemplos práticos
```

## 🔧 Pré-requisitos

- Docker Desktop
- Kubernetes (minikube, kind, ou cluster remoto)
- kubectl
- Helm 3.x
- Python 3.8+
- Java 11+
- Git

## 🏃‍♂️ Como Executar

### 1. Clone o repositório
```bash
git clone https://github.com/seu-usuario/estudosKBNT_Kafka_Logs.git
cd estudosKBNT_Kafka_Logs
```

### 2. Configure o ambiente Kubernetes
```bash
# Inicie o minikube (se estiver usando)
minikube start

# Ou configure seu cluster Kubernetes
kubectl config current-context
```

### 3. Deploy do Kafka no Kubernetes
```bash
# Deploy usando Helm
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install kafka bitnami/kafka -f kubernetes/kafka/values.yaml
```

### 4. Execute os exemplos
```bash
# Produtor de logs
python producers/python/log-producer.py

# Consumidor de logs
python consumers/python/log-consumer.py
```

## 📚 Exemplos

- [Produtor de Logs Simples](examples/simple-log-producer/)
- [Consumidor com Processamento](examples/log-processor/)
- [Pipeline Completo de Logs](examples/complete-pipeline/)
- [Monitoramento com Grafana](examples/monitoring/)

## 📖 Documentação

- [Configuração do Kafka](docs/kafka-setup.md)
- [Deploy no Kubernetes](docs/kubernetes-deployment.md)
- [Padrões de Logs](docs/logging-patterns.md)
- [Monitoramento](docs/monitoring.md)
- [Troubleshooting](docs/troubleshooting.md)

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 📞 Contato

Projeto criado para fins educacionais e estudos de Kafka e Kubernetes.

---

⭐ Se este projeto te ajudou, deixe uma estrela no repositório!
