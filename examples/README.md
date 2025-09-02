# Exemplo Simples - Produtor e Consumidor de Logs

Este exemplo demonstra o uso básico do sistema de logs com Kafka.

## 🎯 Objetivo

Mostrar como:
1. Iniciar o ambiente Kafka
2. Produzir logs sintéticos
3. Consumir e processar logs
4. Monitorar o fluxo de dados

## 🚀 Como Executar

### 1. Usando Docker Compose (Mais Simples)

```powershell
# Navegar para o diretório docker
cd docker

# Iniciar todos os serviços
docker-compose up -d

# Verificar se os serviços estão rodando
docker-compose ps
```

### 2. Usando Kubernetes

```powershell
# Executar script de setup
.\scripts\setup.ps1
```

### 3. Testar o Sistema

```powershell
# Terminal 1: Iniciar o consumidor
python consumers/python/log-consumer.py

# Terminal 2: Gerar logs de teste
python producers/python/log-producer.py --count 20 --interval 0.5
```

## 📊 O que Você Vai Ver

### Produtor
```
2025-08-29 10:30:01 - INFO - Starting log production to topic 'application-logs'
2025-08-29 10:30:01 - INFO - Produced log #1: user-service - INFO
2025-08-29 10:30:02 - INFO - Produced log #2: payment-service - INFO
2025-08-29 10:30:03 - INFO - Produced log #3: user-service - ERROR
```

### Consumidor
```
2025-08-29 10:30:01 - INFO - [user-service] [INFO] User user_42 logged in successfully
2025-08-29 10:30:02 - INFO - 💰 Payment processed: $156.78 (TX: tx-789456)
2025-08-29 10:30:03 - ERROR - 🚨 CRITICAL ERROR in user-service: Database connection timeout
```

## 🔍 Interfaces Web

- **Kafka UI**: http://localhost:8080 (ver tópicos, mensagens, consumers)
- **Kibana**: http://localhost:5601 (se usando ELK stack)

## 📈 Próximos Passos

1. Explore diferentes tipos de logs gerados
2. Modifique os filtros no consumidor
3. Adicione novos serviços ao produtor
4. Experimente com particionamento por chave
