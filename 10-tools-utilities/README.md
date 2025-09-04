# 🛠️ Tools & Utilities Layer (Ferramentas e Utilitários)

A camada de ferramentas e utilitários fornece scripts, automações e ferramentas auxiliares para desenvolvimento, deployment, monitoramento e manutenção do sistema KBNT Kafka Logs.

## 📋 Índice

- [Visão Geral](#-visão-geral)
- [Estrutura](#-estrutura)
- [Scripts de Automação](#-scripts-de-automação)
- [Ferramentas de Desenvolvimento](#-ferramentas-de-desenvolvimento)
- [Monitoramento e Observabilidade](#-monitoramento-e-observabilidade)
- [Scripts de Deployment](#-scripts-de-deployment)
- [Utilitários de Performance](#-utilitários-de-performance)
- [Análise e Relatórios](#-análise-e-relatórios)
- [Simuladores e Demonstrações](#-simuladores-e-demonstrações)
- [Manutenção](#-manutenção)

## 🎯 Visão Geral

Esta camada contém todas as ferramentas auxiliares que facilitam o desenvolvimento, deployment e operação do sistema KBNT Kafka Logs. Inclui scripts de automação, ferramentas de monitoramento, simuladores e utilitários diversos.

### Características Principais:
- **Automação**: Scripts para tarefas repetitivas
- **Monitoramento**: Ferramentas de observabilidade
- **Performance**: Utilitários de análise e teste
- **Development**: Ferramentas de desenvolvimento
- **Deployment**: Scripts de implantação
- **Maintenance**: Utilitários de manutenção

## 🏗️ Estrutura

```
10-tools-utilities/
├── scripts/                      # Scripts gerais
│   ├── setup/
│   │   ├── setup-environment.py
│   │   ├── setup-java-local.ps1
│   │   ├── setup-python.ps1
│   │   └── setup-vscode-environment.ps1
│   ├── analysis/
│   │   ├── import_checker.py
│   │   ├── code_quality_analyzer.py
│   │   └── dependency_analyzer.py
│   ├── simulators/
│   │   ├── amq-streams-simulator.py
│   │   ├── microservices-real-workflow.py
│   │   └── virtual-stock-simulator.py
│   └── utilities/
│       ├── workspace_organizer.py
│       ├── final_cleanup.py
│       └── resource_comparison.py
├── automation/                   # Automação
│   ├── build/
│   │   ├── build-all-microservices.sh
│   │   ├── build-docker-images.py
│   │   └── maven-build-optimizer.py
│   ├── deployment/
│   │   ├── deploy-to-k8s.py
│   │   ├── rollback-deployment.py
│   │   └── health-check-deployment.py
│   ├── testing/
│   │   ├── run-all-tests.py
│   │   ├── performance-test-runner.py
│   │   └── integration-test-suite.py
│   └── maintenance/
│       ├── cleanup-logs.py
│       ├── backup-databases.py
│       └── rotate-certificates.py
├── monitoring/                   # Monitoramento
│   ├── dashboards/
│   │   ├── grafana-dashboards/
│   │   ├── prometheus-rules/
│   │   └── alerting-rules/
│   ├── collectors/
│   │   ├── metrics-collector.py
│   │   ├── log-aggregator.py
│   │   └── trace-analyzer.py
│   └── health-checks/
│       ├── system-health.py
│       ├── service-health.py
│       └── database-health.py
└── README.md                    # Este arquivo
```

## 🔧 Scripts de Automação

### 1. **Environment Setup Scripts**

#### setup-environment.py
```python
#!/usr/bin/env python3
"""
KBNT Kafka Logs - Environment Setup
Configura ambiente completo para desenvolvimento
"""

import os
import subprocess
import sys
import platform
from pathlib import Path

class EnvironmentSetup:
    def __init__(self):
        self.system = platform.system().lower()
        self.workspace_path = Path.cwd()
        
    def setup_complete_environment(self):
        """Setup completo do ambiente"""
        print("🚀 KBNT Kafka Logs - Environment Setup")
        print("=" * 50)
        
        steps = [
            ("🔍 Checking prerequisites", self.check_prerequisites),
            ("☕ Setting up Java environment", self.setup_java),
            ("🐍 Setting up Python environment", self.setup_python),
            ("🐳 Setting up Docker environment", self.setup_docker),
            ("📊 Setting up monitoring tools", self.setup_monitoring),
            ("🔧 Configuring IDE settings", self.setup_ide),
            ("✅ Validating setup", self.validate_setup)
        ]
        
        for description, step_func in steps:
            print(f"\n{description}...")
            try:
                step_func()
                print(f"✅ {description} - Completed")
            except Exception as e:
                print(f"❌ {description} - Failed: {e}")
                return False
        
        print("\n🎉 Environment setup completed successfully!")
        return True
    
    def check_prerequisites(self):
        """Verifica pré-requisitos"""
        required_tools = ["git", "docker", "java", "python"]
        
        for tool in required_tools:
            if not self.is_tool_available(tool):
                raise Exception(f"{tool} is not installed or not in PATH")
    
    def setup_java(self):
        """Configura ambiente Java"""
        # Verificar versão do Java
        result = subprocess.run(["java", "-version"], capture_output=True, text=True)
        if "17" not in result.stderr:
            raise Exception("Java 17 is required")
        
        # Configurar JAVA_HOME se necessário
        java_home = self.get_java_home()
        if not java_home:
            raise Exception("JAVA_HOME not set")
    
    def setup_python(self):
        """Configura ambiente Python"""
        # Criar virtual environment
        venv_path = self.workspace_path / "venv"
        if not venv_path.exists():
            subprocess.run([sys.executable, "-m", "venv", str(venv_path)], check=True)
        
        # Instalar dependências
        pip_path = venv_path / ("Scripts" if self.system == "windows" else "bin") / "pip"
        subprocess.run([str(pip_path), "install", "-r", "requirements.txt"], check=True)
    
    def setup_docker(self):
        """Configura ambiente Docker"""
        # Verificar se Docker está rodando
        subprocess.run(["docker", "ps"], check=True, capture_output=True)
        
        # Build imagens se necessário
        subprocess.run(["docker-compose", "build"], check=True)
    
    def setup_monitoring(self):
        """Configura ferramentas de monitoramento"""
        # Configurar Prometheus
        prometheus_config = self.workspace_path / "monitoring" / "prometheus.yml"
        if not prometheus_config.exists():
            self.create_prometheus_config(prometheus_config)
        
        # Configurar Grafana
        grafana_dir = self.workspace_path / "monitoring" / "grafana"
        if not grafana_dir.exists():
            grafana_dir.mkdir(parents=True)
            self.create_grafana_dashboards(grafana_dir)
    
    def is_tool_available(self, tool: str) -> bool:
        """Verifica se ferramenta está disponível"""
        try:
            subprocess.run([tool, "--version"], capture_output=True, check=True)
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            return False

if __name__ == "__main__":
    setup = EnvironmentSetup()
    setup.setup_complete_environment()
```

#### build-all-microservices.sh
```bash
#!/bin/bash
# Build script para todos os microserviços

set -e

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MICROSERVICES_DIR="$WORKSPACE_DIR/05-microservices"

echo "🏗️ Building KBNT Kafka Logs Microservices"
echo "Workspace: $WORKSPACE_DIR"
echo "Microservices: $MICROSERVICES_DIR"
echo "=================================="

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

build_service() {
    local service_dir=$1
    local service_name=$(basename "$service_dir")
    
    echo -e "\n${YELLOW}📦 Building $service_name...${NC}"
    
    if [ ! -f "$service_dir/pom.xml" ]; then
        echo -e "${RED}❌ No pom.xml found in $service_dir${NC}"
        return 1
    fi
    
    cd "$service_dir"
    
    # Maven build
    if mvn clean package -DskipTests -q; then
        echo -e "${GREEN}✅ $service_name built successfully${NC}"
        
        # Build Docker image if Dockerfile exists
        if [ -f "Dockerfile" ]; then
            echo -e "${YELLOW}🐳 Building Docker image for $service_name...${NC}"
            if docker build -t "kbnt/$service_name:latest" .; then
                echo -e "${GREEN}✅ Docker image built: kbnt/$service_name:latest${NC}"
            else
                echo -e "${RED}❌ Failed to build Docker image for $service_name${NC}"
                return 1
            fi
        fi
        
        return 0
    else
        echo -e "${RED}❌ Failed to build $service_name${NC}"
        return 1
    fi
}

# Build all microservices
SUCCESS_COUNT=0
TOTAL_COUNT=0

for service_dir in "$MICROSERVICES_DIR"/*; do
    if [ -d "$service_dir" ]; then
        TOTAL_COUNT=$((TOTAL_COUNT + 1))
        if build_service "$service_dir"; then
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        fi
    fi
done

echo -e "\n=================================="
echo -e "${GREEN}✅ Build Summary:${NC}"
echo -e "   Successfully built: $SUCCESS_COUNT/$TOTAL_COUNT services"

if [ $SUCCESS_COUNT -eq $TOTAL_COUNT ]; then
    echo -e "${GREEN}🎉 All microservices built successfully!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some builds failed. Check the output above.${NC}"
    exit 1
fi
```

### 2. **Performance Testing Tools**

#### performance-test-runner.py
```python
#!/usr/bin/env python3
"""
KBNT Kafka Logs - Performance Test Runner
Executa bateria completa de testes de performance
"""

import asyncio
import json
import time
import subprocess
from pathlib import Path
from typing import Dict, List
from dataclasses import dataclass, asdict

@dataclass
class TestResult:
    test_name: str
    duration_seconds: float
    requests_per_second: float
    avg_response_time_ms: float
    p95_response_time_ms: float
    p99_response_time_ms: float
    error_rate_percent: float
    success: bool

class PerformanceTestRunner:
    def __init__(self, base_url: str = "http://localhost:8080"):
        self.base_url = base_url
        self.results: List[TestResult] = []
        self.report_dir = Path("07-testing/reports")
        self.report_dir.mkdir(exist_ok=True)
        
    async def run_all_tests(self) -> Dict:
        """Executa todos os testes de performance"""
        print("🚀 KBNT Performance Test Suite")
        print("=" * 50)
        
        test_suite = [
            ("baseline_test", self.run_baseline_test),
            ("load_test", self.run_load_test),
            ("stress_test", self.run_stress_test),
            ("spike_test", self.run_spike_test),
            ("endurance_test", self.run_endurance_test),
            ("volume_test", self.run_volume_test)
        ]
        
        for test_name, test_func in test_suite:
            print(f"\n🧪 Running {test_name}...")
            try:
                result = await test_func()
                self.results.append(result)
                print(f"✅ {test_name} completed: {result.requests_per_second:.0f} RPS")
            except Exception as e:
                print(f"❌ {test_name} failed: {e}")
                self.results.append(TestResult(
                    test_name=test_name,
                    duration_seconds=0,
                    requests_per_second=0,
                    avg_response_time_ms=0,
                    p95_response_time_ms=0,
                    p99_response_time_ms=0,
                    error_rate_percent=100,
                    success=False
                ))
        
        return self.generate_report()
    
    async def run_baseline_test(self) -> TestResult:
        """Teste baseline - 10 usuários por 60 segundos"""
        return await self.execute_load_test(
            concurrent_users=10,
            duration_seconds=60,
            test_name="baseline_test"
        )
    
    async def run_load_test(self) -> TestResult:
        """Teste de carga - 100 usuários por 300 segundos"""
        return await self.execute_load_test(
            concurrent_users=100,
            duration_seconds=300,
            test_name="load_test"
        )
    
    async def run_stress_test(self) -> TestResult:
        """Teste de stress - 500 usuários por 180 segundos"""
        return await self.execute_load_test(
            concurrent_users=500,
            duration_seconds=180,
            test_name="stress_test"
        )
    
    async def run_spike_test(self) -> TestResult:
        """Teste de pico - 1000 usuários por 60 segundos"""
        return await self.execute_load_test(
            concurrent_users=1000,
            duration_seconds=60,
            test_name="spike_test"
        )
    
    async def run_endurance_test(self) -> TestResult:
        """Teste de resistência - 50 usuários por 1800 segundos (30 min)"""
        return await self.execute_load_test(
            concurrent_users=50,
            duration_seconds=1800,
            test_name="endurance_test"
        )
    
    async def run_volume_test(self) -> TestResult:
        """Teste de volume - Alto volume de dados"""
        # Implementar teste específico para volume de dados
        return await self.execute_load_test(
            concurrent_users=200,
            duration_seconds=300,
            test_name="volume_test",
            payload_size="large"
        )
    
    def generate_report(self) -> Dict:
        """Gera relatório consolidado"""
        timestamp = int(time.time())
        
        report = {
            "timestamp": timestamp,
            "summary": {
                "total_tests": len(self.results),
                "passed_tests": len([r for r in self.results if r.success]),
                "failed_tests": len([r for r in self.results if not r.success]),
                "best_rps": max([r.requests_per_second for r in self.results]),
                "worst_rps": min([r.requests_per_second for r in self.results if r.success]),
                "avg_rps": sum([r.requests_per_second for r in self.results if r.success]) / len([r for r in self.results if r.success])
            },
            "results": [asdict(result) for result in self.results],
            "recommendations": self.generate_recommendations()
        }
        
        # Salvar relatório
        report_file = self.report_dir / f"performance_report_{timestamp}.json"
        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2)
        
        print(f"\n📊 Report saved: {report_file}")
        return report
    
    def generate_recommendations(self) -> List[str]:
        """Gera recomendações baseadas nos resultados"""
        recommendations = []
        
        successful_results = [r for r in self.results if r.success]
        if not successful_results:
            return ["All tests failed - check system health"]
        
        avg_rps = sum(r.requests_per_second for r in successful_results) / len(successful_results)
        
        if avg_rps < 1000:
            recommendations.append("Performance below expected - consider scaling up")
        elif avg_rps > 25000:
            recommendations.append("Excellent performance - system is well optimized")
        
        high_error_tests = [r for r in self.results if r.error_rate_percent > 5]
        if high_error_tests:
            recommendations.append(f"High error rates in: {', '.join([r.test_name for r in high_error_tests])}")
        
        return recommendations

if __name__ == "__main__":
    runner = PerformanceTestRunner()
    asyncio.run(runner.run_all_tests())
```

### 3. **Monitoring Tools**

#### system-health.py
```python
#!/usr/bin/env python3
"""
KBNT Kafka Logs - System Health Monitor
Monitora saúde geral do sistema
"""

import psutil
import requests
import time
import json
from typing import Dict, List
from dataclasses import dataclass

@dataclass
class HealthCheck:
    name: str
    status: str  # "healthy", "warning", "critical"
    message: str
    metrics: Dict = None

class SystemHealthMonitor:
    def __init__(self):
        self.checks = []
        self.thresholds = {
            "cpu_warning": 70,
            "cpu_critical": 90,
            "memory_warning": 80,
            "memory_critical": 95,
            "disk_warning": 80,
            "disk_critical": 95
        }
    
    def run_health_checks(self) -> Dict:
        """Executa todos os health checks"""
        print("🔍 KBNT System Health Check")
        print("=" * 40)
        
        self.checks = [
            self.check_system_resources(),
            self.check_application_health(),
            self.check_database_health(),
            self.check_kafka_health(),
            self.check_redis_health()
        ]
        
        # Determinar status geral
        critical_count = len([c for c in self.checks if c.status == "critical"])
        warning_count = len([c for c in self.checks if c.status == "warning"])
        
        if critical_count > 0:
            overall_status = "critical"
        elif warning_count > 0:
            overall_status = "warning"
        else:
            overall_status = "healthy"
        
        report = {
            "timestamp": time.time(),
            "overall_status": overall_status,
            "checks": [
                {
                    "name": check.name,
                    "status": check.status,
                    "message": check.message,
                    "metrics": check.metrics or {}
                }
                for check in self.checks
            ],
            "summary": {
                "total_checks": len(self.checks),
                "healthy": len([c for c in self.checks if c.status == "healthy"]),
                "warnings": warning_count,
                "critical": critical_count
            }
        }
        
        self.print_health_report(report)
        return report
    
    def check_system_resources(self) -> HealthCheck:
        """Verifica recursos do sistema"""
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        metrics = {
            "cpu_percent": cpu_percent,
            "memory_percent": memory.percent,
            "disk_percent": disk.percent,
            "memory_available_gb": memory.available / (1024**3),
            "disk_free_gb": disk.free / (1024**3)
        }
        
        # Determinar status
        if (cpu_percent > self.thresholds["cpu_critical"] or 
            memory.percent > self.thresholds["memory_critical"] or
            disk.percent > self.thresholds["disk_critical"]):
            status = "critical"
            message = "Critical resource usage detected"
        elif (cpu_percent > self.thresholds["cpu_warning"] or 
              memory.percent > self.thresholds["memory_warning"] or
              disk.percent > self.thresholds["disk_warning"]):
            status = "warning"
            message = "High resource usage"
        else:
            status = "healthy"
            message = "System resources normal"
        
        return HealthCheck("System Resources", status, message, metrics)
    
    def check_application_health(self) -> HealthCheck:
        """Verifica saúde da aplicação"""
        try:
            response = requests.get("http://localhost:8080/actuator/health", timeout=5)
            if response.status_code == 200:
                health_data = response.json()
                if health_data.get("status") == "UP":
                    return HealthCheck("Application", "healthy", "Application is running")
                else:
                    return HealthCheck("Application", "warning", "Application health check failed")
            else:
                return HealthCheck("Application", "critical", f"HTTP {response.status_code}")
        except Exception as e:
            return HealthCheck("Application", "critical", f"Cannot connect: {str(e)}")
    
    def check_database_health(self) -> HealthCheck:
        """Verifica saúde do banco de dados"""
        try:
            response = requests.get("http://localhost:8080/actuator/health/db", timeout=5)
            if response.status_code == 200:
                return HealthCheck("Database", "healthy", "Database connection OK")
            else:
                return HealthCheck("Database", "critical", "Database connection failed")
        except Exception as e:
            return HealthCheck("Database", "critical", f"Database check failed: {str(e)}")
    
    def check_kafka_health(self) -> HealthCheck:
        """Verifica saúde do Kafka"""
        try:
            # Verificar através do actuator da aplicação
            response = requests.get("http://localhost:8080/actuator/health/kafka", timeout=5)
            if response.status_code == 200:
                return HealthCheck("Kafka", "healthy", "Kafka connection OK")
            else:
                return HealthCheck("Kafka", "critical", "Kafka connection failed")
        except Exception as e:
            return HealthCheck("Kafka", "critical", f"Kafka check failed: {str(e)}")
    
    def check_redis_health(self) -> HealthCheck:
        """Verifica saúde do Redis"""
        try:
            response = requests.get("http://localhost:8080/actuator/health/redis", timeout=5)
            if response.status_code == 200:
                return HealthCheck("Redis", "healthy", "Redis connection OK")
            else:
                return HealthCheck("Redis", "warning", "Redis connection failed")
        except Exception as e:
            return HealthCheck("Redis", "warning", f"Redis check failed: {str(e)}")
    
    def print_health_report(self, report: Dict):
        """Imprime relatório de saúde"""
        status_colors = {
            "healthy": "🟢",
            "warning": "🟡", 
            "critical": "🔴"
        }
        
        print(f"\n📊 Overall Status: {status_colors[report['overall_status']]} {report['overall_status'].upper()}")
        print(f"📈 Summary: {report['summary']['healthy']} healthy, {report['summary']['warnings']} warnings, {report['summary']['critical']} critical")
        
        print("\n📋 Detailed Results:")
        for check in report['checks']:
            icon = status_colors[check['status']]
            print(f"{icon} {check['name']}: {check['message']}")
            
            if check['metrics']:
                for key, value in check['metrics'].items():
                    if isinstance(value, float):
                        print(f"   {key}: {value:.1f}")
                    else:
                        print(f"   {key}: {value}")

if __name__ == "__main__":
    monitor = SystemHealthMonitor()
    monitor.run_health_checks()
```

## 🚀 Comandos Úteis

### Scripts de Execução Rápida:
```bash
# Setup completo do ambiente
python 10-tools-utilities/scripts/setup-environment.py

# Build de todos os microserviços
./10-tools-utilities/automation/build-all-microservices.sh

# Executar testes de performance
python 10-tools-utilities/scripts/performance-test-runner.py

# Verificar saúde do sistema
python 10-tools-utilities/monitoring/system-health.py

# Análise de qualidade do código
python 10-tools-utilities/scripts/import_checker.py

# Organização do workspace
python 10-tools-utilities/scripts/workspace_organizer.py
```

### PowerShell Scripts (Windows):
```powershell
# Setup ambiente Java
.\10-tools-utilities\automation\setup-java-local.ps1

# Setup ambiente Python
.\10-tools-utilities\automation\setup-python.ps1

# Setup VSCode
.\10-tools-utilities\automation\setup-vscode-environment.ps1
```

## 📊 Métricas e Relatórios

### Tipos de Relatórios Gerados:
- **Performance Reports**: Análise de performance detalhada
- **Code Quality Reports**: Qualidade do código e imports
- **Health Reports**: Estado de saúde do sistema
- **Resource Usage Reports**: Uso de recursos do sistema
- **Deployment Reports**: Status de deployments

### Localização dos Relatórios:
- `07-testing/reports/` - Relatórios de teste e performance
- `09-documentation/performance/` - Documentação de performance
- `logs/` - Logs de execução das ferramentas

## 🔧 Manutenção e Troubleshooting

### Scripts de Manutenção:
- **cleanup-logs.py**: Limpeza de logs antigos
- **backup-databases.py**: Backup automático de bancos
- **rotate-certificates.py**: Rotação de certificados
- **workspace_organizer.py**: Reorganização do workspace

### Troubleshooting:
- **system-health.py**: Diagnóstico geral do sistema
- **service-health.py**: Verificação específica de serviços
- **import_checker.py**: Correção de problemas de imports

---

**Autor**: KBNT Development Team  
**Versão**: 2.1.0  
**Última Atualização**: Janeiro 2025
