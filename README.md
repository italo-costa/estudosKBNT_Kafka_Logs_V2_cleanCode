# Estudos KBNT - Kafka & Kubernetes para Logs

Este projeto contém estudos e exemplos práticos de como usar Apache Kafka e Kubernetes para processamento e gerenciamento de logs.

> 📚 **Projeto de Estudos**: Este é um repositório privado dedicado ao aprendizado e experimentação com tecnologias de logs distribuídos.

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
- Configuração do Red Hat AMQ Streams (Kafka) em Kubernetes
- Coleta e processamento de logs usando AMQ Streams
- Implementação de produtores e consumidores de logs
- Monitoramento e observabilidade
- Padrões de arquitetura para logs distribuídos

## 🚀 Tecnologias

- **Red Hat AMQ Streams** - Plataforma Kafka enterprise (versão community)
- **Apache Kafka** - Base do AMQ Streams
- **Kubernetes** - Orquestração de containers
- **Strimzi Operator** - Operador Kafka para Kubernetes
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

> ⚠️ **Nota**: Este é um repositório privado. Certifique-se de ter as permissões adequadas para acessá-lo.

### 2. Configure o ambiente Kubernetes
```bash
# Inicie o minikube (se estiver usando)
minikube start

# Ou configure seu cluster Kubernetes
kubectl config current-context
```

### 3. Deploy do AMQ Streams no Kubernetes
```bash
# Instalar operador AMQ Streams
kubectl create namespace kafka
kubectl apply -f https://strimzi.io/install/latest?namespace=kafka -n kafka

# Deploy usando Custom Resources do Strimzi
kubectl apply -f kubernetes/kafka/kafka-cluster.yaml
kubectl apply -f kubernetes/kafka/kafka-topics.yaml
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

Como este é um projeto de estudos privado:

1. Use branches para diferentes experimentos (`git checkout -b experimento/nova-funcionalidade`)
2. Faça commits descritivos (`git commit -m 'Adiciona: novo padrão de processamento de logs'`)
3. Documente suas descobertas na pasta `docs/`
4. Crie issues para rastrear objetivos de aprendizado

## 📝 Registro de Aprendizado

Mantenha um registro dos seus estudos:
- Crie arquivos `docs/experimento-YYYY-MM-DD.md` para documentar descobertas
- Use issues para rastrear objetivos e progresso
- Marque commits com tags para marcos importantes

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 📞 Contato

Projeto criado para fins educacionais e estudos de Kafka e Kubernetes.

---

⭐ Se este projeto te ajudou, deixe uma estrela no repositório!
