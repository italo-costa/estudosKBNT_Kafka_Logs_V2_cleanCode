#!/usr/bin/env python3
"""
KBNT Kafka Logs - Setup Development Environment
Configura ambiente completo para desenvolvimento em Windows
"""

import os
import sys
import subprocess
import platform
import zipfile
import urllib.request
from pathlib import Path

class DevEnvironmentSetup:
    def __init__(self):
        self.workspace_dir = Path.cwd()
        self.tools_dir = self.workspace_dir / "tools"
        self.tools_dir.mkdir(exist_ok=True)
        
    def setup_maven(self):
        """Setup do Maven para Windows"""
        print("🔧 Setting up Apache Maven...")
        
        maven_version = "3.9.6"
        maven_dir = self.tools_dir / f"apache-maven-{maven_version}"
        
        if maven_dir.exists():
            print(f"✅ Maven already installed at {maven_dir}")
            return str(maven_dir / "bin")
        
        # Download Maven
        maven_url = f"https://archive.apache.org/dist/maven/maven-3/{maven_version}/binaries/apache-maven-{maven_version}-bin.zip"
        maven_zip = self.tools_dir / f"apache-maven-{maven_version}-bin.zip"
        
        print(f"📥 Downloading Maven {maven_version}...")
        try:
            urllib.request.urlretrieve(maven_url, maven_zip)
            print(f"✅ Downloaded to {maven_zip}")
            
            # Extract Maven
            print("📦 Extracting Maven...")
            with zipfile.ZipFile(maven_zip, 'r') as zip_ref:
                zip_ref.extractall(self.tools_dir)
            
            # Remove zip file
            maven_zip.unlink()
            
            print(f"✅ Maven installed at {maven_dir}")
            return str(maven_dir / "bin")
            
        except Exception as e:
            print(f"❌ Failed to setup Maven: {e}")
            return None
    
    def check_kafka(self):
        """Verifica se Kafka está rodando"""
        print("🔍 Checking Kafka availability...")
        
        # Tentar conectar no Kafka local
        try:
            import socket
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(3)
            result = sock.connect_ex(('localhost', 9092))
            sock.close()
            
            if result == 0:
                print("✅ Kafka is running on localhost:9092")
                return True
            else:
                print("⚠️  Kafka is not running on localhost:9092")
                return False
        except Exception as e:
            print(f"⚠️  Cannot check Kafka: {e}")
            return False
    
    def start_embedded_kafka(self):
        """Inicia Kafka embedded para testes"""
        print("🚀 Starting embedded Kafka for testing...")
        
        # Script simples para simular Kafka (mock)
        kafka_script = """
import socket
import threading
import time

class MockKafkaServer:
    def __init__(self, port=9092):
        self.port = port
        self.running = False
        
    def start(self):
        self.running = True
        server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server.bind(('localhost', self.port))
        server.listen(5)
        
        print(f"Target Kafka server listening on localhost:{self.port}")
        
        while self.running:
            try:
                client, addr = server.accept()
                print(f"Connection from {addr}")
                client.send(b"Kafka-like server\\n")
                client.close()
            except:
                break
                
        server.close()

if __name__ == "__main__":
    server = MockKafkaServer()
    try:
        server.start()
    except KeyboardInterrupt:
        print("\\nStopping mock Kafka server...")
        server.running = False
"""
        
        mock_kafka_file = self.tools_dir / "mock_kafka.py"
        with open(mock_kafka_file, 'w', encoding='utf-8') as f:
            f.write(kafka_script)
        
        print("📝 Created mock Kafka server script")
        return str(mock_kafka_file)
    
    def build_microservice(self, service_path, maven_bin):
        """Build de um microserviço específico"""
        print(f"🏗️ Building microservice: {service_path.name}")
        
        os.chdir(service_path)
        
        try:
            # Usar Maven local para build
            mvn_cmd = f'"{maven_bin}\\mvn.cmd" clean package -DskipTests'
            result = subprocess.run(mvn_cmd, shell=True, capture_output=True, text=True)
            
            if result.returncode == 0:
                print(f"✅ Successfully built {service_path.name}")
                return True
            else:
                print(f"❌ Failed to build {service_path.name}")
                print(f"Error: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ Build error for {service_path.name}: {e}")
            return False
        finally:
            os.chdir(self.workspace_dir)
    
    def run_microservice(self, service_path, maven_bin):
        """Executa um microserviço"""
        print(f"🚀 Starting microservice: {service_path.name}")
        
        os.chdir(service_path)
        
        try:
            # Executar Spring Boot
            mvn_cmd = f'"{maven_bin}\\mvn.cmd" spring-boot:run'
            print(f"Executing: {mvn_cmd}")
            
            # Executar em background para não bloquear
            process = subprocess.Popen(mvn_cmd, shell=True)
            print(f"✅ Started {service_path.name} with PID {process.pid}")
            
            return process
            
        except Exception as e:
            print(f"❌ Failed to start {service_path.name}: {e}")
            return None
        finally:
            os.chdir(self.workspace_dir)
    
    def setup_complete_environment(self):
        """Setup completo do ambiente"""
        print("🎯 KBNT Kafka Logs - Development Environment Setup")
        print("=" * 60)
        
        # 1. Setup Maven
        maven_bin = self.setup_maven()
        if not maven_bin:
            print("❌ Cannot proceed without Maven")
            return False
        
        # 2. Check/Start Kafka
        if not self.check_kafka():
            mock_kafka = self.start_embedded_kafka()
            print(f"📝 Mock Kafka script created: {mock_kafka}")
            print("💡 Run this script separately to simulate Kafka")
        
        # 3. Build microservices
        microservices_dir = self.workspace_dir / "05-microservices"
        services_to_build = [
            "kbnt-log-service",
            "api-gateway",
            "virtual-stock-service"
        ]
        
        built_services = []
        for service_name in services_to_build:
            service_path = microservices_dir / service_name
            if service_path.exists() and (service_path / "pom.xml").exists():
                if self.build_microservice(service_path, maven_bin):
                    built_services.append(service_path)
        
        print(f"\\n📊 Build Summary:")
        print(f"   Successfully built: {len(built_services)} services")
        print(f"   Services ready: {[s.name for s in built_services]}")
        
        # 4. Create startup script
        self.create_startup_script(maven_bin, built_services)
        
        print("\\n🎉 Environment setup completed!")
        print("\\n📋 Next steps:")
        print("   1. Run: python tools/mock_kafka.py (in separate terminal)")
        print("   2. Run: .\\startup-microservices.ps1")
        print("   3. Test: curl http://localhost:8081/actuator/health")
        
        return True
    
    def create_startup_script(self, maven_bin, services):
        """Cria script de startup"""
        script_content = f"""# KBNT Kafka Logs - Startup Script
$MAVEN_BIN = "{maven_bin}"
$WORKSPACE = "{self.workspace_dir}"

Write-Host "🚀 Starting KBNT Kafka Logs Microservices" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green

"""
        
        for i, service in enumerate(services):
            port = 8081 + i
            script_content += f"""
# Start {service.name}
Write-Host "🔧 Starting {service.name} on port {port}..." -ForegroundColor Yellow
cd "{service}"
Start-Process powershell -ArgumentList "-NoExit", "-Command", '"$MAVEN_BIN\\mvn.cmd" spring-boot:run -Dspring-boot.run.arguments="--server.port={port}"'
Start-Sleep 3
cd "$WORKSPACE"

"""
        
        script_content += """
Write-Host "✅ All microservices started!" -ForegroundColor Green
Write-Host "🌐 Available endpoints:" -ForegroundColor Cyan
"""
        
        for i, service in enumerate(services):
            port = 8081 + i
            script_content += f'Write-Host "   {service.name}: http://localhost:{port}" -ForegroundColor White\n'
        
        startup_file = self.workspace_dir / "startup-microservices.ps1"
        with open(startup_file, 'w', encoding='utf-8') as f:
            f.write(script_content)
        
        print(f"📝 Created startup script: {startup_file}")

if __name__ == "__main__":
    setup = DevEnvironmentSetup()
    setup.setup_complete_environment()
