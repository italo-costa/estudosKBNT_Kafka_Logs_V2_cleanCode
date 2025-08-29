# Configuração do Kafka

Este diretório contém as configurações personalizadas do Apache Kafka para o projeto de estudos.

## Estrutura

- `server.properties` - Configuração principal do broker Kafka
- `log4j.properties` - Configuração de logs do Kafka
- `consumer.properties` - Configurações padrão para consumidores
- `producer.properties` - Configurações padrão para produtores

## Configurações Importantes

### Performance
- `num.network.threads=8` - Threads para requisições de rede
- `num.io.threads=8` - Threads para I/O
- `socket.send.buffer.bytes=102400` - Buffer de envio
- `socket.receive.buffer.bytes=102400` - Buffer de recebimento

### Retenção de Logs
- `log.retention.hours=168` - Retenção por 7 dias
- `log.segment.bytes=1073741824` - Tamanho do segmento (1GB)
- `log.retention.check.interval.ms=300000` - Verificação a cada 5min

### Replicação
- `default.replication.factor=3` - Fator de replicação padrão
- `min.insync.replicas=2` - Mínimo de réplicas sincronizadas
