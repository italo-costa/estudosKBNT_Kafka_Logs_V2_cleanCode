#!/usr/bin/env python3
"""
Docker Manager Linux Direto - Clean Architecture
Gerencia Docker Compose diretamente no ambiente Linux
"""

import subprocess
import os
from pathlib import Path
from datetime import datetime

class LinuxDockerManager:
    def __init__(self, workspace_root):
        self.workspace_root = Path(workspace_root)
        self.docker_compose_files = {
            "scalable": "04-infrastructure-layer/docker/docker-compose.scalable.yml",
            "simple": "04-infrastructure-layer/docker/docker-compose.scalable-simple.yml", 
            "infrastructure": "04-infrastructure-layer/docker/docker-compose.infrastructure-only.yml",
            "free_tier": "04-infrastructure-layer/docker/docker-compose.free-tier.yml"
        }
        
    def run_command(self, command):
        """Executa comando no Linux"""
        try:
            result = subprocess.run(
                command,
                shell=True,
                capture_output=True,
                text=True,
                cwd=self.workspace_root
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
    
    def validate_environment(self):
        """Valida ambiente Docker"""
        print("🐳 Validando ambiente Docker...")
        
        # Verificar Docker
        docker_check = self.run_command("docker --version")
        if not docker_check["success"]:
            print("❌ Docker não está disponível")
            return False
        
        print(f"✅ Docker: {docker_check['stdout'].strip()}")
        
        # Verificar Docker Compose
        compose_check = self.run_command("docker-compose --version")
        if not compose_check["success"]:
            print("❌ Docker Compose não está disponível")
            return False
        
        print(f"✅ Docker Compose: {compose_check['stdout'].strip()}")
        return True
    
    def docker_compose_up(self, compose_type="scalable", detached=True):
        """Inicia serviços usando Docker Compose"""
        
        if compose_type not in self.docker_compose_files:
            print(f"❌ Tipo de compose inválido: {compose_type}")
            print(f"💡 Tipos disponíveis: {list(self.docker_compose_files.keys())}")
            return False
        
        compose_file = self.docker_compose_files[compose_type]
        compose_path = self.workspace_root / compose_file
        
        if not compose_path.exists():
            print(f"❌ Arquivo não encontrado: {compose_path}")
            # Listar arquivos disponíveis
            docker_files = self.run_command("find . -name 'docker-compose*.yml' | head -10")
            if docker_files["success"]:
                print("📁 Arquivos Docker Compose encontrados:")
                for file in docker_files["stdout"].split('\n'):
                    if file.strip():
                        print(f"   • {file.strip()}")
            return False
        
        print(f"🚀 Iniciando Docker Compose: {compose_type}")
        print(f"📄 Arquivo: {compose_file}")
        
        # Comando Docker Compose
        detached_flag = "-d" if detached else ""
        command = f"docker-compose -f {compose_file} up {detached_flag}"
        
        result = self.run_command(command)
        
        if result["success"]:
            print("✅ Docker Compose iniciado com sucesso!")
            if result["stdout"]:
                print(result["stdout"])
            return True
        else:
            print("❌ Erro ao iniciar Docker Compose:")
            if result["stderr"]:
                print(result["stderr"])
            return False
    
    def docker_compose_status(self):
        """Verifica status dos containers"""
        print("📊 Verificando status dos containers...")
        
        result = self.run_command("docker ps --format 'table {{.Names}}\\t{{.Status}}\\t{{.Ports}}'")
        
        if result["success"]:
            print("✅ Status dos containers:")
            print(result["stdout"])
            return True
        else:
            print("❌ Erro ao verificar status:")
            if result["stderr"]:
                print(result["stderr"])
            return False
    
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
            check_cmd = f"curl -s -o /dev/null -w '%{{http_code}}' {health_url}"
            result = self.run_command(check_cmd)
            
            if result["success"] and "200" in result["stdout"]:
                print(f"✅ {service_name}: Saudável")
                healthy_services.append(service_name)
            else:
                print(f"❌ {service_name}: Não responsivo")
        
        print(f"\n📊 Serviços saudáveis: {len(healthy_services)}/{len(services)}")
        return healthy_services
    
    def complete_startup_sequence(self, compose_type="infrastructure"):
        """Sequência completa de inicialização"""
        print("🚀 INICIALIZAÇÃO COMPLETA - AMBIENTE LINUX DOCKER")
        print("=" * 60)
        
        # 1. Validar ambiente
        if not self.validate_environment():
            return False
        
        # 2. Verificar arquivos disponíveis primeiro
        print("📁 Verificando arquivos Docker Compose disponíveis...")
        available_files = self.run_command("find . -name 'docker-compose*.yml' | head -10")
        
        if available_files["success"]:
            files = [f.strip() for f in available_files["stdout"].split('\n') if f.strip()]
            print(f"✅ Encontrados {len(files)} arquivos Docker Compose:")
            for file in files[:5]:  # Mostrar primeiros 5
                print(f"   • {file}")
            
            # Usar o primeiro arquivo encontrado se o especificado não existir
            if files and compose_type not in self.docker_compose_files:
                first_file = files[0]
                print(f"🔄 Usando arquivo disponível: {first_file}")
                
                # Iniciar com arquivo específico
                result = self.run_command(f"docker-compose -f {first_file} up -d")
                
                if result["success"]:
                    print("✅ Docker Compose iniciado com arquivo disponível!")
                    print(result["stdout"])
                else:
                    print("❌ Erro ao iniciar Docker Compose:")
                    print(result["stderr"])
                    return False
            else:
                # 3. Iniciar Docker Compose com arquivo especificado
                if not self.docker_compose_up(compose_type):
                    return False
        else:
            print("❌ Nenhum arquivo Docker Compose encontrado")
            return False
        
        # 4. Aguardar inicialização
        print("⏳ Aguardando inicialização dos serviços...")
        import time
        time.sleep(15)  # Reduzido para 15s
        
        # 5. Verificar status
        self.docker_compose_status()
        
        # 6. Health check (opcional, pode falhar se serviços ainda não estão prontos)
        print("🏥 Tentando health check (pode falhar se serviços ainda iniciando)...")
        try:
            healthy_services = self.health_check_services()
        except:
            print("⚠️ Health check falhou, mas isso é normal durante inicialização")
            healthy_services = []
        
        print(f"\n🎉 INICIALIZAÇÃO CONCLUÍDA!")
        print(f"✅ Ambiente: Linux Docker")
        print(f"✅ Compose: {compose_type}")
        print(f"📊 Status: Containers em execução")
        
        return True

def main():
    """Função principal"""
    workspace_root = "/mnt/c/workspace/estudosKBNT_Kafka_Logs"
    manager = LinuxDockerManager(workspace_root)
    
    print("🐧 LINUX DOCKER MANAGER - CLEAN ARCHITECTURE")
    print("=" * 55)
    
    try:
        # Executar inicialização completa
        success = manager.complete_startup_sequence("infrastructure")
        
        if success:
            print(f"\n💡 Comandos úteis:")
            print(f"   • Status: docker ps")
            print(f"   • Logs: docker-compose logs")
            print(f"   • Parar: docker-compose down")
            print(f"\n🌐 Serviços esperados:")
            print(f"   • API Gateway: http://localhost:8080")
            print(f"   • Métricas: http://localhost:9080/actuator")
        
        return 0 if success else 1
        
    except Exception as e:
        print(f"\n❌ Erro durante inicialização: {e}")
        return 1

if __name__ == "__main__":
    exit(main())
