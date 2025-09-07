#!/usr/bin/env python3
"""
Real Environment Performance Tester for Both Branches
Tests each branch in separate Docker environments
"""

import subprocess
import time
import json
import requests
import statistics
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed
import os
import sys

class BranchPerformanceTester:
    """Testa performance real de ambas as branches em ambiente Linux"""
    
    def __init__(self):
        self.base_path = "/mnt/c/workspace/estudosKBNT_Kafka_Logs"
        self.results = {}
        self.endpoints = {
            'api-gateway': 'http://localhost:8080',
            'log-analytics': 'http://localhost:8083', 
            'log-consumer': 'http://localhost:8084',
            'stock-consumer': 'http://localhost:8085',
            'log-producer': 'http://localhost:8086',
            'virtual-stock': 'http://localhost:8087'
        }
        
    def run_wsl_command(self, command, capture_output=True):
        """Executa comando no WSL Ubuntu"""
        try:
            full_command = f'wsl -d Ubuntu -- bash -c "cd {self.base_path} && {command}"'
            print(f"🔧 Executando: {command}")
            
            result = subprocess.run(
                full_command,
                shell=True,
                capture_output=capture_output,
                text=True,
                timeout=300
            )
            
            if result.returncode == 0:
                return result.stdout.strip() if capture_output else "Success"
            else:
                print(f"❌ Erro: {result.stderr}")
                return None
                
        except subprocess.TimeoutExpired:
            print(f"⏰ Timeout ao executar: {command}")
            return None
        except Exception as e:
            print(f"💥 Exceção: {e}")
            return None
    
    def switch_branch_and_rebuild(self, branch_name):
        """Troca de branch e reconstrói ambiente"""
        print(f"\n🔄 Preparando ambiente para branch: {branch_name}")
        
        # 1. Parar containers atuais
        print("⏹️ Parando containers...")
        self.run_wsl_command("docker-compose -f 05-microservices/docker-compose.yml down", False)
        time.sleep(5)
        
        # 2. Trocar branch
        print(f"🌿 Trocando para branch {branch_name}...")
        result = self.run_wsl_command(f"git checkout {branch_name}")
        if not result:
            print(f"❌ Falha ao trocar para branch {branch_name}")
            return False
            
        # 3. Rebuild containers para garantir código atualizado
        print("🔨 Fazendo rebuild dos containers...")
        result = self.run_wsl_command("docker-compose -f 05-microservices/docker-compose.yml build --no-cache", False)
        if not result:
            print("❌ Falha no build dos containers")
            return False
            
        # 4. Iniciar containers
        print("🚀 Iniciando containers...")
        result = self.run_wsl_command("docker-compose -f 05-microservices/docker-compose.yml up -d", False)
        if not result:
            print("❌ Falha ao iniciar containers")
            return False
            
        # 5. Aguardar containers ficarem prontos
        print("⏳ Aguardando containers ficarem prontos...")
        time.sleep(60)  # Tempo maior para estabilização
        
        # 6. Verificar saúde dos containers
        return self.check_containers_health()
    
    def check_containers_health(self):
        """Verifica se containers estão saudáveis"""
        print("🏥 Verificando saúde dos containers...")
        
        # Verificar containers rodando
        result = self.run_wsl_command("docker-compose -f 05-microservices/docker-compose.yml ps")
        if not result:
            return False
            
        print("📋 Status dos containers:")
        print(result)
        
        # Testar conectividade básica
        for name, url in self.endpoints.items():
            try:
                response = requests.get(f"{url}/health", timeout=5)
                print(f"✅ {name}: {response.status_code}")
            except:
                try:
                    # Tenta endpoint raiz se health não existir
                    response = requests.get(url, timeout=5)
                    print(f"⚠️ {name}: {response.status_code} (no health endpoint)")
                except Exception as e:
                    print(f"❌ {name}: Não acessível - {e}")
        
        return True
    
    def discover_working_endpoints(self):
        """Descobre endpoints que estão funcionando"""
        working_endpoints = []
        
        print("🔍 Descobrindo endpoints funcionais...")
        
        # Testa endpoints principais
        test_endpoints = [
            "http://localhost:8080/",
            "http://localhost:8080/api/health",
            "http://localhost:8080/actuator/health",
            "http://localhost:8083/",
            "http://localhost:8083/api/logs",
            "http://localhost:8084/",
            "http://localhost:8085/",
            "http://localhost:8086/",
            "http://localhost:8087/"
        ]
        
        for endpoint in test_endpoints:
            try:
                response = requests.get(endpoint, timeout=3)
                if response.status_code in [200, 404, 405]:  # 404/405 significa serviço vivo
                    working_endpoints.append(endpoint)
                    print(f"✅ {endpoint}: {response.status_code}")
            except:
                print(f"❌ {endpoint}: Não acessível")
        
        return working_endpoints
    
    def perform_load_test(self, endpoint, num_requests=1000, max_workers=10):
        """Executa teste de carga em um endpoint"""
        print(f"🎯 Testando {endpoint} com {num_requests} requisições...")
        
        results = {
            'successful_requests': 0,
            'failed_requests': 0,
            'latencies': [],
            'errors': [],
            'start_time': time.time()
        }
        
        def make_request():
            try:
                start = time.time()
                response = requests.get(endpoint, timeout=10)
                end = time.time()
                
                latency = (end - start) * 1000  # ms
                
                if response.status_code < 500:  # Considera sucesso se não for erro de servidor
                    return {'success': True, 'latency': latency, 'status': response.status_code}
                else:
                    return {'success': False, 'error': f"HTTP {response.status_code}", 'latency': latency}
                    
            except Exception as e:
                end = time.time()
                latency = (end - start) * 1000
                return {'success': False, 'error': str(e), 'latency': latency}
        
        # Executa requisições concorrentes
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            futures = [executor.submit(make_request) for _ in range(num_requests)]
            
            for future in as_completed(futures):
                result = future.result()
                
                if result['success']:
                    results['successful_requests'] += 1
                    results['latencies'].append(result['latency'])
                else:
                    results['failed_requests'] += 1
                    results['errors'].append(result['error'])
                    # Inclui latência mesmo em falha para análise
                    if 'latency' in result:
                        results['latencies'].append(result['latency'])
        
        results['end_time'] = time.time()
        results['total_time'] = results['end_time'] - results['start_time']
        
        # Calcular métricas
        if results['latencies']:
            results['avg_latency'] = statistics.mean(results['latencies'])
            results['min_latency'] = min(results['latencies'])
            results['max_latency'] = max(results['latencies'])
            
            sorted_latencies = sorted(results['latencies'])
            n = len(sorted_latencies)
            results['p95_latency'] = sorted_latencies[int(n * 0.95)]
            results['p99_latency'] = sorted_latencies[int(n * 0.99)]
        else:
            results['avg_latency'] = 0
            results['min_latency'] = 0
            results['max_latency'] = 0
            results['p95_latency'] = 0
            results['p99_latency'] = 0
        
        results['success_rate'] = (results['successful_requests'] / num_requests) * 100
        results['throughput'] = results['successful_requests'] / results['total_time']
        
        return results
    
    def test_branch_performance(self, branch_name, num_requests=1000):
        """Testa performance de uma branch específica"""
        print(f"\n🚀 TESTANDO PERFORMANCE DA BRANCH: {branch_name}")
        print("=" * 60)
        
        # Preparar ambiente
        if not self.switch_branch_and_rebuild(branch_name):
            print(f"❌ Falha ao preparar ambiente para {branch_name}")
            return None
        
        # Descobrir endpoints funcionais
        working_endpoints = self.discover_working_endpoints()
        
        if not working_endpoints:
            print(f"❌ Nenhum endpoint funcional encontrado para {branch_name}")
            return None
        
        # Testar cada endpoint funcional
        branch_results = {
            'branch': branch_name,
            'timestamp': datetime.now().isoformat(),
            'endpoints': {},
            'summary': {}
        }
        
        all_latencies = []
        total_successful = 0
        total_failed = 0
        total_time = 0
        
        for endpoint in working_endpoints[:3]:  # Testa os 3 primeiros endpoints
            print(f"\n📊 Testando endpoint: {endpoint}")
            
            test_results = self.perform_load_test(endpoint, num_requests)
            branch_results['endpoints'][endpoint] = test_results
            
            # Acumular métricas
            all_latencies.extend(test_results['latencies'])
            total_successful += test_results['successful_requests']
            total_failed += test_results['failed_requests']
            total_time += test_results['total_time']
            
            print(f"✅ Sucesso: {test_results['successful_requests']}/{num_requests}")
            print(f"⏱️ Latência média: {test_results['avg_latency']:.2f}ms")
            print(f"🚀 Throughput: {test_results['throughput']:.2f} req/s")
        
        # Calcular métricas consolidadas
        if all_latencies:
            branch_results['summary'] = {
                'total_requests': total_successful + total_failed,
                'successful_requests': total_successful,
                'failed_requests': total_failed,
                'success_rate': (total_successful / (total_successful + total_failed)) * 100,
                'avg_latency': statistics.mean(all_latencies),
                'min_latency': min(all_latencies),
                'max_latency': max(all_latencies),
                'throughput': total_successful / total_time,
                'total_time': total_time
            }
            
            sorted_latencies = sorted(all_latencies)
            n = len(sorted_latencies)
            branch_results['summary']['p95_latency'] = sorted_latencies[int(n * 0.95)]
            branch_results['summary']['p99_latency'] = sorted_latencies[int(n * 0.99)]
        
        return branch_results
    
    def compare_branches(self):
        """Compara performance entre master e refactoring"""
        print("🎯 INICIANDO COMPARAÇÃO DE PERFORMANCE ENTRE BRANCHES")
        print("=" * 70)
        
        # Testar master
        master_results = self.test_branch_performance("master", 500)  # Menos requisições para teste rápido
        
        if not master_results:
            print("❌ Falha ao testar branch master")
            return None
        
        # Testar refactoring
        refactoring_results = self.test_branch_performance("refactoring-clean-architecture-v2.1", 500)
        
        if not refactoring_results:
            print("❌ Falha ao testar branch refactoring")
            return None
        
        # Gerar comparação
        comparison = self.generate_comparison(master_results, refactoring_results)
        
        # Salvar resultados
        self.save_results(master_results, refactoring_results, comparison)
        
        return comparison
    
    def generate_comparison(self, master_results, refactoring_results):
        """Gera comparação entre resultados"""
        master_summary = master_results['summary']
        ref_summary = refactoring_results['summary']
        
        comparison = {
            'timestamp': datetime.now().isoformat(),
            'test_type': 'Real Environment Docker Performance Test',
            'throughput': {
                'master': master_summary['throughput'],
                'refactoring': ref_summary['throughput'],
                'improvement': ((ref_summary['throughput'] - master_summary['throughput']) / master_summary['throughput']) * 100
            },
            'latency': {
                'master': master_summary['avg_latency'],
                'refactoring': ref_summary['avg_latency'],
                'improvement': ((master_summary['avg_latency'] - ref_summary['avg_latency']) / master_summary['avg_latency']) * 100
            },
            'reliability': {
                'master': master_summary['success_rate'],
                'refactoring': ref_summary['success_rate'],
                'improvement': ((ref_summary['success_rate'] - master_summary['success_rate']) / master_summary['success_rate']) * 100
            }
        }
        
        self.print_comparison(comparison)
        return comparison
    
    def print_comparison(self, comparison):
        """Imprime comparação formatada"""
        print(f"\n🏆 RESULTADO DA COMPARAÇÃO REAL")
        print("=" * 50)
        
        print(f"🚀 THROUGHPUT:")
        print(f"   Master: {comparison['throughput']['master']:.2f} req/s")
        print(f"   Refactoring: {comparison['throughput']['refactoring']:.2f} req/s")
        print(f"   Melhoria: {comparison['throughput']['improvement']:+.2f}%")
        
        print(f"\n⏱️ LATÊNCIA:")
        print(f"   Master: {comparison['latency']['master']:.2f} ms")
        print(f"   Refactoring: {comparison['latency']['refactoring']:.2f} ms")
        print(f"   Melhoria: {comparison['latency']['improvement']:+.2f}%")
        
        print(f"\n🎯 CONFIABILIDADE:")
        print(f"   Master: {comparison['reliability']['master']:.2f}%")
        print(f"   Refactoring: {comparison['reliability']['refactoring']:.2f}%")
        print(f"   Melhoria: {comparison['reliability']['improvement']:+.2f}%")
    
    def save_results(self, master_results, refactoring_results, comparison):
        """Salva resultados completos"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"real_performance_comparison_{timestamp}.json"
        
        full_results = {
            'test_info': {
                'type': 'Real Environment Docker Performance Test',
                'timestamp': datetime.now().isoformat(),
                'environment': 'WSL Ubuntu with Docker',
                'methodology': 'Separate Docker environments for each branch'
            },
            'master_results': master_results,
            'refactoring_results': refactoring_results,
            'comparison': comparison
        }
        
        with open(filename, 'w') as f:
            json.dump(full_results, f, indent=2)
        
        print(f"\n💾 Resultados salvos em: {filename}")
        return filename

def main():
    tester = BranchPerformanceTester()
    
    print("🐧 Testador de Performance Real em Ambiente Linux")
    print("Testando ambas as branches com Docker dedicado")
    print("=" * 60)
    
    comparison = tester.compare_branches()
    
    if comparison:
        print(f"\n✅ TESTE CONCLUÍDO COM SUCESSO!")
        print("Verifique os arquivos de resultado para análise detalhada.")
    else:
        print(f"\n❌ TESTE FALHOU - Verifique logs acima")

if __name__ == "__main__":
    main()
