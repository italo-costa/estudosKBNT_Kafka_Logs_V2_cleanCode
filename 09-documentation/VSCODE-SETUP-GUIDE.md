# 🎯 **VS Code Setup Guide - KBNT Virtual Stock System**

## ✅ **Todas as Soluções São 100% Viáveis no VS Code**

### **🚀 MÉTODO RECOMENDADO: Docker + VS Code**

#### **Passo 1: Verificar Extensões**
O projeto já tem `.vscode/extensions.json` configurado. Ao abrir no VS Code, você receberá automaticamente:
- ✅ Java Extension Pack
- ✅ Spring Boot Extensions  
- ✅ Docker Extension
- ✅ Kubernetes Tools
- ✅ Maven Support
- ✅ PowerShell Integration

#### **Passo 2: Setup Automatizado**
Execute o script que criamos:

```powershell
# No terminal integrado do VS Code (Ctrl + `)
cd c:\workspace\estudosKBNT_Kafka_Logs
.\setup-vscode-environment.ps1
```

#### **Passo 3: Desenvolvimento no VS Code**

**🔨 Build & Debug:**
- Pressione `Ctrl+Shift+P` → "Java: Build Workspace"
- Use `F5` para debug individual de serviços
- `Ctrl+Shift+D` para acessar configurações de debug

**🐳 Docker Integration:**
- `Ctrl+Shift+P` → "Docker: Compose Up"
- View → Command Palette → "Docker: Show Logs"
- Sidebar Docker para gerenciar containers

**🧪 Testing Integration:**
- `Ctrl+Shift+P` → "Tasks: Run Task" → "Run Virtual Stock Test"
- Terminal integrado executa testes automaticamente

---

## 🎨 **Funcionalidades VS Code Exclusivas**

### **1. IntelliSense Java Completo**
```java
// Autocomplete, refactoring, navigation
@Value("${app.kafka.topics.application-logs:kbnt-application-logs}")
private String applicationLogsTopic; // <- Ctrl+Click para navegar
```

### **2. Debug Integrado**
- Breakpoints visuais no código
- Variables inspection em tempo real
- Call stack navigation
- Hot reload com Spring Boot DevTools

### **3. Docker Dashboard**
- Visualizar containers em execução
- Logs em tempo real
- Port mapping visual
- Health status indicators

### **4. Kubernetes Integration** 
- YAML IntelliSense
- Apply manifests com `Ctrl+Shift+P`
- Pod logs directly no VS Code
- Port forwarding visual

### **5. Testing Dashboard**
- Executar testes com UI
- Coverage reports integrados
- Test explorer sidebar
- Debugging de testes

---

## 📋 **Workflow Completo no VS Code**

### **Cenário: Executar Teste de 150 Mensagens**

1. **Abrir Projeto:**
   ```
   File → Open Folder → c:\workspace\estudosKBNT_Kafka_Logs
   ```

2. **Install Extensions (Popup automático)**
   - Clique "Install All" quando aparecer

3. **Setup Environment:**
   ```
   Ctrl+` (Terminal) → .\setup-vscode-environment.ps1
   ```

4. **Build Services:**
   ```
   Ctrl+Shift+P → Tasks: Run Task → Build All Services
   ```

5. **Debug Services:**
   ```
   Ctrl+Shift+D → Start All Services (F5)
   ```

6. **Run Test:**
   ```
   Ctrl+Shift+P → Tasks: Run Task → Run Virtual Stock Test (150 messages)
   ```

7. **Monitor Results:**
   - Terminal integrado mostra progresso
   - Docker extension mostra container logs
   - Problems panel mostra erros

---

## 🎯 **Resposta Direta: SIM, Todas Viáveis!**

### **✅ Vantagens de cada método no VS Code:**

#### **Docker + VS Code:**
- 🟢 **Mais fácil:** Um clique para iniciar tudo
- 🟢 **Isolamento:** Não afeta sistema local  
- 🟢 **Reproducível:** Funciona igual em qualquer máquina
- 🟢 **VS Code Integrado:** Docker extension oficial

#### **Java Local + VS Code:**
- 🟢 **Performance:** Execução nativa mais rápida
- 🟢 **Debug direto:** Hot reload instantâneo
- 🟢 **Controle total:** Configurações personalizadas
- 🟢 **Java Extension Pack:** IntelliSense completo

#### **Kubernetes + VS Code:**
- 🟢 **Enterprise-ready:** Ambiente similar produção
- 🟢 **Scalable:** Múltiplas réplicas de serviços  
- 🟢 **Monitoring:** Dashboards integrados
- 🟢 **K8s Extension:** Kubectl integrado

---

## 🚀 **Qual Escolher?**

**Para o teste de 150 mensagens Virtual Stock:**

### **🏆 RECOMENDAÇÃO: Docker + VS Code**

**Por que?**
- ✅ Setup automático em 5 minutos
- ✅ Ambiente completo (Kafka + DBs + UI)
- ✅ Debug visual integrado
- ✅ Zero configuração adicional
- ✅ Funciona imediatamente

**Comando único no VS Code:**
```powershell
# Terminal integrado (Ctrl+`)
.\setup-vscode-environment.ps1 && code .
```

Depois é só pressionar `F5` e executar os testes! 🎉

---

**Quer que eu execute o setup automatizado agora?** 😊
