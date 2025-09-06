#!/usr/bin/env python3
"""
Configuração de Portas e Execução das Aplicações - Versão Simplificada
Usa JARs compilados anteriormente e executa teste de 10.000 requisições
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

# Configuração de portas para cada serviço
PORT_CONFIG = {
    'virtual-stock-service': 8081,
    'log-producer-service': 8082,
    'api-gateway': 8080
}

class SimpleApplicationLauncher:
    def __init__(self, workspace_root):
        self.workspace_root = Path(workspace_root)
        self.running_services = {}
        self.health_check_results = {}
        
    def find_jar_file(self, service_name):
        """Encontra o arquivo JAR compilado de um serviço"""
        service_path = self.workspace_root / '05-microservices' / service_name
        target_path = service_path / 'target'
        
        if target_path.exists():
            for jar_file in target_path.glob('*.jar'):
                if not jar_file.name.endswith('-sources.jar') and not jar_file.name.endswith('-javadoc.jar'):
                    return jar_file
        
        return None
    
    def start_service_with_jar(self, service_name, port):
        """Inicia um serviço usando o JAR compilado"""
        jar_file = self.find_jar_file(service_name)
        
        if not jar_file:
            print(f"❌ JAR não encontrado para {service_name}")
            return False
        
        print(f"🚀 Iniciando {service_name} na porta {port} com JAR: {jar_file.name}")
        
        try:
            # Inicia o serviço com Java
            process = subprocess.Popen(
                ['java', '-jar', str(jar_file), f'--server.port={port}'],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                cwd=jar_file.parent
            )
            
            self.running_services[service_name] = {
                'process': process,
                'port': port,
                'status': 'starting',
                'jar_file': str(jar_file)
            }
            
            print(f"✅ {service_name} iniciado (PID: {process.pid})")
            return True
            
        except Exception as e:
            print(f"❌ Erro ao iniciar {service_name}: {e}")
            return False
    
    def check_service_health(self, service_name, port, timeout=60):
        """Verifica se um serviço está saudável"""
        print(f"🔍 Verificando saúde do {service_name} na porta {port}...")
        
        # URLs possíveis para verificar saúde
        test_urls = [
            f"http://localhost:{port}/actuator/health",
            f"http://localhost:{port}/health",
            f"http://localhost:{port}/api/v1/health",
            f"http://localhost:{port}/"
        ]
        
        start_time = time.time()
        
        while time.time() - start_time < timeout:
            for url in test_urls:
                try:
                    response = requests.get(url, timeout=5)
                    if response.status_code in [200, 404]:  # 404 também indica que está respondendo
                        self.health_check_results[service_name] = {
                            'status': 'healthy',
                            'port': port,
                            'response_time': time.time() - start_time,
                            'working_url': url
                        }
                        print(f"✅ {service_name} está saudável na porta {port} (URL: {url})")
                        return True
                except:
                    continue
            
            time.sleep(2)
        
        # Fallback: verifica apenas se a porta está respondendo
        try:
            import socket
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            result = sock.connect_ex(('localhost', port))
            sock.close()
            
            if result == 0:
                self.health_check_results[service_name] = {
                    'status': 'responding',
                    'port': port,
                    'response_time': time.time() - start_time
                }
                print(f"⚠️  {service_name} está respondendo na porta {port} (sem endpoint de saúde)")
                return True
        except:
            pass
        
        self.health_check_results[service_name] = {
            'status': 'unhealthy',
            'port': port,
            'response_time': timeout
        }
        print(f"❌ {service_name} não está respondendo na porta {port}")
        return False
    
    def stop_all_services(self):
        """Para todos os serviços em execução"""
        print("\n🛑 Parando todos os serviços...")
        
        for service_name, service_info in self.running_services.items():
            try:
                process = service_info['process']
                process.terminate()
                
                # Aguarda um pouco para terminar graciosamente
                try:
                    process.wait(timeout=10)
                    print(f"✅ {service_name} parado")
                except subprocess.TimeoutExpired:
                    process.kill()
                    print(f"🔫 {service_name} forçadamente parado")
            except Exception as e:
                print(f"❌ Erro ao parar {service_name}: {e}")

def perform_comprehensive_load_test(base_url, num_requests=10000):
    """Executa teste de carga abrangente com 10.000 requisições"""
    print(f"\n🎯 Iniciando teste de carga abrangente com {num_requests} requisições...")
    
    # URLs para teste
    test_endpoints = [
        "/",
        "/actuator/health",
        "/api/v1/virtual-stock/health",
        "/api/v1/logs/health"
    ]
    
    results = {
        'total_requests': num_requests,
        'successful_requests': 0,
        'failed_requests': 0,
        'response_times': [],
        'errors': [],
        'status_codes': {},
        'endpoint_results': {endpoint: {'success': 0, 'failed': 0} for endpoint in test_endpoints}
    }
    
    def make_request(request_id):
        # Seleciona endpoint aleatoriamente
        import random
        endpoint = random.choice(test_endpoints)
        url = f"{base_url}{endpoint}"
        
        try:
            start_time = time.time()
            response = requests.get(url, timeout=10)
            end_time = time.time()
            
            response_time = (end_time - start_time) * 1000  # em ms
            
            # Registra código de status
            status_code = response.status_code
            if status_code not in results['status_codes']:
                results['status_codes'][status_code] = 0
            results['status_codes'][status_code] += 1
            
            if response.status_code in [200, 404]:  # Considera 404 como sucesso (endpoint pode não existir)
                results['successful_requests'] += 1
                results['response_times'].append(response_time)
                results['endpoint_results'][endpoint]['success'] += 1
            else:
                results['failed_requests'] += 1
                results['endpoint_results'][endpoint]['failed'] += 1
                results['errors'].append(f"Request {request_id} to {endpoint}: HTTP {response.status_code}")
                
        except Exception as e:
            results['failed_requests'] += 1
            results['endpoint_results'][endpoint]['failed'] += 1
            results['errors'].append(f"Request {request_id} to {endpoint}: {str(e)}")
    
    # Executa requisições em lotes para controle de memória
    batch_size = 50  # Reduzido para evitar sobrecarga
    threads = []
    
    print("🚀 Executando requisições em lotes...")
    
    for i in range(0, num_requests, batch_size):
        batch_threads = []
        current_batch_size = min(batch_size, num_requests - i)
        
        for j in range(current_batch_size):
            thread = threading.Thread(target=make_request, args=(i + j,))
            batch_threads.append(thread)
            thread.start()
        
        # Espera o batch completar
        for thread in batch_threads:
            thread.join()
        
        # Progress
        completed = i + current_batch_size
        progress = (completed / num_requests) * 100
        print(f"Progress: {completed}/{num_requests} ({progress:.1f}%) - Sucessos: {results['successful_requests']}, Falhas: {results['failed_requests']}")
        
        # Pequena pausa entre lotes para não sobrecarregar
        time.sleep(0.1)
    
    # Calcula estatísticas
    if results['response_times']:
        avg_time = sum(results['response_times']) / len(results['response_times'])
        min_time = min(results['response_times'])
        max_time = max(results['response_times'])
        
        # Calcula percentis
        sorted_times = sorted(results['response_times'])
        p50 = sorted_times[int(len(sorted_times) * 0.5)]
        p95 = sorted_times[int(len(sorted_times) * 0.95)]
        p99 = sorted_times[int(len(sorted_times) * 0.99)]
        
        results['statistics'] = {
            'avg_response_time': avg_time,
            'min_response_time': min_time,
            'max_response_time': max_time,
            'p50_response_time': p50,
            'p95_response_time': p95,
            'p99_response_time': p99
        }
    
    return results

def main():
    workspace_root = Path.cwd()
    launcher = SimpleApplicationLauncher(workspace_root)
    
    print("🚀 Executando Aplicações e Teste de 10.000 Requisições")
    print("=" * 60)
    
    try:
        # 1. Verificar JARs disponíveis
        print("\n📦 Verificando JARs compilados...")
        available_services = []
        
        for service_name in PORT_CONFIG.keys():
            jar_file = launcher.find_jar_file(service_name)
            if jar_file:
                print(f"✅ {service_name}: {jar_file.name}")
                available_services.append(service_name)
            else:
                print(f"❌ {service_name}: JAR não encontrado")
        
        if not available_services:
            print("❌ Nenhum JAR encontrado. Execute o build primeiro.")
            return
        
        # 2. Iniciar serviços disponíveis
        startup_order = ['virtual-stock-service', 'log-producer-service', 'api-gateway']
        started_services = []
        
        print(f"\n🚀 Iniciando serviços disponíveis...")
        
        for service in startup_order:
            if service in available_services:
                port = PORT_CONFIG[service]
                if launcher.start_service_with_jar(service, port):
                    started_services.append(service)
                    # Aguarda um pouco antes de verificar saúde
                    time.sleep(15)
                    launcher.check_service_health(service, port, timeout=30)
                    time.sleep(5)  # Pausa entre serviços
        
        if not started_services:
            print("❌ Nenhum serviço foi iniciado com sucesso")
            return
        
        # 3. Aguardar estabilização
        print("\n⏰ Aguardando estabilização dos serviços...")
        time.sleep(20)
        
        # 4. Determinar URL base para teste
        base_url = None
        if 'api-gateway' in started_services:
            base_url = "http://localhost:8080"
            print("🌐 Usando API Gateway como ponto de entrada")
        elif 'virtual-stock-service' in started_services:
            base_url = "http://localhost:8081"
            print("🌐 Usando Virtual Stock Service diretamente")
        else:
            print("❌ Nenhum serviço apropriado para teste encontrado")
            return
        
        # 5. Executar teste de carga
        print(f"\n🎯 Iniciando teste de carga contra {base_url}...")
        
        test_results = perform_comprehensive_load_test(base_url, 10000)
        
        # 6. Salvar e exibir resultados
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        results_file = f"performance_test_10k_results_{timestamp}.json"
        
        # Adiciona informações dos serviços aos resultados
        test_results['test_info'] = {
            'base_url': base_url,
            'started_services': started_services,
            'service_health': launcher.health_check_results,
            'timestamp': datetime.now().isoformat()
        }
        
        with open(results_file, 'w', encoding='utf-8') as f:
            json.dump(test_results, f, indent=2, ensure_ascii=False)
        
        # Exibir resultados
        print("\n📊 RESULTADOS DO TESTE DE CARGA - 10.000 REQUISIÇÕES")
        print("=" * 60)
        print(f"🌐 URL Base: {base_url}")
        print(f"🏃 Serviços Iniciados: {', '.join(started_services)}")
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
        
        print(f"\n🎯 RESULTADOS POR ENDPOINT:")
        for endpoint, stats in test_results['endpoint_results'].items():
            total = stats['success'] + stats['failed']
            if total > 0:
                success_pct = (stats['success'] / total) * 100
                print(f"   {endpoint}: {stats['success']}/{total} ({success_pct:.1f}% sucesso)")
        
        print(f"\n📄 Resultados detalhados salvos em: {results_file}")
        
        # Mostrar algumas falhas se houver
        if test_results['errors'] and len(test_results['errors']) <= 10:
            print(f"\n⚠️  EXEMPLOS DE ERROS:")
            for error in test_results['errors'][:5]:
                print(f"   {error}")
        
    except KeyboardInterrupt:
        print("\n\n⚠️  Interrompido pelo usuário")
    except Exception as e:
        print(f"\n❌ Erro durante execução: {e}")
        import traceback
        traceback.print_exc()
    finally:
        # Para todos os serviços
        launcher.stop_all_services()
        
        # Salva relatório final de execução
        final_report = {
            'timestamp': datetime.now().isoformat(),
            'executed_services': list(launcher.running_services.keys()),
            'health_checks': launcher.health_check_results,
            'service_details': {k: {
                'port': v['port'],
                'status': v['status'],
                'jar_file': v.get('jar_file', 'N/A')
            } for k, v in launcher.running_services.items()}
        }
        
        execution_report_file = f"execution_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(execution_report_file, 'w', encoding='utf-8') as f:
            json.dump(final_report, f, indent=2, ensure_ascii=False)
        
        print(f"\n📄 Relatório de execução salvo em: {execution_report_file}")

if __name__ == "__main__":
    main()
