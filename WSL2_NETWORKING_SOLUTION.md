# 🔧 SOLUÇÃO para Error: connect ECONNREFUSED 127.0.0.1:8084

## 🎯 DIAGNÓSTICO DO PROBLEMA

**Erro**: `Error: connect ECONNREFUSED 127.0.0.1:8084` no Postman Windows

**Causa Raiz**: WSL2 usa uma rede virtualizada separada. As portas dos containers Docker no WSL2 não são automaticamente acessíveis pelo Windows via `localhost`.

## ✅ STATUS DA APLICAÇÃO
- ✅ Virtual Stock Service está FUNCIONANDO perfeitamente
- ✅ PostgreSQL conectado e operacional  
- ✅ API respondendo dentro do WSL2
- ❌ Porta não acessível pelo Windows devido ao networking do WSL2

## 🛠️ SOLUÇÕES DISPONÍVEIS

### Solução 1: 🚀 **Port Forwarding Automático (RECOMENDADO)**

Execute como **Administrador** no PowerShell:
```powershell
.\configure-wsl2-port-forwarding.ps1
```

Este script irá:
- ✅ Detectar IP do WSL2 automaticamente
- ✅ Configurar port forwarding 8084
- ✅ Configurar firewall
- ✅ Testar conectividade

### Solução 2: 🎯 **Usar IP Direto do WSL2 (IMEDIATO)**

Use este IP no Postman em vez de localhost:
```
http://172.30.221.62:8084/api/v1/virtual-stock/stocks
```

### Solução 3: 🔧 **Port Forwarding Manual**

Execute como Administrador:
```cmd
netsh interface portproxy add v4tov4 listenport=8084 listenaddress=0.0.0.0 connectport=8084 connectaddress=172.30.221.62
```

Para remover depois:
```cmd
netsh interface portproxy delete v4tov4 listenport=8084 listenaddress=0.0.0.0
```

### Solução 4: 📱 **Usar WSL2 Terminal Curl (TESTE RÁPIDO)**

Para testes rápidos via terminal:
```bash
wsl curl http://localhost:8084/api/v1/virtual-stock/stocks
```

## 🧪 TESTE DE VERIFICAÇÃO

Após configurar o port forwarding, teste no Postman:

### 📋 Configuração Postman:
- **URL**: `http://localhost:8084/api/v1/virtual-stock/stocks`  
- **Method**: GET
- **Headers**: `Content-Type: application/json`

### 📊 Resposta Esperada:
```json
{
  "success": true,
  "data": [],
  "message": "Stocks retrieved successfully",
  "timestamp": "2025-09-09T11:46:48.994041117"
}
```

## 🔄 COMANDOS POSTMAN APÓS CORREÇÃO

### 1. ✅ GET - Listar Stocks
```
GET http://localhost:8084/api/v1/virtual-stock/stocks
```

### 2. ✅ POST - Criar Stock
```
POST http://localhost:8084/api/v1/virtual-stock/stocks
Content-Type: application/json

{
  "stockCode": "PROD001",
  "productName": "Produto Teste",
  "quantity": 100,
  "unitPrice": 29.90
}
```

### 3. ✅ GET - Buscar por ID  
```
GET http://localhost:8084/api/v1/virtual-stock/stocks/1
```

### 4. ✅ PUT - Atualizar Quantidade
```
PUT http://localhost:8084/api/v1/virtual-stock/stocks/1/quantity
Content-Type: application/json

{
  "quantity": 150
}
```

## 🚨 TROUBLESHOOTING

### Se ainda não funcionar:

1. **Verificar se aplicação está rodando**:
   ```bash
   wsl docker ps --filter name=virtual-stock-service
   ```

2. **Verificar IP do WSL2**:
   ```bash
   wsl hostname -I
   ```

3. **Testar dentro do WSL**:
   ```bash
   wsl curl http://localhost:8084/api/v1/virtual-stock/stocks
   ```

4. **Verificar port proxy**:
   ```cmd
   netsh interface portproxy show all
   ```

5. **Reiniciar aplicação se necessário**:
   ```bash
   wsl docker compose -f docker-compose.complete.yml restart virtual-stock-service
   ```

## 💡 EXPLICAÇÃO TÉCNICA

O WSL2 funciona como uma máquina virtual leve com sua própria rede. Por padrão:
- ✅ WSL2 pode acessar Windows (host)
- ❌ Windows não pode acessar WSL2 diretamente
- 🔧 Solução: Port forwarding ou IP direto

## 🎉 RESULTADO FINAL

Após aplicar qualquer solução acima, você terá:
- ✅ Postman funcionando com `http://localhost:8084`
- ✅ Todos os endpoints da API acessíveis
- ✅ CRUD completo operacional
- ✅ Ambiente pronto para desenvolvimento
