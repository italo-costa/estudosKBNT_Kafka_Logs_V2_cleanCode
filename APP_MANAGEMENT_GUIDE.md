# Scripts de Gerenciamento - Virtual Stock Service

## 🚀 Scripts Disponíveis

### 1. **start-app.ps1** - Inicialização Rápida
```powershell
powershell -ExecutionPolicy Bypass -File start-app.ps1
```
- Verifica WSL2 e Docker
- Inicia containers se necessário
- Testa todos os endpoints
- Mostra status completo da aplicação

### 2. **restart-app.ps1** - Reinicialização
```powershell
powershell -ExecutionPolicy Bypass -File restart-app.ps1
```
- Para todos os containers
- Reinicia containers
- Testa aplicação após restart

### 3. **monitor-app.ps1** - Monitoramento Contínuo
```powershell
powershell -ExecutionPolicy Bypass -File monitor-app.ps1
```
- Monitora saúde da aplicação a cada 30 segundos
- Reinicia automaticamente em caso de falha
- Exibe logs em tempo real

### 4. **setup-port-forwarding.ps1** - Configuração para Postman
```powershell
# Execute como Administrador
powershell -ExecutionPolicy Bypass -File setup-port-forwarding.ps1
```
- Configura port forwarding para acesso do Windows
- Necessário para testes via Postman

## 🔧 Status da Aplicação

### Containers Ativos:
- **postgres-kbnt-stable**: PostgreSQL 15 (porta 5432)
- **virtual-stock-stable**: Spring Boot App (porta 8084)
- **Rede**: kbnt-stable-net
- **Restart Policy**: always (reinício automático)

### Endpoints Disponíveis:
- **Health Check**: http://localhost:8084/actuator/health
- **Página Inicial**: http://localhost:8084/
- **Ping**: http://localhost:8084/ping
- **API Health**: http://localhost:8084/api/v1/health
- **Stocks API**: http://localhost:8084/api/v1/virtual-stock/stocks

## 📋 Guia de Uso Rápido

### Para Iniciar pela Primeira Vez:
1. Execute `start-app.ps1`
2. Aguarde verificação completa
3. Use os endpoints listados

### Para Testes via Postman:
1. Execute `setup-port-forwarding.ps1` como Administrador
2. Use `start-app.ps1` para verificar funcionamento
3. Teste endpoints no Postman

### Para Monitoramento:
1. Execute `monitor-app.ps1` em janela separada
2. Deixe rodando para monitoramento contínuo

### Em Caso de Problemas:
1. Use `restart-app.ps1` para reiniciar
2. Verifique logs: `wsl -e bash -c "docker logs virtual-stock-stable"`
3. Se necessário, use `monitor-app.ps1` para diagnóstico

## 🛠️ Comandos Úteis WSL2

```bash
# Ver containers rodando
wsl -e bash -c "docker ps"

# Ver logs da aplicação
wsl -e bash -c "docker logs virtual-stock-stable"

# Ver logs do PostgreSQL
wsl -e bash -c "docker logs postgres-kbnt-stable"

# Testar endpoint manualmente
wsl -e bash -c "curl http://localhost:8084/actuator/health"
```

## ✅ Aplicação Funcionando

A aplicação Virtual Stock Service está configurada e rodando com:
- ✅ Reinício automático (restart=always)
- ✅ Persistência de dados PostgreSQL
- ✅ Health checks configurados
- ✅ Rede Docker customizada
- ✅ Scripts de monitoramento
- ✅ Configuração para Windows/Postman
