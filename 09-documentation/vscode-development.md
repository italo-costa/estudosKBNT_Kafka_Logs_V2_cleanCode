# Desenvolvimento Spring Boot no VS Code

Este guia mostra como configurar e desenvolver os microserviços Spring Boot no VS Code de forma eficiente.

## 🚀 Setup Inicial no VS Code

### 1. Extensões Necessárias

O arquivo `.vscode/extensions.json` já contém todas as extensões recomendadas. Quando abrir o workspace, o VS Code sugerirá instalar automaticamente:

- **Java Extension Pack** - Suporte completo para Java
- **Spring Boot Extension Pack** - Ferramentas Spring Boot
- **Spring Boot Dashboard** - Interface visual para gerenciar apps
- **Lombok Annotations Support** - Suporte ao Lombok

### 2. Configuração Automática

As configurações do workspace em `.vscode/settings.json` incluem:
- Formatação automática ao salvar
- Organização automática de imports
- Configurações específicas para Java e Spring
- Exclusão de arquivos desnecessários

## 🛠️ Desenvolvendo com VS Code

### Spring Boot Dashboard

Após instalar as extensões, você verá o **Spring Boot Dashboard** na barra lateral:

```
SPRING BOOT DASHBOARD
├── log-producer-service
├── log-consumer-service  
├── log-analytics-service
└── api-gateway
```

**Funcionalidades:**
- ▶️ **Run** - Executar aplicação
- 🐛 **Debug** - Debug com breakpoints
- ⏹️ **Stop** - Parar aplicação
- 🔧 **Configure** - Alterar configurações

### Executar Microserviços

#### Opção 1: Spring Boot Dashboard
1. Clique no ícone ▶️ ao lado do serviço
2. A aplicação iniciará com perfil `local`
3. Console aparecerá automaticamente

#### Opção 2: Run/Debug Configuration
1. `Ctrl+Shift+P` → "Debug: Select and Start Debugging"
2. Escolha a configuração (ex: "Log Producer Service")
3. Aplicação inicia em modo debug

#### Opção 3: Terminal Integrado
```bash
cd microservices/log-producer-service
mvn spring-boot:run -Dspring-boot.run.profiles=local
```

### Hot Reload (DevTools)

O Spring DevTools está configurado em todos os serviços:
- ✅ **Auto-restart** quando código Java muda
- ✅ **Live reload** para recursos estáticos
- ✅ **Property reload** para configurações

**Para ativar:**
1. Salve qualquer arquivo `.java`
2. Aplicação reinicia automaticamente
3. Não perde estado do debug

### Debug Avançado

#### Breakpoints
- Clique na margem esquerda para criar breakpoint
- **Conditional breakpoints**: Clique direito no breakpoint
- **Logpoints**: Breakpoint que só loga, não para

#### Debug Remoto
Para debug em container Docker:
```yaml
# docker-compose.yml
environment:
  - JAVA_OPTS=-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005
ports:
  - "5005:5005"
```

### Profiles de Desenvolvimento

#### Local (default para VS Code)
```yaml
# application-local.yml
spring:
  kafka:
    bootstrap-servers: localhost:9092
logging:
  level:
    com.kbnt: DEBUG
```

#### Docker
```yaml
# application-docker.yml  
spring:
  kafka:
    bootstrap-servers: kafka:29092
```

#### Test
```yaml
# application-test.yml
spring:
  kafka:
    bootstrap-servers: ${spring.embedded.kafka.brokers}
```

## 📋 Tasks Configuradas

Use `Ctrl+Shift+P` → "Tasks: Run Task":

- **Build All Microservices** - Build completo
- **Start AMQ Streams** - Port-forward do Kafka
- **Start Docker Environment** - Docker Compose
- **Run Python Log Producer** - Teste rápido
- **Setup Environment** - Script completo

## 🔧 Configurações por Serviço

### log-producer-service (Port 8081)
```java
// Endpoints principais
POST /api/v1/logs              // Enviar log
POST /api/v1/logs/topic/{topic} // Enviar para tópico específico
POST /api/v1/logs/batch        // Lote de logs
GET  /api/v1/logs/health       // Health check
```

**Teste rápido:**
```bash
curl -X POST http://localhost:8081/api/v1/logs \
  -H "Content-Type: application/json" \
  -d '{"service":"test","level":"INFO","message":"Hello from VS Code"}'
```

### log-consumer-service (Port 8082)
- Consome logs automaticamente
- Processa e salva no banco
- Expõe métricas de consumo

### log-analytics-service (Port 8083)  
- APIs para consultas
- Cache com Redis
- Dashboards de estatísticas

### api-gateway (Port 8080)
- Ponto único de entrada
- Rate limiting
- Logging de requisições

## 🧪 Testes no VS Code

### Unit Tests
```java
@SpringBootTest
class LogProducerServiceTest {
    
    @Test
    void shouldSendLogSuccessfully() {
        // Teste aparece na Test Explorer
    }
}
```

### Integration Tests
```java
@SpringBootTest
@TestcontainersEnabled
class LogProducerIntegrationTest {
    
    @Container
    static KafkaContainer kafka = new KafkaContainer(DockerImageName.parse("confluentinc/cp-kafka:latest"));
}
```

**Executar testes:**
- **Test Explorer**: Sidebar com árvore de testes
- **CodeLens**: Links "Run Test" acima dos métodos
- **Command Palette**: "Java: Run Tests"

## 📊 Monitoramento durante Desenvolvimento

### Actuator Endpoints

Cada serviço expõe:
- `/actuator/health` - Status da aplicação
- `/actuator/metrics` - Métricas detalhadas  
- `/actuator/prometheus` - Métricas para Prometheus
- `/actuator/info` - Informações da app

### Logs em Tempo Real

**Terminal integrado:**
```bash
# Seguir logs de um serviço
docker logs -f log-producer-service

# Logs do Kubernetes
kubectl logs -f deployment/log-producer-service -n kafka
```

**Extensão Kubernetes:**
- View → Command Palette → "Kubernetes: Show Logs"

## 🚨 Troubleshooting

### Problemas Comuns

#### 1. Extensões não funcionam
```bash
# Reload window
Ctrl+Shift+P → "Developer: Reload Window"

# Verificar JAVA_HOME
echo $env:JAVA_HOME  # PowerShell
echo $JAVA_HOME      # Bash
```

#### 2. Spring Boot Dashboard não aparece
- Verificar se há `pom.xml` nos diretórios
- Recarregar workspace: `Ctrl+Shift+P` → "Java: Reload Projects"

#### 3. Kafka não conecta
```bash
# Port-forward manual
kubectl port-forward -n kafka svc/kafka-cluster-kafka-bootstrap 9092:9092

# Verificar conectividade
telnet localhost 9092
```

#### 4. Build falha
```bash
# Limpar cache Maven
mvn clean

# Força download dependências  
mvn clean compile -U

# Verificar versão Java
java -version  # Deve ser 17+
```

### Debug Kafka Issues

#### Ver mensagens em tópicos:
```bash
# Executar dentro do VS Code terminal
kubectl exec -n kafka kafka-cluster-kafka-0 -- \
  /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic application-logs \
  --from-beginning
```

#### Verificar consumer groups:
```bash  
kubectl exec -n kafka kafka-cluster-kafka-0 -- \
  /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --list
```

## 🎯 Dicas de Produtividade

### Shortcuts Úteis
- `Ctrl+Shift+P` - Command Palette
- `Ctrl+` - Terminal integrado
- `F5` - Start debugging
- `Ctrl+F5` - Start without debugging
- `Shift+F5` - Stop debugging
- `Ctrl+Shift+F5` - Restart debugging

### Snippets Spring Boot
O VS Code criará automaticamente snippets para:
- `@RestController` classes
- `@Service` beans  
- `@Configuration` classes
- Test methods

### Live Templates
- `sout` → `System.out.println()`
- `psvm` → `public static void main()`
- `@test` → Método de teste completo

## 📚 Recursos Adicionais

- [VS Code Java Documentation](https://code.visualstudio.com/docs/languages/java)
- [Spring Boot in VS Code](https://code.visualstudio.com/docs/java/java-spring-boot)  
- [Debugging Spring Boot](https://code.visualstudio.com/docs/java/java-debugging)
- [Spring Boot Dashboard](https://marketplace.visualstudio.com/items?itemName=vscjava.vscode-spring-boot-dashboard)
