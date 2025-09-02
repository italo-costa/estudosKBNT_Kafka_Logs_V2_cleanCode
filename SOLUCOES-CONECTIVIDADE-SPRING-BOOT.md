# GUIA: Como Deixar Aplicação Spring Boot Acessível no Windows

## 🎯 PROBLEMA IDENTIFICADO
A aplicação Spring Boot inicia corretamente e mostra que o Tomcat está rodando na porta 8080, mas não consegue receber conexões HTTP externas.

## 🔧 SOLUÇÕES IMPLEMENTADAS

### 1. Configuração de Rede no Spring Boot

#### application.properties
```properties
# Bind em todas as interfaces de rede
server.address=0.0.0.0
server.port=8080

# Configurações de Tomcat otimizadas
server.tomcat.max-threads=200
server.tomcat.connection-timeout=20000

# Logging para debugging
logging.level.org.springframework.web=DEBUG
logging.level.org.springframework.boot.web.embedded.tomcat=INFO
```

#### Parâmetros JVM para Conectividade
```bash
java -Dserver.address=0.0.0.0 \
     -Dserver.port=8080 \
     -Djava.net.preferIPv4Stack=true \
     -Dspring.profiles.active=dev \
     -jar aplicacao.jar
```

### 2. Configuração CORS (Cross-Origin Resource Sharing)

```java
@Bean
public FilterRegistrationBean<CorsFilter> corsFilter() {
    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    CorsConfiguration config = new CorsConfiguration();
    config.setAllowCredentials(true);
    config.addAllowedOriginPattern("*");
    config.addAllowedHeader("*");
    config.addAllowedMethod("*");
    source.registerCorsConfiguration("/**", config);
    FilterRegistrationBean<CorsFilter> bean = new FilterRegistrationBean<>(new CorsFilter(source));
    bean.setOrder(0);
    return bean;
}
```

### 3. Configuração do Windows Firewall

#### Via PowerShell (Executar como Administrador):
```powershell
# Criar regra para aplicação Java na porta 8080
netsh advfirewall firewall add rule name="Java-Spring-Boot-8080" dir=in action=allow protocol=TCP localport=8080

# Verificar regra criada
netsh advfirewall firewall show rule name="Java-Spring-Boot-8080"

# Alternativo: Permitir Java.exe
netsh advfirewall firewall add rule name="Java Application" dir=in action=allow program="C:\Program Files\Eclipse Adoptium\jdk-17.0.16.8-hotspot\bin\java.exe"
```

#### Via Interface Gráfica:
1. Windows Security → Firewall & network protection
2. Advanced settings → Inbound Rules → New Rule
3. Port → TCP → Specific local ports → 8080
4. Allow the connection → Domain/Private/Public → Name: "Spring Boot 8080"

### 4. Script PowerShell de Inicialização

```powershell
# start-spring-app.ps1
param([int]$Port = 8080)

# Configurar ambiente
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.16.8-hotspot"
$env:PATH = "C:\maven\apache-maven-3.9.4\bin;$env:JAVA_HOME\bin;$env:PATH"

# Liberar porta se estiver em uso
$portCheck = netstat -ano | findstr ":$Port"
if ($portCheck) {
    # Finalizar processos usando a porta
    $processes = netstat -ano | findstr ":$Port" | ForEach-Object { 
        if ($_ -match '\s+(\d+)$') { $matches[1] } 
    } | Select-Object -Unique
    
    foreach ($pid in $processes) {
        taskkill /PID $pid /F 2>$null
        Start-Sleep 2
    }
}

# Iniciar aplicação com configurações otimizadas
& "$env:JAVA_HOME\bin\java.exe" `
    "-Dserver.address=0.0.0.0" `
    "-Dserver.port=$Port" `
    "-Djava.net.preferIPv4Stack=true" `
    "-Dspring.profiles.active=dev" `
    -jar target\simple-stock-api-1.0.0.jar
```

### 5. Verificações de Diagnóstico

#### Verificar se a porta está ocupada:
```powershell
netstat -ano | findstr ":8080"
```

#### Testar conectividade local:
```powershell
# Teste simples
curl http://localhost:8080/actuator/health

# Teste com PowerShell
Invoke-RestMethod -Uri "http://localhost:8080/actuator/health" -TimeoutSec 10
```

#### Verificar processos Java:
```powershell
tasklist /FI "IMAGENAME eq java.exe"
Get-Process | Where-Object {$_.ProcessName -eq "java"}
```

## 🚨 PROBLEMAS COMUNS E SOLUÇÕES

### 1. "Impossível conectar-se ao servidor remoto"

**Causa**: Firewall bloqueando conexões ou aplicação não binding em 0.0.0.0

**Solução**:
- Configurar Windows Firewall (regras acima)
- Usar `-Dserver.address=0.0.0.0` nos parâmetros JVM
- Executar como Administrador se necessário

### 2. Porta aparece ocupada mas aplicação não responde

**Causa**: Processo anterior não foi finalizado corretamente

**Solução**:
```powershell
# Encontrar PID usando a porta
netstat -ano | findstr ":8080"

# Finalizar processo
taskkill /PID [PID_NUMBER] /F
```

### 3. Aplicação inicia mas netstat não mostra a porta

**Causa**: Binding apenas em localhost (127.0.0.1) em vez de todas as interfaces

**Solução**:
- Configurar `server.address=0.0.0.0` no application.properties
- Ou usar parâmetro JVM `-Dserver.address=0.0.0.0`

### 4. Timeout em requests HTTP

**Causa**: Configurações de proxy ou antivírus interferindo

**Solução**:
- Desabilitar proxy temporariamente
- Adicionar exceção no antivírus
- Testar com ferramenta alternativa (Postman, wget)

### 5. CORS errors em browsers

**Causa**: Política de Same-Origin do browser

**Solução**:
- Implementar configuração CORS (código acima)
- Usar `@CrossOrigin` nos controllers
- Configurar headers apropriados

## 📝 CHECKLIST DE TROUBLESHOOTING

- [ ] ✅ Aplicação compila sem erros
- [ ] ✅ JAR é gerado corretamente (>10MB)
- [ ] ✅ Variáveis JAVA_HOME e PATH configuradas
- [ ] ✅ Logs mostram "Tomcat started on port(s): 8080"
- [ ] ⚠️ Porta 8080 aparece em `netstat -ano`
- [ ] ⚠️ Firewall permite conexões na porta 8080
- [ ] ⚠️ Aplicação responde a `curl localhost:8080/actuator/health`
- [ ] ⚠️ Aplicação aceita conexões externas

## 🎯 STATUS ATUAL

### ✅ Funcionando:
- Compilação Maven
- Geração de JAR
- Startup do Spring Boot
- Inicialização do Tomcat
- Logging detalhado

### ⚠️ Problemas Identificados:
- Binding de rede não funcional
- Porta não aparece em netstat
- Requests HTTP timeout
- Conectividade local falha

### 🔄 Próximos Passos:
1. **PRIORITÁRIO**: Configurar Windows Firewall como Administrador
2. Testar com porta alternativa (8081, 9090)
3. Verificar configurações de proxy do sistema
4. Testar com perfil de rede diferente
5. Considerar execução via Docker se problemas persistirem

## 💡 ALTERNATIVAS SE PROBLEMAS PERSISTIREM

### Opção 1: Porta Alternativa
```bash
java -Dserver.port=8081 -jar aplicacao.jar
```

### Opção 2: Profile de Teste
```bash
java -Dspring.profiles.active=test -Dserver.address=127.0.0.1 -jar aplicacao.jar
```

### Opção 3: Docker (Recomendado)
```dockerfile
FROM openjdk:17-jdk-slim
COPY target/simple-stock-api-1.0.0.jar app.jar
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
```

```bash
docker build -t virtual-stock .
docker run -p 8080:8080 virtual-stock
```

---

**Resumo**: A aplicação Spring Boot está funcionalmente correta, mas enfrenta problemas de conectividade de rede específicos do Windows. As soluções implementadas cobrem configuração de firewall, parâmetros JVM otimizados e configurações de rede. O próximo passo crítico é configurar o Windows Firewall como Administrador.
