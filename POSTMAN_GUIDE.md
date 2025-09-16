# 🎯 GUIA DEFINITIVO POSTMAN - VIRTUAL STOCK SERVICE

## ⚠️ PROBLEMA IDENTIFICADO:
O erro `connect ETIMEDOUT 172.30.221.62:8084` ocorre porque:
1. O Postman no Windows não consegue acessar diretamente o IP do WSL2
2. É necessário usar `localhost:8084` com port forwarding configurado

## ✅ SOLUÇÃO IMPLEMENTADA:

### 1. **Containers Configurados:**
- ✅ PostgreSQL: Porta 5432
- ✅ Virtual Stock Service: Porta 8084
- ✅ Restart automático ativado

### 2. **Port Forwarding Configurado:**
```
Windows 0.0.0.0:8084 → WSL2 172.30.221.62:8084
```

## 🚀 **ENDPOINTS PARA POSTMAN (USAR localhost):**

### **❌ NÃO USE:** `http://172.30.221.62:8084`
### **✅ USE:** `http://localhost:8084`

### **Endpoints Disponíveis:**

#### 1. **Health Check**
```
GET http://localhost:8084/actuator/health
```
**Resposta esperada:**
```json
{
  "status": "UP",
  "components": {
    "db": {"status": "UP"}
  }
}
```

#### 2. **Listar Stocks**
```
GET http://localhost:8084/api/v1/virtual-stock/stocks
```

#### 3. **Criar Stock**
```
POST http://localhost:8084/api/v1/virtual-stock/stocks
Content-Type: application/json

{
  "productCode": "PROD-001",
  "productName": "Produto Teste",
  "quantity": 100,
  "price": 29.99
}
```

#### 4. **Ping Test**
```
GET http://localhost:8084/ping
```

#### 5. **Home**
```
GET http://localhost:8084/
```

## 🔧 **VERIFICAR SE ESTÁ FUNCIONANDO:**

### **No PowerShell:**
```powershell
# Verificar aplicação
wsl -e bash -c "curl -s http://localhost:8084/actuator/health"

# Verificar port forwarding
netsh interface portproxy show v4tov4

# Reiniciar se necessário
powershell -ExecutionPolicy Bypass -File simple-fix.ps1
```

### **Teste Windows:**
```powershell
Invoke-WebRequest -Uri "http://localhost:8084/actuator/health" -UseBasicParsing
```

## 🛠️ **SE AINDA NÃO FUNCIONAR:**

1. **Execute como Administrador:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File simple-fix.ps1
   ```

2. **Aguarde aplicação inicializar (pode levar até 2 minutos)**

3. **Reinicie o Postman**

4. **Use APENAS localhost:8084, nunca o IP 172.30.221.62**

## 📋 **STATUS ATUAL:**
- ✅ Containers criados
- ✅ Port forwarding configurado  
- ⏳ Aplicação inicializando (aguarde)
- ⏳ Teste pendente

## 🎯 **PRÓXIMOS PASSOS:**
1. Aguarde 2 minutos para aplicação inicializar
2. Teste `http://localhost:8084/actuator/health` no Postman
3. Se funcionar, use todos os outros endpoints
4. Se não funcionar, execute `simple-fix.ps1` como Administrador

**Lembre-se: SEMPRE use `localhost:8084`, nunca `172.30.221.62:8084`!**