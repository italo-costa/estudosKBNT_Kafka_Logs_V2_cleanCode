#!/usr/bin/env python3
"""
WSL Linux Docker Compose Manager - Clean Architecture
Força execução exclusiva no ambiente virtual Linux (WSL Ubuntu)
"""

import subprocess
import os
import json
from pathlib import Path
from datetime import datetime

class WSLDockerManager:
    def __init__(self, workspace_root):
        self.workspace_root = Path(workspace_root)
        self.wsl_distro = "Ubuntu"
        self.docker_compose_files = {
            "scalable": "04-infrastructure-layer/docker/docker-compose.scalable.yml",
            "simple": "04-infrastructure-layer/docker/docker-compose.scalable-simple.yml", 
            "infrastructure": "04-infrastructure-layer/docker/docker-compose.infrastructure-only.yml",
            "free_tier": "04-infrastructure-layer/docker/docker-compose.free-tier.yml"
        }
        
    def validate_wsl_environment(self):
        """Valida se o ambiente WSL está disponível"""
        print("🐧 Validando ambiente WSL Linux...")
        
        try:
            # Verificar se WSL está disponível
            result = subprocess.run(
                ["wsl", "-l", "-v"],
                capture_output=True,
                text=True,
                shell=True
            )
            
            if result.returncode != 0:
                print("❌ WSL não está disponível no sistema")
                return False
            
            # Verificar se Ubuntu está instalado
            if "Ubuntu" not in result.stdout:
                print("❌ Ubuntu não está instalado no WSL")
                return False
            
            print("✅ WSL Ubuntu detectado")
            return True
            
        except Exception as e:
            print(f"❌ Erro ao validar WSL: {e}")
            return False
    
    def validate_docker_in_wsl(self):
        """Valida se Docker está funcionando no WSL"""
        print("🐳 Validando Docker no WSL...")
        
        try:
            # Testar Docker no WSL
            result = subprocess.run(
                ["wsl", "-d", self.wsl_distro, "docker", "--version"],
                capture_output=True,
                text=True,
                shell=True
            )
            
            if result.returncode != 0:
                print("❌ Docker não está funcionando no WSL")
                return False
            
            print(f"✅ Docker detectado: {result.stdout.strip()}")
            
            # Testar Docker Compose
            result = subprocess.run(
                ["wsl", "-d", self.wsl_distro, "docker-compose", "--version"],
                capture_output=True,
                text=True,
                shell=True
            )
            
            if result.returncode != 0:
                print("❌ Docker Compose não está funcionando no WSL")
                return False
            
            print(f"✅ Docker Compose detectado: {result.stdout.strip()}")
            return True
            
        except Exception as e:
            print(f"❌ Erro ao validar Docker no WSL: {e}")
            return False
    
    def convert_windows_path_to_wsl(self, windows_path):
        """Converte caminho Windows para WSL"""
        # Converter C:\workspace\... para /mnt/c/workspace/...
        windows_path = str(windows_path)
        if windows_path.startswith('C:'):
            wsl_path = windows_path.replace('C:', '/mnt/c').replace('\\', '/')
        else:
            wsl_path = windows_path.replace('\\', '/')
        
        return wsl_path
    
    def execute_wsl_command(self, command, working_dir=None):
        """Executa comando no WSL"""
        
        if working_dir:
            wsl_dir = self.convert_windows_path_to_wsl(working_dir)
            full_command = ["wsl", "-d", self.wsl_distro, "bash", "-c", f"cd {wsl_dir} && {command}"]
        else:
            full_command = ["wsl", "-d", self.wsl_distro, "bash", "-c", command]
        
        print(f"🐧 Executando no WSL: {command}")
        
        try:
            result = subprocess.run(
                full_command,
                capture_output=True,
                text=True,
                shell=True
            )
            
            return {
                "success": result.returncode == 0,
                "stdout": result.stdout,
                "stderr": result.stderr,
                "returncode": result.returncode
            }
            
        except Exception as e:
            return {
                "success": False,
                "stdout": "",
                "stderr": str(e),
                "returncode": -1
            }
    
    def docker_compose_up(self, compose_type="scalable", detached=True):
        """Inicia serviços usando Docker Compose no WSL"""
        
        if compose_type not in self.docker_compose_files:
            print(f"❌ Tipo de compose inválido: {compose_type}")
            return False
        
        compose_file = self.docker_compose_files[compose_type]
        compose_path = self.workspace_root / compose_file
        
        if not compose_path.exists():
            print(f"❌ Arquivo não encontrado: {compose_path}")
            return False
        
        print(f"🚀 Iniciando Docker Compose: {compose_type}")
        
        # Comando Docker Compose
        detached_flag = "-d" if detached else ""
        command = f"docker-compose -f {compose_file} up {detached_flag}"
        
        result = self.execute_wsl_command(command, self.workspace_root)
        
        if result["success"]:
            print("✅ Docker Compose iniciado com sucesso!")
            print(result["stdout"])
            return True
        else:
            print("❌ Erro ao iniciar Docker Compose:")
            print(result["stderr"])
            return False
    
    def docker_compose_down(self, compose_type="scalable"):
        """Para serviços usando Docker Compose no WSL"""
        
        if compose_type not in self.docker_compose_files:
            print(f"❌ Tipo de compose inválido: {compose_type}")
            return False
        
        compose_file = self.docker_compose_files[compose_type]
        
        print(f"🛑 Parando Docker Compose: {compose_type}")
        
        command = f"docker-compose -f {compose_file} down"
        result = self.execute_wsl_command(command, self.workspace_root)
        
        if result["success"]:
            print("✅ Docker Compose parado com sucesso!")
            return True
        else:
            print("❌ Erro ao parar Docker Compose:")
            print(result["stderr"])
            return False
    
    def docker_compose_status(self):
        """Verifica status dos containers"""
        print("📊 Verificando status dos containers...")
        
        command = "docker ps --format 'table {{.Names}}\\t{{.Status}}\\t{{.Ports}}'"
        result = self.execute_wsl_command(command)
        
        if result["success"]:
            print("✅ Status dos containers:")
            print(result["stdout"])
            return True
        else:
            print("❌ Erro ao verificar status:")
            print(result["stderr"])
            return False
    
    def docker_compose_logs(self, service_name=None, compose_type="scalable", tail=50):
        """Visualiza logs dos serviços"""
        
        compose_file = self.docker_compose_files[compose_type]
        
        if service_name:
            command = f"docker-compose -f {compose_file} logs --tail={tail} {service_name}"
            print(f"📋 Logs do serviço {service_name}:")
        else:
            command = f"docker-compose -f {compose_file} logs --tail={tail}"
            print(f"📋 Logs de todos os serviços:")
        
        result = self.execute_wsl_command(command, self.workspace_root)
        
        if result["success"]:
            print(result["stdout"])
            return True
        else:
            print("❌ Erro ao visualizar logs:")
            print(result["stderr"])
            return False
    
    def setup_port_forwarding(self):
        """Configura port forwarding para acesso Windows -> WSL"""
        print("🔗 Configurando port forwarding WSL...")
        
        # Lista de portas para forward
        ports = [
            8080, 8081, 8082, 8083, 8084, 8085,  # Aplicações
            9080, 9081, 9082, 9083, 9084, 9085,  # Management
            5432,  # PostgreSQL
            6379,  # Redis
            9092, 29092,  # Kafka
            2181   # Zookeeper
        ]
        
        forwarded_ports = []
        
        for port in ports:
            command = f"netsh interface portproxy add v4tov4 listenport={port} listenaddress=0.0.0.0 connectport={port} connectaddress=localhost"
            
            try:
                result = subprocess.run(
                    ["powershell", "-Command", command],
                    capture_output=True,
                    text=True,
                    shell=True
                )
                
                if result.returncode == 0:
                    forwarded_ports.append(port)
                    
            except Exception as e:
                print(f"⚠️ Erro ao configurar porta {port}: {e}")
        
        print(f"✅ Port forwarding configurado para {len(forwarded_ports)} portas")
        return forwarded_ports
    
    def health_check_services(self):
        """Verifica saúde dos serviços"""
        print("🏥 Executando health check dos serviços...")
        
        services = {
            "API Gateway": "http://localhost:8080/actuator/health",
            "Log Producer": "http://localhost:8081/actuator/health",
            "Log Consumer": "http://localhost:8082/actuator/health",
            "Log Analytics": "http://localhost:8083/actuator/health",
            "Virtual Stock": "http://localhost:8084/actuator/health",
            "KBNT Consumer": "http://localhost:8085/actuator/health"
        }
        
        healthy_services = []
        
        for service_name, health_url in services.items():
            command = f"curl -s -o /dev/null -w '%{{http_code}}' {health_url}"
            result = self.execute_wsl_command(command)
            
            if result["success"] and "200" in result["stdout"]:
                print(f"✅ {service_name}: Saudável")
                healthy_services.append(service_name)
            else:
                print(f"❌ {service_name}: Não responsivo")
        
        print(f"\n📊 Serviços saudáveis: {len(healthy_services)}/{len(services)}")
        return healthy_services
    
    def complete_startup_sequence(self, compose_type="scalable"):
        """Sequência completa de inicialização"""
        print("🚀 INICIALIZAÇÃO COMPLETA - AMBIENTE WSL LINUX")
        print("=" * 60)
        
        # 1. Validar ambiente
        if not self.validate_wsl_environment():
            return False
        
        if not self.validate_docker_in_wsl():
            return False
        
        # 2. Configurar port forwarding
        self.setup_port_forwarding()
        
        # 3. Iniciar Docker Compose
        if not self.docker_compose_up(compose_type):
            return False
        
        # 4. Aguardar inicialização
        print("⏳ Aguardando inicialização dos serviços...")
        import time
        time.sleep(30)
        
        # 5. Verificar status
        self.docker_compose_status()
        
        # 6. Health check
        healthy_services = self.health_check_services()
        
        print(f"\n🎉 INICIALIZAÇÃO CONCLUÍDA!")
        print(f"✅ Ambiente: WSL Ubuntu + Docker")
        print(f"✅ Compose: {compose_type}")
        print(f"✅ Serviços: {len(healthy_services)} ativos")
        
        return True
    
    def generate_startup_script(self):
        """Gera script de inicialização rápida"""
        
        script_content = f'''#!/bin/bash
# Startup Script - WSL Docker Compose
# Gerado em: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

echo "🚀 INICIANDO AMBIENTE KBNT - WSL LINUX"
echo "======================================"

# Verificar Docker
if ! docker --version > /dev/null 2>&1; then
    echo "❌ Docker não está disponível"
    exit 1
fi

if ! docker-compose --version > /dev/null 2>&1; then
    echo "❌ Docker Compose não está disponível"
    exit 1
fi

echo "✅ Docker e Docker Compose detectados"

# Ir para diretório do projeto
WORKSPACE_PATH="/mnt/c/workspace/estudosKBNT_Kafka_Logs"
cd "$WORKSPACE_PATH" || {{
    echo "❌ Não foi possível acessar $WORKSPACE_PATH"
    exit 1
}}

echo "📁 Diretório: $(pwd)"

# Iniciar serviços
echo "🚀 Iniciando Docker Compose..."
docker-compose -f 04-infrastructure-layer/docker/docker-compose.scalable.yml up -d

# Aguardar inicialização
echo "⏳ Aguardando inicialização (30s)..."
sleep 30

# Verificar status
echo "📊 Status dos containers:"
docker ps --format "table {{{{.Names}}}}\\t{{{{.Status}}}}\\t{{{{.Ports}}}}"

# Health checks
echo "🏥 Verificando saúde dos serviços..."
for port in 8080 8081 8082 8083 8084 8085; do
    if curl -s -o /dev/null -w "%{{http_code}}" http://localhost:$port/actuator/health | grep -q "200"; then
        echo "✅ Serviço na porta $port: Saudável"
    else
        echo "❌ Serviço na porta $port: Não responsivo"
    fi
done

echo ""
echo "🎉 AMBIENTE INICIADO!"
echo "🌐 API Gateway: http://localhost:8080"
echo "📊 Métricas: http://localhost:9080/actuator"
echo "📋 Para ver logs: docker-compose -f 04-infrastructure-layer/docker/docker-compose.scalable.yml logs"
'''
        
        script_path = self.workspace_root / "06-deployment" / "scripts" / "start-wsl-environment.sh"
        script_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(script_path, 'w', encoding='utf-8') as f:
            f.write(script_content)
        
        # Tornar executável no WSL
        wsl_script_path = self.convert_windows_path_to_wsl(script_path)
        self.execute_wsl_command(f"chmod +x {wsl_script_path}")
        
        print(f"✅ Script de startup criado: {script_path}")
        return script_path

def main():
    """Função principal"""
    workspace_root = Path(__file__).parent.parent.parent
    manager = WSLDockerManager(workspace_root)
    
    print("🐧 WSL DOCKER MANAGER - CLEAN ARCHITECTURE")
    print("=" * 55)
    
    try:
        # Gerar script de startup
        script_path = manager.generate_startup_script()
        
        # Executar inicialização completa
        success = manager.complete_startup_sequence("scalable")
        
        if success:
            print(f"\n💡 Para futuras inicializações:")
            print(f"   wsl -d Ubuntu bash {manager.convert_windows_path_to_wsl(script_path)}")
            print(f"\n🔧 Comandos úteis:")
            print(f"   • Status: wsl -d Ubuntu docker ps")
            print(f"   • Logs: wsl -d Ubuntu docker-compose logs")
            print(f"   • Parar: wsl -d Ubuntu docker-compose down")
        
        return 0 if success else 1
        
    except Exception as e:
        print(f"\n❌ Erro durante inicialização: {e}")
        return 1

if __name__ == "__main__":
    exit(main())
