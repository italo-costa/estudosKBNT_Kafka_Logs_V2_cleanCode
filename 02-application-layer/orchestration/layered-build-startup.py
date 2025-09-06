#!/usr/bin/env python3
"""
KBNT Kafka Logs - Build por Camadas (Clean Architecture)
Constrói e sobe cada camada da arquitetura limpa separadamente
"""

import subprocess
import time
import os
import sys
import urllib.request
import urllib.error
from pathlib import Path
import json

class LayeredApplicationBuilder:
    def __init__(self):
        self.workspace_dir = Path(__file__).parent
        self.maven_path = self.workspace_dir / "tools" / "apache-maven-3.9.6" / "bin" / "mvn.cmd"
        self.processes = []
        self.services_status = {}
        
    def log(self, message: str, level: str = "INFO"):
        """Log com timestamp"""
        timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{timestamp}] [{level}] {message}")
    
    def check_maven(self):
        """Verifica se Maven está disponível"""
        if not self.maven_path.exists():
            self.log("Maven não encontrado. Executando setup...", "WARN")
            try:
                subprocess.run([sys.executable, "setup-development-environment.py"], 
                             cwd=self.workspace_dir, check=True)
                self.log("Setup do Maven concluído", "INFO")
            except subprocess.CalledProcessError:
                self.log("Falha no setup do Maven", "ERROR")
                return False
        return True
    
    def build_layer(self, layer_name: str, layer_path: Path) -> bool:
        """Constrói uma camada específica"""
        self.log(f"🔧 Construindo {layer_name}...", "INFO")
        
        if not layer_path.exists():
            self.log(f"Camada {layer_name} não encontrada em {layer_path}", "WARN")
            return False
        
        # Verificar se há projetos Maven na camada
        maven_projects = list(layer_path.rglob("pom.xml"))
        
        if not maven_projects:
            self.log(f"Nenhum projeto Maven encontrado em {layer_name}", "INFO")
            return True
        
        success_count = 0
        for pom_file in maven_projects:
            project_dir = pom_file.parent
            project_name = project_dir.name
            
            self.log(f"  📦 Construindo {project_name}...", "INFO")
            
            try:
                result = subprocess.run(
                    [str(self.maven_path), "clean", "compile", "-q"],
                    cwd=project_dir,
                    capture_output=True,
                    text=True,
                    timeout=300
                )
                
                if result.returncode == 0:
                    self.log(f"  ✅ {project_name} construído com sucesso", "INFO")
                    success_count += 1
                else:
                    self.log(f"  ❌ Falha ao construir {project_name}", "ERROR")
                    self.log(f"     Erro: {result.stderr}", "ERROR")
                    
            except subprocess.TimeoutExpired:
                self.log(f"  ⏰ Timeout ao construir {project_name}", "ERROR")
            except Exception as e:
                self.log(f"  ❌ Erro inesperado ao construir {project_name}: {e}", "ERROR")
        
        if success_count == len(maven_projects):
            self.log(f"✅ {layer_name} construída com sucesso ({success_count}/{len(maven_projects)} projetos)", "INFO")
            return True
        else:
            self.log(f"⚠️ {layer_name} construída parcialmente ({success_count}/{len(maven_projects)} projetos)", "WARN")
            return success_count > 0
    
    def start_microservice(self, service_name: str, service_dir: Path, port: int) -> bool:
        """Inicia um microserviço específico"""
        self.log(f"🚀 Iniciando {service_name} na porta {port}...", "INFO")
        
        if not service_dir.exists():
            self.log(f"Diretório do serviço {service_name} não encontrado", "ERROR")
            return False
        
        pom_file = service_dir / "pom.xml"
        if not pom_file.exists():
            self.log(f"pom.xml não encontrado para {service_name}", "ERROR")
            return False
        
        try:
            # Configurar ambiente
            env = os.environ.copy()
            env["SERVER_PORT"] = str(port)
            env["SPRING_PROFILES_ACTIVE"] = "local"
            
            # Comando para iniciar o serviço
            cmd = [
                str(self.maven_path),
                "spring-boot:run",
                f"-Dspring-boot.run.arguments=--server.port={port}",
                "-Dspring-boot.run.fork=false",
                "-q"
            ]
            
            # Iniciar processo em background
            process = subprocess.Popen(
                cmd,
                cwd=service_dir,
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True
            )
            
            self.processes.append({
                "name": service_name,
                "process": process,
                "port": port
            })
            
            # Aguardar inicialização
            self.log(f"  ⏳ Aguardando {service_name} inicializar...", "INFO")
            time.sleep(10)
            
            # Verificar se o serviço está saudável
            return self.check_service_health(service_name, port)
            
        except Exception as e:
            self.log(f"❌ Erro ao iniciar {service_name}: {e}", "ERROR")
            return False
    
    def check_service_health(self, service_name: str, port: int, max_retries: int = 6) -> bool:
        """Verifica saúde do serviço"""
        health_url = f"http://localhost:{port}/actuator/health"
        
        for attempt in range(max_retries):
            try:
                with urllib.request.urlopen(health_url, timeout=5) as response:
                    if response.getcode() == 200:
                        self.log(f"  ✅ {service_name} está saudável na porta {port}", "INFO")
                        self.services_status[service_name] = {
                            "status": "running",
                            "port": port,
                            "health": "ok"
                        }
                        return True
            except (urllib.error.URLError, urllib.error.HTTPError) as e:
                pass
            
            self.log(f"  ⏳ {service_name} ainda não está pronto (tentativa {attempt + 1}/{max_retries})", "INFO")
            time.sleep(5)
        
        self.log(f"  ❌ {service_name} falhou no health check", "ERROR")
        self.services_status[service_name] = {
            "status": "failed",
            "port": port,
            "health": "failed"
        }
        return False
    
    def build_all_layers(self):
        """Constrói todas as camadas"""
        self.log("🎯 KBNT Kafka Logs - Build por Camadas", "INFO")
        self.log("=" * 60, "INFO")
        
        if not self.check_maven():
            return False
        
        # Definir ordem das camadas (de dentro para fora)
        layers = [
            ("03-domain-layer", "Camada de Domínio"),
            ("02-application-layer", "Camada de Aplicação"),
            ("04-infrastructure-layer", "Camada de Infraestrutura"), 
            ("01-presentation-layer", "Camada de Apresentação"),
            ("05-microservices", "Microserviços")
        ]
        
        success_count = 0
        
        for layer_dir, layer_name in layers:
            layer_path = self.workspace_dir / layer_dir
            
            self.log(f"\n🔧 === Construindo {layer_name} ===", "INFO")
            
            if self.build_layer(layer_name, layer_path):
                success_count += 1
                self.log(f"✅ {layer_name} concluída com sucesso\n", "INFO")
            else:
                self.log(f"⚠️ {layer_name} teve problemas na construção\n", "WARN")
        
        self.log("=" * 60, "INFO")
        self.log(f"📊 Build concluído: {success_count}/{len(layers)} camadas", "INFO")
        
        return success_count > 0
    
    def start_layered_services(self):
        """Inicia serviços por camada"""
        self.log("\n🚀 === Iniciando Aplicação por Camadas ===", "INFO")
        
        # Ordem de inicialização (infraestrutura primeiro)
        services = [
            # Camada de Infraestrutura
            ("api-gateway", "05-microservices/api-gateway", 8080),
            
            # Camada de Aplicação/Domínio
            ("virtual-stock-service", "05-microservices/virtual-stock-service", 8081),
            ("log-producer-service", "05-microservices/log-producer-service", 8082),
            ("kbnt-log-service", "05-microservices/kbnt-log-service", 8083),
        ]
        
        successful_services = []
        
        for service_name, service_path, port in services:
            service_dir = self.workspace_dir / service_path
            
            self.log(f"\n🔧 === Camada: {service_name} ===", "INFO")
            
            if self.start_microservice(service_name, service_dir, port):
                successful_services.append((service_name, port))
                self.log(f"✅ {service_name} iniciado com sucesso na porta {port}", "INFO")
                
                # Aguardar entre serviços para estabilização
                time.sleep(5)
            else:
                self.log(f"❌ Falha ao iniciar {service_name}", "ERROR")
        
        return successful_services
    
    def generate_status_report(self, successful_services):
        """Gera relatório de status"""
        self.log("\n" + "=" * 60, "INFO")
        self.log("📊 RELATÓRIO DE STATUS DA APLICAÇÃO", "INFO")
        self.log("=" * 60, "INFO")
        
        if successful_services:
            self.log("✅ Serviços em execução:", "INFO")
            for service_name, port in successful_services:
                self.log(f"   • {service_name}: http://localhost:{port}", "INFO")
                
                # Endpoints específicos por serviço
                if service_name == "api-gateway":
                    self.log(f"     - Health: http://localhost:{port}/actuator/health", "INFO")
                    self.log(f"     - Routes: http://localhost:{port}/actuator/gateway/routes", "INFO")
        
        # Salvar relatório em JSON
        timestamp = time.strftime("%Y%m%d_%H%M%S")
        report = {
            "timestamp": timestamp,
            "services": self.services_status,
            "successful_services": len(successful_services),
            "total_attempted": len(self.services_status)
        }
        
        report_file = f"layered_build_report_{timestamp}.json"
        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2)
        
        self.log(f"\n📄 Relatório salvo: {report_file}", "INFO")
        
        return len(successful_services) > 0
    
    def stop_all_services(self):
        """Para todos os serviços"""
        self.log("\n🛑 Parando todos os serviços...", "INFO")
        
        for service_info in self.processes:
            try:
                service_name = service_info["name"]
                process = service_info["process"]
                
                self.log(f"  🛑 Parando {service_name}...", "INFO")
                process.terminate()
                
                # Aguardar término gracioso
                try:
                    process.wait(timeout=10)
                    self.log(f"  ✅ {service_name} parado", "INFO")
                except subprocess.TimeoutExpired:
                    self.log(f"  ⚡ Forçando parada de {service_name}...", "WARN")
                    process.kill()
                    
            except Exception as e:
                self.log(f"  ❌ Erro ao parar serviço: {e}", "ERROR")
        
        self.log("✅ Todos os serviços foram parados", "INFO")

def main():
    builder = LayeredApplicationBuilder()
    
    try:
        # Fase 1: Build das camadas
        if not builder.build_all_layers():
            builder.log("❌ Falha no build das camadas", "ERROR")
            return False
        
        # Fase 2: Inicialização dos serviços
        successful_services = builder.start_layered_services()
        
        # Fase 3: Relatório de status
        if builder.generate_status_report(successful_services):
            builder.log("\n🎯 Aplicação iniciada com sucesso!", "INFO")
            builder.log("💡 Use Ctrl+C para parar todos os serviços", "INFO")
            
            # Manter rodando
            try:
                while True:
                    time.sleep(5)
            except KeyboardInterrupt:
                builder.log("\n🛑 Shutdown solicitado pelo usuário...", "INFO")
        else:
            builder.log("❌ Nenhum serviço foi iniciado com sucesso", "ERROR")
            return False
            
    except KeyboardInterrupt:
        builder.log("\n🛑 Interrompido pelo usuário", "INFO")
    except Exception as e:
        builder.log(f"❌ Erro inesperado: {e}", "ERROR")
    finally:
        builder.stop_all_services()
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
