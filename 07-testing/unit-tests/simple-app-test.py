#!/usr/bin/env python3
"""
KBNT Kafka Logs - Inicialização Simples
Inicia apenas um serviço por vez para teste e executa 1000 requisições
"""

import subprocess
import time
import sys
import urllib.request
import urllib.error
from pathlib import Path
import threading

class SimpleApplicationStarter:
    def __init__(self):
        self.workspace_dir = Path(__file__).parent
        self.maven_path = self.workspace_dir / "tools" / "apache-maven-3.9.6" / "bin" / "mvn.cmd"
        self.process = None
        
    def log(self, message: str):
        """Log com timestamp"""
        timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{timestamp}] {message}")
    
    def start_api_gateway(self):
        """Inicia apenas o API Gateway para teste"""
        self.log("🚀 Iniciando API Gateway...")
        
        service_dir = self.workspace_dir / "05-microservices" / "api-gateway"
        
        if not service_dir.exists():
            self.log("❌ Diretório do API Gateway não encontrado")
            return False
        
        try:
            # Configurar ambiente
            env = {"SERVER_PORT": "8080"}
            
            # Comando para iniciar
            cmd = [
                str(self.maven_path),
                "spring-boot:run",
                "-Dspring-boot.run.arguments=--server.port=8080"
            ]
            
            # Iniciar processo
            self.process = subprocess.Popen(
                cmd,
                cwd=service_dir,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True
            )
            
            self.log("⏳ Aguardando API Gateway inicializar...")
            
            # Monitorar logs do Spring Boot
            startup_detected = False
            timeout = 60  # 60 segundos timeout
            start_time = time.time()
            
            def monitor_logs():
                nonlocal startup_detected
                for line in iter(self.process.stdout.readline, ''):
                    if line.strip():
                        print(f"[API-Gateway] {line.strip()}")
                        
                        # Detectar inicialização bem-sucedida
                        if "Started ApiGatewayApplication" in line:
                            startup_detected = True
                            break
                        if "APPLICATION FAILED TO START" in line:
                            break
            
            # Iniciar monitoramento em thread separada
            log_thread = threading.Thread(target=monitor_logs)
            log_thread.daemon = True
            log_thread.start()
            
            # Aguardar inicialização
            while not startup_detected and (time.time() - start_time) < timeout:
                if self.process.poll() is not None:
                    self.log("❌ Processo terminou inesperadamente")
                    return False
                time.sleep(1)
            
            if startup_detected:
                self.log("✅ API Gateway iniciado com sucesso!")
                return True
            else:
                self.log("⏰ Timeout ao aguardar inicialização")
                return False
                
        except Exception as e:
            self.log(f"❌ Erro ao iniciar API Gateway: {e}")
            return False
    
    def test_api_gateway(self):
        """Testa se o API Gateway está respondendo"""
        self.log("🔍 Testando conectividade com API Gateway...")
        
        test_urls = [
            "http://localhost:8080",
            "http://localhost:8080/actuator/health",
            "http://localhost:8080/actuator"
        ]
        
        for url in test_urls:
            try:
                self.log(f"  Testando: {url}")
                with urllib.request.urlopen(url, timeout=5) as response:
                    status = response.getcode()
                    self.log(f"  ✅ {url} - Status: {status}")
                    if status == 200:
                        return url
            except Exception as e:
                self.log(f"  ❌ {url} - Erro: {e}")
        
        return None
    
    def run_performance_test(self, target_url: str):
        """Executa teste de performance simples"""
        self.log(f"🎯 Iniciando teste de performance contra {target_url}")
        
        total_requests = 1000
        successful = 0
        failed = 0
        total_time = 0
        
        start_time = time.time()
        
        for i in range(1, total_requests + 1):
            try:
                req_start = time.time()
                with urllib.request.urlopen(target_url, timeout=10) as response:
                    req_end = time.time()
                    if response.getcode() == 200:
                        successful += 1
                        total_time += (req_end - req_start)
                    else:
                        failed += 1
            except Exception as e:
                failed += 1
            
            # Progress update a cada 100 requisições
            if i % 100 == 0:
                progress = (i / total_requests) * 100
                self.log(f"📊 Progresso: {i}/{total_requests} ({progress:.1f}%) - Sucessos: {successful}, Falhas: {failed}")
        
        end_time = time.time()
        total_duration = end_time - start_time
        
        # Resultados
        self.log("\n" + "=" * 60)
        self.log("📊 RESULTADOS DO TESTE DE PERFORMANCE")
        self.log("=" * 60)
        self.log(f"Total de Requisições: {total_requests}")
        self.log(f"Sucessos: {successful}")
        self.log(f"Falhas: {failed}")
        self.log(f"Taxa de Sucesso: {(successful/total_requests)*100:.2f}%")
        self.log(f"Duração Total: {total_duration:.2f}s")
        self.log(f"Requisições/Segundo: {total_requests/total_duration:.2f} RPS")
        
        if successful > 0:
            avg_response_time = (total_time / successful) * 1000
            self.log(f"Tempo Médio de Resposta: {avg_response_time:.2f}ms")
        
        return successful > (total_requests * 0.8)  # 80% de sucesso mínimo
    
    def stop_service(self):
        """Para o serviço"""
        if self.process:
            self.log("🛑 Parando API Gateway...")
            try:
                self.process.terminate()
                self.process.wait(timeout=10)
                self.log("✅ API Gateway parado")
            except subprocess.TimeoutExpired:
                self.log("⚡ Forçando parada...")
                self.process.kill()
            except Exception as e:
                self.log(f"❌ Erro ao parar: {e}")

def main():
    starter = SimpleApplicationStarter()
    
    try:
        starter.log("🎯 KBNT Kafka Logs - Teste de Aplicação Simples")
        starter.log("=" * 60)
        
        # Fase 1: Iniciar API Gateway
        if not starter.start_api_gateway():
            starter.log("❌ Falha ao iniciar API Gateway")
            return False
        
        # Pequena pausa para estabilização
        time.sleep(5)
        
        # Fase 2: Testar conectividade
        target_url = starter.test_api_gateway()
        if not target_url:
            starter.log("❌ API Gateway não está respondendo")
            return False
        
        # Fase 3: Executar teste de performance
        success = starter.run_performance_test(target_url)
        
        if success:
            starter.log("\n🎉 Teste concluído com sucesso!")
            starter.log("💡 Pressione Ctrl+C para finalizar")
            
            # Manter rodando para observação
            try:
                while True:
                    time.sleep(5)
            except KeyboardInterrupt:
                starter.log("\n🛑 Finalizando...")
        else:
            starter.log("\n⚠️ Teste concluído com problemas")
            
        return success
        
    except KeyboardInterrupt:
        starter.log("\n🛑 Interrompido pelo usuário")
        return True
    except Exception as e:
        starter.log(f"❌ Erro inesperado: {e}")
        return False
    finally:
        starter.stop_service()

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
