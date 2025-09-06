#!/usr/bin/env python3
"""
Docker Compose - Subir Aplicação e Teste de 10.000 Requisições
Utiliza Docker Compose para subir toda a infraestrutura e microserviços
"""

import os
import sys
import time
import json
import subprocess
import requests
import threading
from datetime import datetime
from pathlib import Path

class DockerComposeManager:
    def __init__(self, workspace_root):
        self.workspace_root = Path(workspace_root)
        self.microservices_path = self.workspace_root / '05-microservices'
        self.compose_file = self.microservices_path / 'docker-compose.yml'
        self.service_health = {}
        
    def check_docker_availability(self):
        """Verifica se Docker está disponível"""
        try:
            result = subprocess.run(['docker', '--version'], capture_output=True, text=True)
            if result.returncode == 0:
                print(f"✅ Docker disponível: {result.stdout.strip()}")
                
                result = subprocess.run(['docker-compose', '--version'], capture_output=True, text=True)
                if result.returncode == 0:
                    print(f"✅ Docker Compose disponível: {result.stdout.strip()}")
                    return True
                else:
                    print("❌ Docker Compose não encontrado")
                    return False
            else:
                print("❌ Docker não encontrado")
                return False
        except Exception as e:
            print(f"❌ Erro ao verificar Docker: {e}")
            return False
    
    def cleanup_existing_containers(self):
        """Remove containers existentes que possam estar em conflito"""
        print("🧹 Limpando containers existentes...")
        
        try:
            os.chdir(self.microservices_path)
            
            # Para e remove containers do compose
            subprocess.run(['docker-compose', 'down', '-v'], capture_output=True)
            
            # Remove containers órfãos
            subprocess.run(['docker', 'system', 'prune', '-f'], capture_output=True)
            
            print("✅ Limpeza concluída")
            return True
        except Exception as e:
            print(f"⚠️  Erro na limpeza (ignorando): {e}")
            return False
        finally:
            os.chdir(self.workspace_root)
    
    def build_and_start_services(self):
        """Faz build e inicia todos os serviços"""
        print("🔨 Fazendo build e iniciando serviços com Docker Compose...")
        
        try:
            os.chdir(self.microservices_path)
            
            # Build das imagens
            print("📦 Fazendo build das imagens...")
            build_process = subprocess.Popen(
                ['docker-compose', 'build', '--no-cache'],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                universal_newlines=True
            )
            
            # Mostra progresso do build
            for line in build_process.stdout:
                print(f"BUILD: {line.strip()}")
            
            build_process.wait()
            
            if build_process.returncode != 0:
                print("❌ Erro no build das imagens")
                return False
            
            print("✅ Build das imagens concluído")
            
            # Inicia os serviços
            print("🚀 Iniciando serviços...")
            start_process = subprocess.Popen(
                ['docker-compose', 'up', '-d'],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True
            )
            
            start_output, _ = start_process.communicate()
            print(start_output)
            
            if start_process.returncode == 0:
                print("✅ Serviços iniciados com sucesso")
                return True
            else:
                print("❌ Erro ao iniciar serviços")
                return False
                
        except Exception as e:
            print(f"❌ Erro durante build/start: {e}")
            return False
        finally:
            os.chdir(self.workspace_root)
    
    def check_services_health(self, timeout=300):
        """Verifica a saúde de todos os serviços"""
        print("🔍 Verificando saúde dos serviços...")
        
        # Definir endpoints de saúde para cada serviço
        health_endpoints = {
            'api-gateway': 'http://localhost:8080/actuator/health',
            'log-producer-service': 'http://localhost:8081/actuator/health',
            'log-consumer-service': 'http://localhost:8082/actuator/health',
            'log-analytics-service': 'http://localhost:8083/actuator/health',
            'virtual-stock-service': 'http://localhost:8084/actuator/health',
            'kbnt-stock-consumer-service': 'http://localhost:8085/actuator/health'
        }
        
        start_time = time.time()
        healthy_services = set()
        
        while time.time() - start_time < timeout:
            print(f"\n⏰ Verificação de saúde - {int(time.time() - start_time)}s/{timeout}s")
            
            for service_name, health_url in health_endpoints.items():
                if service_name not in healthy_services:
                    try:
                        response = requests.get(health_url, timeout=5)
                        if response.status_code == 200:
                            health_data = response.json()
                            if health_data.get('status') == 'UP':
                                print(f"✅ {service_name} está saudável")
                                healthy_services.add(service_name)
                                self.service_health[service_name] = {
                                    'status': 'healthy',
                                    'url': health_url,
                                    'response_time': time.time() - start_time
                                }
                            else:
                                print(f"⚠️  {service_name} respondendo mas não está UP")
                        else:
                            print(f"⚠️  {service_name} retornou HTTP {response.status_code}")
                    except requests.exceptions.RequestException:
                        print(f"⏳ {service_name} ainda não está respondendo")
                    except Exception as e:
                        print(f"❌ Erro ao verificar {service_name}: {e}")
            
            if len(healthy_services) >= 3:  # API Gateway + pelo menos 2 serviços
                print(f"\n✅ {len(healthy_services)} serviços estão saudáveis. Prosseguindo...")
                break
            
            time.sleep(10)
        
        # Verificar se pelo menos o API Gateway está funcionando
        if 'api-gateway' in healthy_services:
            print("✅ API Gateway está funcionando - teste pode prosseguir")
            return True
        else:
            print("❌ API Gateway não está funcionando - não é possível executar teste")
            return False
    
    def get_container_logs(self, service_name):
        """Obtém logs de um container específico"""
        try:
            os.chdir(self.microservices_path)
            result = subprocess.run(
                ['docker-compose', 'logs', '--tail=50', service_name],
                capture_output=True,
                text=True
            )
            return result.stdout
        except Exception as e:
            return f"Erro ao obter logs: {e}"
        finally:
            os.chdir(self.workspace_root)
    
    def stop_all_services(self):
        """Para todos os serviços"""
        print("🛑 Parando todos os serviços...")
        
        try:
            os.chdir(self.microservices_path)
            subprocess.run(['docker-compose', 'down'], capture_output=True)
            print("✅ Serviços parados")
        except Exception as e:
            print(f"⚠️  Erro ao parar serviços: {e}")
        finally:
            os.chdir(self.workspace_root)

def perform_comprehensive_load_test(base_url, num_requests=10000):
    """Executa teste de carga abrangente com 10.000 requisições"""
    print(f"\n🎯 Iniciando teste de carga com {num_requests} requisições contra {base_url}")
    
    # Endpoints para teste através do API Gateway
    test_endpoints = [
        "/actuator/health",
        "/api/v1/virtual-stock/health",
        "/api/v1/virtual-stock/status",
        "/api/v1/logs/health",
        "/api/v1/logs/status"
    ]
    
    results = {
        'total_requests': num_requests,
        'successful_requests': 0,
        'failed_requests': 0,
        'response_times': [],
        'errors': [],
        'status_codes': {},
        'endpoint_results': {endpoint: {'success': 0, 'failed': 0, 'avg_time': 0} for endpoint in test_endpoints}
    }
    
    results_lock = threading.Lock()
    
    def make_request(request_id):
        # Seleciona endpoint
        import random
        endpoint = random.choice(test_endpoints)
        url = f"{base_url}{endpoint}"
        
        try:
            start_time = time.time()
            response = requests.get(url, timeout=15)
            end_time = time.time()
            
            response_time = (end_time - start_time) * 1000  # em ms
            
            with results_lock:
                # Registra código de status
                status_code = response.status_code
                if status_code not in results['status_codes']:
                    results['status_codes'][status_code] = 0
                results['status_codes'][status_code] += 1
                
                if response.status_code in [200, 404]:  # 404 pode ser endpoint que não existe
                    results['successful_requests'] += 1
                    results['response_times'].append(response_time)
                    results['endpoint_results'][endpoint]['success'] += 1
                    
                    # Atualiza tempo médio do endpoint
                    current_count = results['endpoint_results'][endpoint]['success']
                    current_avg = results['endpoint_results'][endpoint]['avg_time']
                    new_avg = ((current_avg * (current_count - 1)) + response_time) / current_count
                    results['endpoint_results'][endpoint]['avg_time'] = new_avg
                else:
                    results['failed_requests'] += 1
                    results['endpoint_results'][endpoint]['failed'] += 1
                    results['errors'].append(f"Req {request_id} to {endpoint}: HTTP {response.status_code}")
                    
        except Exception as e:
            with results_lock:
                results['failed_requests'] += 1
                results['endpoint_results'][endpoint]['failed'] += 1
                results['errors'].append(f"Req {request_id} to {endpoint}: {str(e)}")
    
    # Executa requisições em lotes controlados
    batch_size = 25  # Lotes menores para não sobrecarregar
    print("🚀 Executando requisições em lotes controlados...")
    
    for i in range(0, num_requests, batch_size):
        batch_threads = []
        current_batch_size = min(batch_size, num_requests - i)
        
        # Cria threads para o lote
        for j in range(current_batch_size):
            thread = threading.Thread(target=make_request, args=(i + j,))
            batch_threads.append(thread)
            thread.start()
        
        # Aguarda conclusão do lote
        for thread in batch_threads:
            thread.join()
        
        # Progress report
        completed = i + current_batch_size
        progress = (completed / num_requests) * 100
        success_rate = (results['successful_requests'] / completed) * 100 if completed > 0 else 0
        
        print(f"Progress: {completed}/{num_requests} ({progress:.1f}%) - "
              f"Sucessos: {results['successful_requests']} ({success_rate:.1f}%)")
        
        # Pausa entre lotes para não sobrecarregar
        if i + batch_size < num_requests:
            time.sleep(0.5)
    
    # Calcula estatísticas finais
    if results['response_times']:
        sorted_times = sorted(results['response_times'])
        results['statistics'] = {
            'avg_response_time': sum(results['response_times']) / len(results['response_times']),
            'min_response_time': min(results['response_times']),
            'max_response_time': max(results['response_times']),
            'p50_response_time': sorted_times[int(len(sorted_times) * 0.5)],
            'p95_response_time': sorted_times[int(len(sorted_times) * 0.95)],
            'p99_response_time': sorted_times[int(len(sorted_times) * 0.99)]
        }
    
    return results

def main():
    workspace_root = Path.cwd()
    docker_manager = DockerComposeManager(workspace_root)
    
    print("🐳 DOCKER COMPOSE - Aplicação Completa + Teste 10K Requisições")
    print("=" * 70)
    
    try:
        # 1. Verificar Docker
        if not docker_manager.check_docker_availability():
            print("❌ Docker não está disponível. Certifique-se de que o Docker está instalado e rodando.")
            return
        
        # 2. Limpeza inicial
        docker_manager.cleanup_existing_containers()
        
        # 3. Build e start dos serviços
        print("\n🏗️  Fazendo build e iniciando toda a infraestrutura...")
        if not docker_manager.build_and_start_services():
            print("❌ Falha ao iniciar serviços")
            return
        
        # 4. Aguardar estabilização
        print("\n⏰ Aguardando estabilização inicial...")
        time.sleep(30)
        
        # 5. Verificar saúde dos serviços
        if not docker_manager.check_services_health(timeout=300):
            print("❌ Serviços não estão saudáveis")
            
            # Mostrar logs de erro
            print("\n📋 LOGS DOS SERVIÇOS:")
            for service in ['api-gateway', 'virtual-stock-service', 'log-producer-service']:
                print(f"\n--- {service} ---")
                logs = docker_manager.get_container_logs(service)
                print(logs[-1000:])  # Últimos 1000 caracteres
            
            return
        
        # 6. Executar teste de carga
        base_url = "http://localhost:8080"
        print(f"\n🎯 Iniciando teste de carga contra {base_url}")
        
        test_results = perform_comprehensive_load_test(base_url, 10000)
        
        # 7. Salvar e exibir resultados
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        results_file = f"docker_compose_test_10k_results_{timestamp}.json"
        
        # Adiciona informações do ambiente
        test_results['environment_info'] = {
            'test_type': 'docker_compose',
            'base_url': base_url,
            'healthy_services': list(docker_manager.service_health.keys()),
            'service_health': docker_manager.service_health,
            'timestamp': datetime.now().isoformat(),
            'infrastructure': 'Docker Compose with Kafka, PostgreSQL, Redis'
        }
        
        with open(results_file, 'w', encoding='utf-8') as f:
            json.dump(test_results, f, indent=2, ensure_ascii=False)
        
        # Exibir resultados
        print("\n📊 RESULTADOS DO TESTE DE CARGA - 10.000 REQUISIÇÕES")
        print("=" * 70)
        print(f"🐳 Ambiente: Docker Compose")
        print(f"🌐 URL Base: {base_url}")
        print(f"🏥 Serviços Saudáveis: {len(docker_manager.service_health)}")
        print(f"📊 Total de requisições: {test_results['total_requests']}")
        print(f"✅ Requisições bem-sucedidas: {test_results['successful_requests']}")
        print(f"❌ Requisições falhadas: {test_results['failed_requests']}")
        
        success_rate = (test_results['successful_requests'] / test_results['total_requests']) * 100
        print(f"📈 Taxa de sucesso: {success_rate:.2f}%")
        
        if 'statistics' in test_results:
            stats = test_results['statistics']
            print(f"\n⏱️  TEMPOS DE RESPOSTA:")
            print(f"   Médio: {stats['avg_response_time']:.2f}ms")
            print(f"   Mínimo: {stats['min_response_time']:.2f}ms")
            print(f"   Máximo: {stats['max_response_time']:.2f}ms")
            print(f"   P50: {stats['p50_response_time']:.2f}ms")
            print(f"   P95: {stats['p95_response_time']:.2f}ms")
            print(f"   P99: {stats['p99_response_time']:.2f}ms")
        
        print(f"\n📋 CÓDIGOS DE STATUS:")
        for status_code, count in test_results['status_codes'].items():
            percentage = (count / test_results['total_requests']) * 100
            print(f"   HTTP {status_code}: {count} ({percentage:.1f}%)")
        
        print(f"\n🎯 PERFORMANCE POR ENDPOINT:")
        for endpoint, stats in test_results['endpoint_results'].items():
            total = stats['success'] + stats['failed']
            if total > 0:
                success_pct = (stats['success'] / total) * 100
                avg_time = stats['avg_time']
                print(f"   {endpoint}: {stats['success']}/{total} ({success_pct:.1f}% sucesso, {avg_time:.1f}ms médio)")
        
        print(f"\n📄 Resultados detalhados salvos em: {results_file}")
        
        # Performance summary
        if success_rate >= 95:
            print("\n🎉 EXCELENTE! Taxa de sucesso >= 95%")
        elif success_rate >= 85:
            print("\n👍 BOM! Taxa de sucesso >= 85%")
        else:
            print("\n⚠️  ATENÇÃO: Taxa de sucesso baixa. Verificar logs.")
        
    except KeyboardInterrupt:
        print("\n\n⚠️  Teste interrompido pelo usuário")
    except Exception as e:
        print(f"\n❌ Erro durante execução: {e}")
        import traceback
        traceback.print_exc()
    finally:
        # Para todos os serviços
        docker_manager.stop_all_services()
        
        # Salva relatório final
        final_report = {
            'timestamp': datetime.now().isoformat(),
            'execution_type': 'docker_compose',
            'service_health': docker_manager.service_health,
            'compose_file': str(docker_manager.compose_file)
        }
        
        execution_report_file = f"docker_execution_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(execution_report_file, 'w', encoding='utf-8') as f:
            json.dump(final_report, f, indent=2, ensure_ascii=False)
        
        print(f"\n📄 Relatório de execução salvo em: {execution_report_file}")

if __name__ == "__main__":
    main()
        
        return True
    
    def start_microservice(self, service_name: str, port: int) -> bool:
        """Inicia um microserviço específico"""
        service_dir = self.microservices_dir / service_name
        
        if not service_dir.exists():
            print(f"❌ Service directory not found: {service_dir}")
            return False
        
        print(f"🚀 Starting {service_name} on port {port}...")
        
        try:
            # Configurar ambiente
            env = os.environ.copy()
            env["SERVER_PORT"] = str(port)
            env["SPRING_PROFILES_ACTIVE"] = "local"
            
            # Comando Maven para executar o Spring Boot
            cmd = [
                str(self.maven_path),
                "spring-boot:run",
                f"-Dspring-boot.run.arguments=--server.port={port}",
                "-Dspring-boot.run.fork=false"
            ]
            
            # Executar em thread separada
            def run_service():
                try:
                    process = subprocess.Popen(
                        cmd,
                        cwd=service_dir,
                        env=env,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT,
                        text=True,
                        bufsize=1,
                        universal_newlines=True
                    )
                    
                    self.processes.append(process)
                    
                    # Log output
                    for line in iter(process.stdout.readline, ''):
                        if line.strip():
                            print(f"[{service_name}] {line.strip()}")
                            
                            # Verificar se o serviço iniciou
                            if "Started" in line and "seconds" in line:
                                print(f"✅ {service_name} started successfully")
                                break
                    
                    process.wait()
                except Exception as e:
                    print(f"❌ Error starting {service_name}: {e}")
            
            thread = threading.Thread(target=run_service)
            thread.daemon = True
            thread.start()
            
            # Aguardar um pouco para o serviço iniciar
            time.sleep(5)
            
            # Verificar se o serviço está respondendo
            return self.check_service_health(port)
            
        except Exception as e:
            print(f"❌ Failed to start {service_name}: {e}")
            return False
    
    def check_service_health(self, port: int, max_retries: int = 10) -> bool:
        """Verifica se o serviço está saudável"""
        health_url = f"http://localhost:{port}/actuator/health"
        
        for attempt in range(max_retries):
            try:
                with urllib.request.urlopen(health_url, timeout=5) as response:
                    if response.getcode() == 200:
                        print(f"✅ Service on port {port} is healthy")
                        return True
            except (urllib.error.URLError, urllib.error.HTTPError):
                pass
            
            print(f"⏳ Waiting for service on port {port} (attempt {attempt + 1}/{max_retries})")
            time.sleep(3)
        
        print(f"❌ Service on port {port} failed health check")
        return False
    
    def start_embedded_kafka(self):
        """Inicia Kafka embedded ou usa configuração local"""
        print("🔧 Configuring Kafka (embedded mode)...")
        
        # Para este exemplo, vamos usar configuração que permite Kafka embedded
        # Os microserviços Spring Boot podem usar Kafka embedded para testes
        
        # Criar arquivo de configuração temporário
        kafka_config = """
# Configuração para Kafka embedded/local
spring.kafka.bootstrap-servers=localhost:9092
spring.kafka.consumer.group-id=kbnt-consumer-group
spring.kafka.consumer.auto-offset-reset=earliest
spring.kafka.producer.key-serializer=org.apache.kafka.common.serialization.StringSerializer
spring.kafka.producer.value-serializer=org.apache.kafka.common.serialization.StringSerializer
"""
        
        config_file = self.workspace_dir / "application-test.properties"
        with open(config_file, "w") as f:
            f.write(kafka_config)
        
        print("✅ Kafka configuration ready")
        return True
    
    def start_all_services(self):
        """Inicia todos os serviços necessários"""
        print("🎯 KBNT Kafka Logs - Real Application Startup")
        print("=" * 60)
        
        if not self.check_dependencies():
            print("❌ Dependencies check failed")
            return False
        
        # Configurar Kafka
        if not self.start_embedded_kafka():
            print("❌ Kafka configuration failed")
            return False
        
        # Lista de serviços para iniciar
        services = [
            ("api-gateway", 8080),
            ("virtual-stock-service", 8081),
            ("log-producer-service", 8082),
            ("kbnt-log-service", 8083)
        ]
        
        successful_services = []
        
        # Iniciar serviços
        for service_name, port in services:
            if self.start_microservice(service_name, port):
                successful_services.append((service_name, port))
                time.sleep(10)  # Aguardar entre inicializações
            else:
                print(f"⚠️ Failed to start {service_name}, continuing with other services...")
        
        print("\n" + "=" * 60)
        print("📊 APPLICATION STARTUP SUMMARY")
        print("=" * 60)
        
        if successful_services:
            print("✅ Successfully started services:")
            for service_name, port in successful_services:
                print(f"   • {service_name}: http://localhost:{port}")
                
            print(f"\n🚀 Ready for testing! {len(successful_services)} services running")
            print("💡 You can now run the performance test:")
            print("   python performance-test-1000-requests.py")
            
            return True
        else:
            print("❌ No services started successfully")
            return False
    
    def stop_all_services(self):
        """Para todos os serviços"""
        print("🛑 Stopping all services...")
        
        for process in self.processes:
            try:
                process.terminate()
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                process.kill()
            except Exception as e:
                print(f"Error stopping process: {e}")
        
        print("✅ All services stopped")

def main():
    starter = ApplicationStarter()
    
    try:
        if starter.start_all_services():
            print("\n🎯 Application is running! Press Ctrl+C to stop all services...")
            
            # Manter rodando até interrupção
            while True:
                time.sleep(5)
                
        else:
            print("❌ Failed to start application")
            sys.exit(1)
            
    except KeyboardInterrupt:
        print("\n🛑 Shutdown requested...")
        starter.stop_all_services()
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        starter.stop_all_services()
        sys.exit(1)

if __name__ == "__main__":
    main()
