# 🏗️ Workspace Clean Architecture - Índice de Navegação

## 📋 Estrutura Reorganizada

Este workspace foi completamente refatorado seguindo os princípios da **Clean Architecture**, organizando todos os arquivos em camadas bem definidas.

---

## 🎯 Navegação Rápida por Camadas

### 📊 [01-presentation-layer](./01-presentation-layer/)
**Documentação, Relatórios e Interfaces de Apresentação**
- 📁 **docs/**: Documentação técnica e arquitetural
  - README.md principal do projeto
  - Análises comparativas de escalabilidade
  - Correções de diagramas e relatórios
  - Estratégias de deployment
  - Relatórios de refatoração
- 📁 **reports/**: Relatórios de execução e performance
  - Relatórios de execução Docker
  - Relatórios de stress test
  - Relatórios de configuração de portas
- 📁 **dashboards/**: Visualizações e dashboards

### 🎯 [02-application-layer](./02-application-layer/)
**Casos de Uso e Orquestração de Serviços**
- 📁 **services/**: Serviços de aplicação
  - docker-compose-application.py
  - setup-development-environment.py
  - start-real-application.py
- 📁 **orchestration/**: Scripts de orquestração
  - layered-build-startup.py
- 📁 **use-cases/**: Casos de uso específicos

### 🏢 [03-domain-layer](./03-domain-layer/)
**Entidades e Regras de Negócio**
- 📁 **entities/**: Entidades do domínio
  - temp_stock.json (modelo de estoque)
- 📁 **value-objects/**: Objetos de valor
- 📁 **domain-services/**: Serviços de domínio

### 🔧 [04-infrastructure-layer](./04-infrastructure-layer/)
**Infraestrutura e Configurações Externas**
- 📁 **docker/**: Configurações Docker
  - docker-compose.free-tier.yml
  - docker-compose.infrastructure-only.yml
  - docker-compose.scalable-simple.yml
  - docker-compose.scalable.yml
  - prometheus-metrics-export.txt
- 📁 **kubernetes/**: Configurações Kubernetes
- 📁 **config/**: Configurações de infraestrutura
- 📁 **databases/**: Configurações de banco

### 🚀 [05-microservices](./05-microservices/)
**Implementação dos Microserviços**
- 📁 **api-gateway/**: Gateway de API
- 📁 **log-services/**: Serviços de log
- 📁 **stock-services/**: Serviços de estoque
- 📁 **shared/**: Componentes compartilhados

### 🚀 [06-deployment](./06-deployment/)
**Scripts de Deployment e DevOps**
- 📁 **scripts/**: Scripts de deployment
- 📁 **automation/**: Automação de deploy
- 📁 **ci-cd/**: Configurações CI/CD

### 🧪 [07-testing](./07-testing/)
**Testes, Performance e Qualidade**
- 📁 **performance-tests/**: Testes de performance
  - performance-test-1000-requests.py
  - performance-test-powershell.ps1
  - simplified-stress-test.py
  - stress-test-with-graphics.py
  - view-stress-test-results.py
- 📁 **unit-tests/**: Testes unitários
  - application-test.properties
  - mock-services-test.py
  - simple-app-test.py
  - run-10k-test.py
- 📁 **integration-tests/**: Testes de integração
- 📁 **stress-tests/**: Testes de stress

### ⚙️ [08-configuration](./08-configuration/)
**Configurações Globais e Ambiente**
- 📁 **ports/**: Configurações de portas
  - configure-ports-and-run.py
  - configure-standard-ports.py
  - FINAL_PORT_CONFIGURATION.json
  - import_checker.py
- 📁 **properties/**: Arquivos de propriedades
- 📁 **environment/**: Configurações de ambiente

### 📊 [09-monitoring](./09-monitoring/)
**Monitoramento e Observabilidade**
- 📁 **metrics/**: Métricas do sistema
- 📁 **logs/**: Logs do sistema
- 📁 **prometheus/**: Configurações Prometheus
- 📁 **grafana/**: Dashboards Grafana

### 🛠️ [10-tools-utilities](./10-tools-utilities/)
**Ferramentas e Utilitários**
- 📁 **scripts/**: Scripts utilitários
  - final_cleanup.py
  - startup-microservices.ps1
  - resources_comparison_chart_20250903_235758.png
  - workspace_refactorer.py
  - workspace_refactoring_report.json
- 📁 **generators/**: Geradores de código
- 📁 **analyzers/**: Analisadores
- 📁 **cleaners/**: Ferramentas de limpeza

---

## 🎯 Fluxos de Trabalho Principais

### 🚀 **Inicialização da Aplicação**
```bash
# 1. Configurar ambiente
cd 02-application-layer/services/
python setup-development-environment.py

# 2. Iniciar aplicação
python start-real-application.py
```

### 🔧 **Configuração de Portas**
```bash
# Configurar portas padrão
cd 08-configuration/ports/
python configure-standard-ports.py
```

### 🧪 **Executar Testes**
```bash
# Testes de performance
cd 07-testing/performance-tests/
python stress-test-with-graphics.py

# Visualizar resultados
python view-stress-test-results.py
```

### 🏗️ **Build e Deploy**
```bash
# Orquestração em camadas
cd 02-application-layer/orchestration/
python layered-build-startup.py
```

---

## 📈 Métricas da Refatoração

- ✅ **65 arquivos** reorganizados
- 🏗️ **10 camadas** da Clean Architecture
- 📄 **10 documentações** de camada criadas
- 🎯 **0 erros** no processo de refatoração

---

## 🔄 Próximos Passos

1. **✅ Refatoração Concluída** - Workspace organizado
2. **🔍 Validação** - Verificar funcionamento dos scripts
3. **📝 Atualização** - Corrigir paths e imports se necessário
4. **🧪 Teste** - Executar testes de funcionalidade
5. **📊 Monitoramento** - Verificar se todas as funcionalidades estão operacionais

---

## 🛡️ Arquitetura Limpa

Esta estrutura segue os princípios da **Clean Architecture**:
- **Separation of Concerns**: Cada camada tem responsabilidades bem definidas
- **Dependency Inversion**: Dependências apontam para dentro
- **Interface Segregation**: Interfaces específicas para cada caso de uso
- **Single Responsibility**: Cada arquivo tem uma única responsabilidade

---

*📅 Refatoração realizada em: 2025-01-09*  
*🔧 Ferramenta: workspace_refactorer.py*  
*📊 Relatório completo: [10-tools-utilities/scripts/workspace_refactoring_report.json](./10-tools-utilities/scripts/workspace_refactoring_report.json)*
