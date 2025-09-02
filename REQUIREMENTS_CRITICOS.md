# 🚨 REQUIREMENTS E CORREÇÕES CRÍTICAS
*Lista atualizada baseada nos erros reais encontrados durante tentativas de startup*

---

## 📊 **STATUS ATUAL DO SISTEMA**

### 🔴 **DIAGNOSIS**: SISTEMA COMPLETAMENTE INOPERANTE
- **Build Status**: ❌ FALHA CRÍTICA (100 compilation errors)
- **Runtime Status**: ❌ IMPOSSÍVEL (não compila)
- **Scripts Status**: ❌ PARSING ERRORS (sintaxe incorreta)
- **Tests Status**: ❌ BLOQUEADOS (dependem do build)

---

## 🎯 **PROBLEMAS CRÍTICOS IDENTIFICADOS**

### **1. 🔧 LOMBOK ANNOTATION PROCESSING FAILURE**
**Severidade**: 🔴 CRITICAL - Bloqueia toda compilação

#### **Sintomas Observados:**
```java
[ERROR] cannot find symbol
  symbol:   method getUnitPrice()
  symbol:   method getStatus() 
  symbol:   method builder()
  location: variable stock of type Stock
```

#### **Classes Afetadas:**
- `Stock.java` - Domain entity sem getters/setters
- `StockUpdatedEvent.java` - Domain event sem builders
- `RestModels.java` - DTOs sem getters/setters
- `KafkaStockEventPublisherAdapter.java` - Adapter sem acesso a métodos

#### **Causa Raiz:**
- Lombok annotation processor não está ativo
- Maven compiler plugin não configurado para Lombok
- IDE annotation processing desabilitado

#### **Solução Necessária:**
```xml
<!-- pom.xml - Maven Compiler Plugin -->
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-compiler-plugin</artifactId>
    <version>3.11.0</version>
    <configuration>
        <source>17</source>
        <target>17</target>
        <annotationProcessorPaths>
            <path>
                <groupId>org.projectlombok</groupId>
                <artifactId>lombok</artifactId>
                <version>1.18.30</version>
            </path>
        </annotationProcessorPaths>
    </configuration>
</plugin>
```

### **2. 🏗️ ESTRUTURA DE CLASSES INADEQUADA**
**Severidade**: 🟡 HIGH - Viola padrões Java

#### **Sintomas Observados:**
```java
[ERROR] class CreateStockRequest is public, should be declared in a file named CreateStockRequest.java
[ERROR] class UpdateQuantityRequest is public, should be declared in a file named UpdateQuantityRequest.java
[ERROR] class StockResponse is public, should be declared in a file named StockResponse.java
```

#### **Problema:**
- Múltiplas classes públicas no mesmo arquivo `RestModels.java`
- Viola convenção Java: 1 classe pública por arquivo

#### **Solução:**
Separar classes em arquivos individuais:
```
src/main/java/com/kbnt/virtualstock/infrastructure/adapter/input/rest/
├── CreateStockRequest.java
├── UpdateQuantityRequest.java  
├── UpdatePriceRequest.java
├── ReserveStockRequest.java
├── StockResponse.java
├── StockReservationResponse.java
└── ApiResponse.java
```

### **3. 📜 POWERSHELL SCRIPT SYNTAX ERRORS**
**Severidade**: 🔴 CRITICAL - Impede inicialização

#### **Script Afetado**: `start-complete-environment.ps1`
#### **Linhas com Erro**: 512, 525, 681, 692, 702

#### **Sintomas:**
```powershell
+ FROM openjdk:17-jre-slim
+ ~~~~
A palavra-chave 'from' não tem suporte nesta versão da linguagem.

+     CMD curl -f http://localhost:8080/actuator/health || exit 1
+                                                       ~~
O token '||' não é um separador de instruções válido nesta versão.
```

#### **Causa:** Dockerfile syntax misturada em script PowerShell

#### **Solução:** Criar `Dockerfile` separado
```dockerfile
# microservices/virtual-stock-service/Dockerfile
FROM openjdk:17-jre-slim
WORKDIR /app
COPY target/*.jar app.jar
RUN useradd -r -u 1001 appuser
USER appuser
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1
EXPOSE 8080
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"
ENTRYPOINT exec java $JAVA_OPTS -jar app.jar
```

### **4. 🗄️ JPA REPOSITORY ADAPTER AUSENTE**
**Severidade**: 🟡 HIGH - Aplicação não inicia

#### **Interface Definida mas Não Implementada:**
```java
public interface StockRepositoryPort {
    Stock save(Stock stock);
    Optional<Stock> findById(Stock.StockId stockId);
    // ... outros métodos
}
```

#### **Implementação Necessária:**
```java
@Repository
@RequiredArgsConstructor
public class JpaStockRepositoryAdapter implements StockRepositoryPort {
    
    private final SpringDataStockRepository springDataRepository;
    
    @Override
    public Stock save(Stock stock) {
        StockEntity entity = StockEntityMapper.toEntity(stock);
        StockEntity saved = springDataRepository.save(entity);
        return StockEntityMapper.toDomain(saved);
    }
    
    // ... implementar outros métodos
}
```

---

## 🛠️ **REQUIREMENTS ATUALIZADOS PARA CORREÇÃO**

### **📦 DEPENDENCIES MAVEN NECESSÁRIAS**

#### **Lombok com Annotation Processing**
```xml
<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <version>1.18.30</version>
    <scope>provided</scope>
</dependency>
```

#### **JPA e Database**
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <scope>runtime</scope>
</dependency>
<dependency>
    <groupId>com.h2database</groupId>
    <artifactId>h2</artifactId>
    <scope>runtime</scope>
</dependency>
```

#### **Build Plugins Necessários**
```xml
<build>
    <plugins>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
            <configuration>
                <excludes>
                    <exclude>
                        <groupId>org.projectlombok</groupId>
                        <artifactId>lombok</artifactId>
                    </exclude>
                </excludes>
            </configuration>
        </plugin>
        
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-compiler-plugin</artifactId>
            <version>3.11.0</version>
            <configuration>
                <source>17</source>
                <target>17</target>
                <annotationProcessorPaths>
                    <path>
                        <groupId>org.projectlombok</groupId>
                        <artifactId>lombok</artifactId>
                        <version>1.18.30</version>
                    </path>
                </annotationProcessorPaths>
            </configuration>
        </plugin>
    </plugins>
</build>
```

### **🔧 FERRAMENTAS DE AMBIENTE**

#### **Java Development Kit**
```bash
# DEVE estar configurado corretamente
JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.16.8-hotspot
PATH=%PATH%;%JAVA_HOME%\bin

# Verificar:
java --version  # deve mostrar OpenJDK 17
```

#### **Apache Maven**
```bash
# DEVE estar no PATH
MAVEN_HOME=C:\maven\apache-maven-3.9.4
PATH=%PATH%;%MAVEN_HOME%\bin

# Verificar:
mvn --version  # deve mostrar Maven 3.9.4
```

#### **IDE Configuration (VS Code/IntelliJ)**
- Lombok plugin instalado e habilitado
- Annotation processing habilitado
- Java 17 configurado como projeto JDK

---

## 🎯 **PLANO DE CORREÇÃO PRIORITÁRIO**

### **FASE 1: CORREÇÃO CRÍTICA (1-2 horas)**

#### **1.1 Corrigir Lombok Configuration**
```bash
# Verificar se annotation processing funciona
mvn clean compile -X | grep -i lombok

# Se falhar, adicionar plugin configuration no pom.xml
```

#### **1.2 Separar Classes RestModels**
```bash
# Criar arquivos individuais para cada classe pública
# Mover classes de RestModels.java para arquivos separados
```

#### **1.3 Corrigir Script PowerShell**
```bash
# Extrair Dockerfile do script PowerShell
# Criar Dockerfile separado em cada microservice
```

### **FASE 2: IMPLEMENTAÇÃO JPA (2-3 horas)**

#### **2.1 Criar JPA Entities**
```java
@Entity
@Table(name = "stocks")
public class StockEntity {
    @Id
    private String stockId;
    // ... outros campos
}
```

#### **2.2 Implementar Repository Adapter**
```java
@Repository
public class JpaStockRepositoryAdapter implements StockRepositoryPort {
    // ... implementação
}
```

### **FASE 3: VALIDAÇÃO (30 minutos)**

#### **3.1 Teste de Compilação**
```bash
mvn clean compile  # deve executar sem erros
```

#### **3.2 Teste de Startup**
```bash
mvn spring-boot:run -Dspring.profiles.active=local
```

---

## 🚨 **RECOMENDAÇÃO FINAL**

### **📁 PASTA DE TESTE SEPARADA**

Dado que encontramos **problemas estruturais críticos**, recomendo criarmos uma **pasta de teste** para:

1. **Implementar correções sem afetar código atual**
2. **Validar soluções antes de aplicar no projeto principal** 
3. **Criar versão funcional mínima para testes**

#### **Estrutura Proposta:**
```
c:\workspace\estudosKBNT_Kafka_Logs\
├── microservices\              # <- Código atual (com problemas)
├── test-environment\           # <- Nova pasta para correções
│   ├── virtual-stock-service-fixed\
│   ├── scripts-fixed\
│   └── logs\
└── LOG_ERROS_STARTUP.md        # <- Log de todos os erros
```

### **Próximos Passos Sugeridos:**

1. **Criar test-environment/** com código corrigido
2. **Aplicar todas as correções prioritárias**  
3. **Validar funcionamento básico**
4. **Documentar soluções que funcionaram**
5. **Aplicar correções no projeto principal**

**Se você concordar com essa abordagem, posso começar a criar a pasta de teste com as correções implementadas.**

---

*Requirements críticos gerados em: 2025-08-30*  
*Baseado em: Erros reais de compilação e execução*  
*Status: SISTEMA INOPERANTE - Correções críticas necessárias*
