#!/usr/bin/env python3
"""
Aplicação Simplificada com Port Assignment + Teste 10K
Usa apenas endpoints mock/simple sem Docker para teste de 10.000 requisições
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
from http.server import HTTPServer, BaseHTTPRequestHandler
import socketserver

class SimpleApplicationServer:
    def __init__(self, workspace_root):
        self.workspace_root = Path(workspace_root)
        self.servers = {}
        self.health_status = {}
        
    def create_mock_service(self, port, service_name):
        """Cria um serviço mock simples"""
        
        class MockServiceHandler(BaseHTTPRequestHandler):
            def do_GET(self):
                if self.path in ['/actuator/health', '/health']:
                    self.send_response(200)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    response = {
                        'status': 'UP',
                        'service': service_name,
                        'port': port,
                        'timestamp': datetime.now().isoformat()
                    }
                    self.wfile.write(json.dumps(response).encode())
                elif self.path.startswith('/api/v1/'):
                    self.send_response(200)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    response = {
                        'service': service_name,
                        'endpoint': self.path,
                        'status': 'OK',
                        'data': f"Response from {service_name}",
                        'timestamp': datetime.now().isoformat()
                    }
                    self.wfile.write(json.dumps(response).encode())
                else:
                    self.send_response(404)
                    self.end_headers()
                    
            def log_message(self, format, *args):
                pass  # Silencia logs do servidor
        
        return MockServiceHandler
    
    def start_service(self, port, service_name):
        """Inicia um serviço mock"""
        try:
            handler_class = self.create_mock_service(port, service_name)
            server = HTTPServer(('localhost', port), handler_class)
            
            def run_server():
                print(f"✅ {service_name} mock iniciado na porta {port}")
                server.serve_forever()
            
            import threading
            thread = threading.Thread(target=run_server, daemon=True)
            thread.start()
            
            self.servers[service_name] = {
                'server': server,
                'port': port,
                'thread': thread
            }
            
            # Aguarda um pouco para o servidor estabilizar
            time.sleep(1)
            
            # Verifica se está respondendo
            try:
                response = requests.get(f"http://localhost:{port}/actuator/health", timeout=2)
                if response.status_code == 200:
                    self.health_status[service_name] = 'healthy'
                    return True
            except:
                pass
            
            self.health_status[service_name] = 'unhealthy'
            return False
            
        except Exception as e:
            print(f"❌ Erro ao iniciar {service_name}: {e}")
            return False
    
    def stop_all_services(self):
        """Para todos os serviços"""
        print("🛑 Parando todos os serviços mock...")
        for service_name, service_info in self.servers.items():
            try:
                service_info['server'].shutdown()
                print(f"✅ {service_name} parado")
            except:
                pass

def perform_high_volume_load_test(base_url, num_requests=10000):
    """Executa teste de carga de alto volume com 10.000 requisições"""
    print(f"\n🎯 TESTE DE CARGA DE ALTO VOLUME - {num_requests} REQUISIÇÕES")
    print("=" * 60)
    
    # Múltiplos endpoints para simular carga real
    test_endpoints = [
        "/actuator/health",
        "/api/v1/virtual-stock/products",
        "/api/v1/virtual-stock/status",
        "/api/v1/logs/recent",
        "/api/v1/logs/status",
        "/api/v1/analytics/summary",
        "/api/v1/analytics/metrics"
    ]
    
    results = {
        'test_config': {
            'total_requests': num_requests,
            'base_url': base_url,
            'test_start': datetime.now().isoformat(),
            'endpoints': test_endpoints
        },
        'performance_metrics': {
            'successful_requests': 0,
            'failed_requests': 0,
            'response_times': [],
            'errors': [],
            'status_codes': {},
            'endpoint_performance': {ep: {'success': 0, 'failed': 0, 'total_time': 0} for ep in test_endpoints}
        }
    }
    
    # Lock para thread safety
    results_lock = threading.Lock()
    start_test_time = time.time()
    
    def execute_request(request_id):
        # Seleciona endpoint de forma balanceada
        import random
        endpoint = random.choice(test_endpoints)
        url = f"{base_url}{endpoint}"
        
        try:
            request_start = time.time()
            response = requests.get(url, timeout=10)
            request_end = time.time()
            
            response_time = (request_end - request_start) * 1000  # milliseconds
            
            with results_lock:
                # Atualiza métricas globais
                if response.status_code == 200:
                    results['performance_metrics']['successful_requests'] += 1
                    results['performance_metrics']['response_times'].append(response_time)
                    
                    # Atualiza métricas por endpoint
                    results['performance_metrics']['endpoint_performance'][endpoint]['success'] += 1
                    results['performance_metrics']['endpoint_performance'][endpoint]['total_time'] += response_time
                else:
                    results['performance_metrics']['failed_requests'] += 1
                    results['performance_metrics']['endpoint_performance'][endpoint]['failed'] += 1
                    results['performance_metrics']['errors'].append(
                        f"Request {request_id} to {endpoint}: HTTP {response.status_code}"
                    )
                
                # Registra código de status
                status_code = response.status_code
                if status_code not in results['performance_metrics']['status_codes']:
                    results['performance_metrics']['status_codes'][status_code] = 0
                results['performance_metrics']['status_codes'][status_code] += 1
                
        except Exception as e:
            with results_lock:
                results['performance_metrics']['failed_requests'] += 1
                results['performance_metrics']['endpoint_performance'][endpoint]['failed'] += 1
                results['performance_metrics']['errors'].append(
                    f"Request {request_id} to {endpoint}: {str(e)}"
                )
    
    # Execução em batches com controle de concorrência
    batch_size = 50
    max_concurrent_threads = 100
    
    print("🚀 Iniciando execução de requisições em lotes...")
    
    for batch_start in range(0, num_requests, batch_size):
        batch_end = min(batch_start + batch_size, num_requests)
        batch_threads = []
        
        # Controla número de threads concorrentes
        for i in range(batch_start, batch_end):
            thread = threading.Thread(target=execute_request, args=(i,))
            batch_threads.append(thread)
            thread.start()
            
            # Limita concorrência
            if len(batch_threads) >= max_concurrent_threads:
                for t in batch_threads:
                    t.join()
                batch_threads = []
        
        # Aguarda threads restantes do batch
        for thread in batch_threads:
            thread.join()
        
        # Relatório de progresso
        completed = batch_end
        progress = (completed / num_requests) * 100
        elapsed_time = time.time() - start_test_time
        
        with results_lock:
            current_success_rate = (results['performance_metrics']['successful_requests'] / completed) * 100
            avg_response_time = (
                sum(results['performance_metrics']['response_times']) / 
                len(results['performance_metrics']['response_times'])
            ) if results['performance_metrics']['response_times'] else 0
        
        print(f"Progress: {completed}/{num_requests} ({progress:.1f}%) | "
              f"Sucesso: {current_success_rate:.1f}% | "
              f"Tempo médio: {avg_response_time:.1f}ms | "
              f"Elapsed: {elapsed_time:.1f}s")
        
        # Pequena pausa para não sobrecarregar
        time.sleep(0.2)
    
    # Finaliza medições
    total_test_time = time.time() - start_test_time
    results['test_config']['test_end'] = datetime.now().isoformat()
    results['test_config']['total_duration_seconds'] = total_test_time
    
    # Calcula estatísticas avançadas
    if results['performance_metrics']['response_times']:
        times = sorted(results['performance_metrics']['response_times'])
        
        results['performance_metrics']['statistics'] = {
            'avg_response_time': sum(times) / len(times),
            'min_response_time': min(times),
            'max_response_time': max(times),
            'median_response_time': times[len(times) // 2],
            'p90_response_time': times[int(len(times) * 0.9)],
            'p95_response_time': times[int(len(times) * 0.95)],
            'p99_response_time': times[int(len(times) * 0.99)],
            'total_requests_per_second': num_requests / total_test_time
        }
        
        # Calcula estatísticas por endpoint
        for endpoint, metrics in results['performance_metrics']['endpoint_performance'].items():
            total_endpoint_requests = metrics['success'] + metrics['failed']
            if total_endpoint_requests > 0 and metrics['success'] > 0:
                metrics['avg_response_time'] = metrics['total_time'] / metrics['success']
                metrics['success_rate'] = (metrics['success'] / total_endpoint_requests) * 100
    
    return results

def main():
    workspace_root = Path.cwd()
    app_server = SimpleApplicationServer(workspace_root)
    
    print("🚀 APLICAÇÃO SIMPLIFICADA + TESTE DE 10.000 REQUISIÇÕES")
    print("=" * 70)
    print("📝 Usando serviços mock para simular microserviços reais")
    
    try:
        # 1. Configurar e iniciar serviços mock
        services_config = {
            'api-gateway': 8080,
            'virtual-stock-service': 8081,
            'log-producer-service': 8082,
            'log-analytics-service': 8083
        }
        
        print("\n🏗️  Iniciando serviços mock...")
        healthy_services = []
        
        for service_name, port in services_config.items():
            if app_server.start_service(port, service_name):
                healthy_services.append(service_name)
            else:
                print(f"⚠️  Falha ao iniciar {service_name}")
        
        if not healthy_services:
            print("❌ Nenhum serviço foi iniciado com sucesso")
            return
        
        print(f"✅ {len(healthy_services)} serviços iniciados: {', '.join(healthy_services)}")
        
        # 2. Aguardar estabilização
        print("\n⏰ Aguardando estabilização...")
        time.sleep(5)
        
        # 3. Executar teste de carga de alto volume
        base_url = "http://localhost:8080"
        print(f"\n🎯 Iniciando teste contra {base_url}")
        
        test_results = perform_high_volume_load_test(base_url, 10000)
        
        # 4. Salvar resultados detalhados
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        results_file = f"high_volume_test_results_{timestamp}.json"
        
        with open(results_file, 'w', encoding='utf-8') as f:
            json.dump(test_results, f, indent=2, ensure_ascii=False)
        
        # 5. Exibir relatório de resultados
        print("\n📊 RELATÓRIO DE TESTE DE ALTO VOLUME - 10.000 REQUISIÇÕES")
        print("=" * 70)
        
        config = test_results['test_config']
        metrics = test_results['performance_metrics']
        
        print(f"🕒 Duração total: {config['total_duration_seconds']:.2f} segundos")
        print(f"📊 Total de requisições: {config['total_requests']}")
        print(f"✅ Requisições bem-sucedidas: {metrics['successful_requests']}")
        print(f"❌ Requisições falhadas: {metrics['failed_requests']}")
        
        success_rate = (metrics['successful_requests'] / config['total_requests']) * 100
        print(f"📈 Taxa de sucesso geral: {success_rate:.2f}%")
        
        if 'statistics' in metrics:
            stats = metrics['statistics']
            print(f"\n⏱️  ESTATÍSTICAS DE PERFORMANCE:")
            print(f"   Requisições por segundo: {stats['total_requests_per_second']:.2f}")
            print(f"   Tempo de resposta médio: {stats['avg_response_time']:.2f}ms")
            print(f"   Tempo mínimo: {stats['min_response_time']:.2f}ms")
            print(f"   Tempo máximo: {stats['max_response_time']:.2f}ms")
            print(f"   Mediana (P50): {stats['median_response_time']:.2f}ms")
            print(f"   P90: {stats['p90_response_time']:.2f}ms")
            print(f"   P95: {stats['p95_response_time']:.2f}ms")
            print(f"   P99: {stats['p99_response_time']:.2f}ms")
        
        print(f"\n📋 CÓDIGOS DE STATUS HTTP:")
        for status_code, count in metrics['status_codes'].items():
            percentage = (count / config['total_requests']) * 100
            print(f"   HTTP {status_code}: {count} ({percentage:.1f}%)")
        
        print(f"\n🎯 PERFORMANCE POR ENDPOINT:")
        for endpoint, ep_metrics in metrics['endpoint_performance'].items():
            total = ep_metrics['success'] + ep_metrics['failed']
            if total > 0:
                avg_time = ep_metrics.get('avg_response_time', 0)
                success_pct = ep_metrics.get('success_rate', 0)
                print(f"   {endpoint}: {ep_metrics['success']}/{total} "
                      f"({success_pct:.1f}% sucesso, {avg_time:.1f}ms médio)")
        
        print(f"\n📄 Resultados detalhados salvos em: {results_file}")
        
        # 6. Avaliação de performance
        if success_rate >= 99:
            print("\n🎉 PERFORMANCE EXCEPCIONAL! Taxa de sucesso >= 99%")
        elif success_rate >= 95:
            print("\n🌟 EXCELENTE PERFORMANCE! Taxa de sucesso >= 95%")
        elif success_rate >= 90:
            print("\n👍 BOA PERFORMANCE! Taxa de sucesso >= 90%")
        elif success_rate >= 80:
            print("\n⚠️  PERFORMANCE ACEITÁVEL! Taxa de sucesso >= 80%")
        else:
            print("\n🔴 PERFORMANCE BAIXA! Requer investigação.")
        
        # Mostra alguns erros se houver
        if metrics['errors'] and len(metrics['errors']) <= 10:
            print(f"\n⚠️  EXEMPLOS DE ERROS ({len(metrics['errors'])} total):")
            for error in metrics['errors'][:5]:
                print(f"   {error}")
        
    except KeyboardInterrupt:
        print("\n\n⚠️  Teste interrompido pelo usuário")
    except Exception as e:
        print(f"\n❌ Erro durante execução: {e}")
        import traceback
        traceback.print_exc()
    finally:
        # Para todos os serviços
        app_server.stop_all_services()
        
        # Salva relatório de execução
        execution_report = {
            'timestamp': datetime.now().isoformat(),
            'execution_type': 'simple_mock_services',
            'services_started': list(app_server.servers.keys()),
            'health_status': app_server.health_status
        }
        
        execution_file = f"simple_execution_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(execution_file, 'w', encoding='utf-8') as f:
            json.dump(execution_report, f, indent=2, ensure_ascii=False)
        
        print(f"\n📄 Relatório de execução salvo em: {execution_file}")

if __name__ == "__main__":
    main()
