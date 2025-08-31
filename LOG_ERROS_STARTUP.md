# 🚨 LOG DE ERROS DE EXECUÇÃO - TENTATIVA DE STARTUP
*Registro### **Solução Necessária**: Separar Dockerfile do script PowerShell

---

## 🔴 **ERRO #2: SCRIPT DE STARTUP SIMPLES**

### **Comando Executado:**
```powershell
.\scripts\simple-startup.ps1
```

### **Pergunta/Contexto:**
"tente levantar toda a aplicação - tentativa com script simples após falha do script principal"

### **Erro Completo:**
```powershell
Building Virtual Stock Service...
   Virtual Stock Service build: ERROR - O termo 'mvn' não é reconhecido como nome de cmdlet, função, arquivo de script ou programa operável. Verifique a grafia do nome ou, se um caminho tiver sido incluído, veja se o caminho está correto e tente novamente.

Building ACL Virtual Stock Service...
   ACL Virtual Stock Service build: ERROR - O termo 'mvn' não é reconhecido como nome de cmdlet, função, arquivo de script ou programa operável. Verifique a grafia do nome ou, se um caminho tiver sido incluído, veja se o caminho está correto e tente novamente.

ENVIRONMENT STATUS:
==================
Virtual Stock Service (Port 8080): NOT RUNNING
ACL Virtual Stock Service (Port 8081): NOT RUNNING

ENVIRONMENT NOT FULLY READY
Please check the application logs for errors
```

### **Análise do Erro:**
- **Causa**: Maven não está instalado/disponível no PATH
- **Comportamento**: Script detecta serviços como "already running" mas não consegue compilar
- **Resultado**: Após 120s de espera, confirma que serviços NOT RUNNING
- **Tipo**: Dependency missing - Maven ausente

---

## 🔴 **ERRO #3: COMPILAÇÃO MAVEN - LOMBOK NÃO FUNCIONAL**

### **Comando Executado:**
```powershell
mvn clean compile
```

### **Pergunta/Contexto:**
"tente levantar toda a aplicação - tentativa de compilação após instalar Java e Maven"

### **Erro Principal:**
```java
BUILD FAILURE - 100 errors
Compilation failure: cannot find symbol
symbol:   method getUnitPrice()
symbol:   method getStatus()
symbol:   method builder()
location: variable stock of type Stock

[ERROR] class CreateStockRequest is public, should be declared in a file named CreateStockRequest.java
[ERROR] class StockResponse is public, should be declared in a file named StockResponse.java
```

### **Análise do Erro:**
- **Causa Raiz**: Lombok annotations não estão sendo processadas
- **Impacto**: Getters/Setters/Builders não são gerados em tempo de compilação  
- **Classes Afetadas**: Stock.java, StockUpdatedEvent.java, RestModels.java
- **Tipo**: Annotation Processing failure - Lombok plugin issue
- **Sintomas**:
  - `cannot find symbol: method getStockId()`
  - `cannot find symbol: method builder()`
  - `cannot find symbol: method getCorrelationId()`

### **Problemas Identificados:**
1. **Lombok não processa @Getter/@Setter/@Builder**
2. **Classes públicas em arquivos únicos** (RestModels.java)
3. **Annotation processing desabilitado**

---

## 📊 **RESUMO DOS ERROS POR CATEGORIA**

### **1. 🚨 ERROS CRÍTICOS DE INFRAESTRUTURA**
- ❌ Script PowerShell com sintaxe Docker
- ❌ Maven não estava no PATH  
- ❌ Java não estava no PATH

### **2. 🔧 ERROS DE BUILD/COMPILAÇÃO**
- ❌ Lombok annotation processing falhou
- ❌ 100 erros de compilação Java
- ❌ Classes com estrutura inadequada

### **3. 🏗️ ERROS ARQUITETURAIS**
- ❌ JPA Repository Adapter ausente
- ❌ Dependency injection incompleta
- ❌ Configuration classes ausentes

---

## 🎯 **DIAGNÓSTICO FINAL**

### **Status Atual**: 🔴 SISTEMA INOPERANTE
- **Scripts**: FALHAM (sintaxe incorreta)
- **Build**: FALHA (Lombok não funciona)  
- **Runtime**: IMPOSSÍVEL (não compila)
- **Tests**: BLOQUEADOS (dependem do build)

### **Bloqueadores Principais**:
1. **Lombok Configuration Issue**: Critical
2. **PowerShell Script Syntax Error**: Critical  
3. **JPA Adapter Missing**: High
4. **Project Structure Issues**: Medium

---talhado das tentativas de inicialização do sistema e erros encontrados*

---

## 📊 **RESUMO DA SESSÃO DE STARTUP**
- **Data/Hora**: 2025-08-30 (Análise atual)
- **Objetivo**: Levantar toda a aplicação e documentar erros
- **Status**: ❌ FALHADO - Erros críticos de infraestrutura

---

## 🔴 **ERRO #1: SCRIPT PRINCIPAL DE INICIALIZAÇÃO**

### **Comando Executado:**
```powershell
.\scripts\start-complete-environment.ps1
```

### **Pergunta/Contexto:**
"tente levantar toda a aplicação por ele para os erros que derem deixe-os salvo em algum lugar juntamente com a pergunta feita"

### **Erro Completo:**
```powershell
No C:\workspace\estudosKBNT_Kafka_Logs\scripts\start-complete-environment.ps1:512  
caractere:1
+ FROM openjdk:17-jre-slim
+ ~~~~
A palavra-chave 'from' não tem suporte nesta versão da linguagem.

No C:\workspace\estudosKBNT_Kafka_Logs\scripts\start-complete-environment.ps1:525  
caractere:55
+     CMD curl -f http://localhost:8080/actuator/health || exit 1
+                                                       ~~
O token '||' não é um separador de instruções válido nesta versão.

No C:\workspace\estudosKBNT_Kafka_Logs\scripts\start-complete-environment.ps1:681  
caractere:31
+             # For Windows, we'll need to run the script using Git Bas ...     
+                               ~~
Token 'll' inesperado na expressão ou instrução.

No C:\workspace\estudosKBNT_Kafka_Logs\scripts\start-complete-environment.ps1:692  
caractere:5
+     }
+     ~
Token '}' inesperado na expressão ou instrução.

No C:\workspace\estudosKBNT_Kafka_Logs\scripts\start-complete-environment.ps1:702 
caractere:1
+ }
+ ~
Token '}' inesperado na expressão ou instrução.
    + CategoryInfo          : ParserError: (:) [], ParseException
    + FullyQualifiedErrorId : ReservedKeywordNotAllowed

Command exited with code 1
```

### **Análise do Erro:**
- **Causa**: Sintaxe Docker (FROM, CMD, ||) misturada no script PowerShell
- **Localização**: Linhas 512, 525, 681, 692, 702
- **Tipo**: ParseException crítico - impede execução
- **Solução Necessária**: Separar Dockerfile do script PowerShell

---
