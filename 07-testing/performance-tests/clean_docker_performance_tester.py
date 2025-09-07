#!/usr/bin/env python3
"""
Clean Docker Performance Test
Limpa completamente ambiente e testa cada branch
"""

import subprocess
import time
import json
import requests
import statistics
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed

class CleanDockerPerformanceTester:
    """Testador com limpeza completa do Docker"""
    
    def __init__(self):
        self.base_path = "/mnt/c/workspace/estudosKBNT_Kafka_Logs"
        
    def run_wsl_command(self, command, capture_output=True):
        """Executa comando no WSL Ubuntu"""
        try:
            full_command = f'wsl -d Ubuntu -- bash -c "cd {self.base_path} && {command}"'
            print(f"🔧 {command}")
            
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
            print(f"⏰ Timeout: {command}")
            return None
        except Exception as e:
            print(f"💥 Exceção: {e}")
            return None
    
    def clean_docker_environment(self):
        """Limpa completamente o ambiente Docker"""
        print("🧹 LIMPEZA COMPLETA DO DOCKER")
        print("-" * 40)
        
        # Parar todos os containers
        print("⏹️ Parando todos os containers...")
        self.run_wsl_command("docker stop $(docker ps -aq) 2>/dev/null || true", False)
        time.sleep(3)
        
        # Remover todos os containers
        print("🗑️ Removendo todos os containers...")
        self.run_wsl_command("docker rm $(docker ps -aq) 2>/dev/null || true", False)
        time.sleep(3)
        
        # Remover todas as redes
        print("🌐 Removendo todas as redes...")
        self.run_wsl_command("docker network prune -f", False)
        time.sleep(2)
        
        # Limpar volumes órfãos
        print("💾 Limpando volumes...")
        self.run_wsl_command("docker volume prune -f", False)
        time.sleep(2)
        
        print("✅ Ambiente Docker limpo!")
    
    def build_and_start_services(self, branch_name):
        """Constrói e inicia serviços para uma branch"""
        print(f"\n🔨 CONSTRUINDO SERVIÇOS PARA: {branch_name}")
        print("-" * 50)
        
        # Checkout da branch
        print(f"🌿 Checkout para {branch_name}...")
        result = self.run_wsl_command(f"git checkout {branch_name}")
        if not result:
            print(f"❌ Falha no checkout de {branch_name}")
            return False
        
        # Descobrir docker-compose
        docker_compose_paths = [
            "05-microservices/docker-compose.yml",
            "microservices/docker-compose.yml", 
            "docker-compose.yml"
        ]
        
        docker_compose_file = None
        for path in docker_compose_paths:
            check = self.run_wsl_command(f"test -f {path} && echo 'found'")
            if check == "found":
                docker_compose_file = path
                break
        
        if not docker_compose_file:
            print("❌ Nenhum docker-compose.yml encontrado")
            return False
        
        print(f"📋 Usando: {docker_compose_file}")
        
        # Build dos serviços
        print("🔨 Building serviços...")
        result = self.run_wsl_command(f"docker-compose -f {docker_compose_file} build --parallel", False)
        if not result:
            print("⚠️ Build falhou, tentando sem --parallel...")
            result = self.run_wsl_command(f"docker-compose -f {docker_compose_file} build", False)
            if not result:
                print("❌ Build falhou completamente")
                return False
        
        # Start dos serviços
        print("🚀 Iniciando serviços...")
        result = self.run_wsl_command(f"docker-compose -f {docker_compose_file} up -d", False)
        if not result:
            print("❌ Falha ao iniciar serviços")
            return False
        
        # Aguardar containers ficarem prontos
        print("⏳ Aguardando inicialização (60s)...")
        time.sleep(60)
        
        return docker_compose_file
    
    def discover_active_endpoints(self):
        """Descobre endpoints ativos"""
        print("🔍 Descobrindo endpoints ativos...")
        
        # Verificar containers ativos
        containers_result = self.run_wsl_command("docker ps --format 'table {{.Names}}\\t{{.Ports}}'")
        if containers_result:
            print("📋 Containers ativos:")
            print(containers_result)
        
        # Testar portas comuns
        test_ports = [8080, 8081, 8082, 8083, 8084, 8085, 8086, 8087]
        active_endpoints = []
        
        for port in test_ports:
            url = f"http://localhost:{port}"
            try:
                response = requests.get(url, timeout=5)
                if response.status_code < 500:  # Qualquer resposta válida
                    active_endpoints.append(url)
                    print(f"✅ {url}: {response.status_code}")
            except:
                print(f"❌ {url}: Não acessível")
        
        return active_endpoints
    
    def run_performance_test(self, endpoints, num_requests=300):
        """Executa teste de performance nos endpoints"""
        if not endpoints:
            print("❌ Nenhum endpoint ativo para testar")
            return None
        
        print(f"\n🎯 TESTE DE PERFORMANCE")
        print(f"Endpoints: {len(endpoints)}")
        print(f"Requisições por endpoint: {num_requests}")
        print("-" * 40)
        
        all_results = []
        
        for endpoint in endpoints[:2]:  # Testa os 2 primeiros
            print(f"\n📊 Testando: {endpoint}")
            result = self.perform_load_test(endpoint, num_requests)
            all_results.append(result)
        
        return self.aggregate_results(all_results)
    
    def perform_load_test(self, endpoint, num_requests):
        """Executa teste de carga em um endpoint"""
        results = {
            'endpoint': endpoint,
            'successful_requests': 0,
            'failed_requests': 0,
            'latencies': [],
            'start_time': time.time()
        }
        
        def make_request():
            try:
                start = time.time()
                response = requests.get(endpoint, timeout=10)
                end = time.time()
                
                latency = (end - start) * 1000  # ms
                
                if response.status_code < 500:
                    return {'success': True, 'latency': latency}
                else:
                    return {'success': False, 'latency': latency}
                    
            except Exception:
                end = time.time()
                latency = (end - start) * 1000
                return {'success': False, 'latency': latency}
        
        # Teste com ThreadPoolExecutor
        with ThreadPoolExecutor(max_workers=8) as executor:
            futures = [executor.submit(make_request) for _ in range(num_requests)]
            
            for i, future in enumerate(as_completed(futures)):
                result = future.result()
                
                if result['success']:
                    results['successful_requests'] += 1
                else:
                    results['failed_requests'] += 1
                
                results['latencies'].append(result['latency'])
                
                # Progress indicator
                if (i + 1) % 50 == 0:
                    print(f"   Progresso: {i + 1}/{num_requests}")
        
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
        
        results['success_rate'] = (results['successful_requests'] / num_requests) * 100
        results['throughput'] = results['successful_requests'] / results['total_time'] if results['total_time'] > 0 else 0
        
        print(f"   ✅ Sucesso: {results['successful_requests']}/{num_requests} ({results['success_rate']:.1f}%)")
        print(f"   ⏱️ Latência: {results['avg_latency']:.2f}ms")
        print(f"   🚀 Throughput: {results['throughput']:.2f} req/s")
        
        return results
    
    def aggregate_results(self, endpoint_results):
        """Agrega resultados de múltiplos endpoints"""
        if not endpoint_results:
            return None
        
        all_latencies = []
        total_successful = 0
        total_failed = 0
        total_time = 0
        
        for result in endpoint_results:
            all_latencies.extend(result['latencies'])
            total_successful += result['successful_requests']
            total_failed += result['failed_requests']
            total_time += result['total_time']
        
        aggregated = {
            'total_requests': total_successful + total_failed,
            'successful_requests': total_successful,
            'failed_requests': total_failed,
            'success_rate': (total_successful / (total_successful + total_failed)) * 100,
            'avg_latency': statistics.mean(all_latencies) if all_latencies else 0,
            'throughput': total_successful / total_time if total_time > 0 else 0,
            'total_time': total_time,
            'endpoint_results': endpoint_results
        }
        
        if all_latencies:
            sorted_latencies = sorted(all_latencies)
            n = len(sorted_latencies)
            aggregated['p95_latency'] = sorted_latencies[int(n * 0.95)]
            aggregated['p99_latency'] = sorted_latencies[int(n * 0.99)]
        
        return aggregated
    
    def test_branch(self, branch_name):
        """Testa uma branch completa"""
        print(f"\n🚀 TESTANDO BRANCH: {branch_name}")
        print("=" * 60)
        
        # Limpar ambiente
        self.clean_docker_environment()
        
        # Build e start
        docker_compose_file = self.build_and_start_services(branch_name)
        if not docker_compose_file:
            print(f"❌ Falha ao preparar {branch_name}")
            return None
        
        # Descobrir endpoints
        endpoints = self.discover_active_endpoints()
        
        # Executar teste
        results = self.run_performance_test(endpoints, 300)
        
        if results:
            results['branch'] = branch_name
            results['timestamp'] = datetime.now().isoformat()
            results['docker_compose_file'] = docker_compose_file
        
        return results
    
    def compare_branches(self):
        """Compara performance entre branches"""
        print("🎯 COMPARAÇÃO CLEAN DOCKER PERFORMANCE")
        print("=" * 60)
        
        # Teste master
        master_results = self.test_branch("master")
        
        # Pequena pausa entre testes
        time.sleep(10)
        
        # Teste refactoring
        refactoring_results = self.test_branch("refactoring-clean-architecture-v2.1")
        
        if not master_results or not refactoring_results:
            print("❌ Um ou ambos os testes falharam")
            return None
        
        # Gerar comparação
        comparison = self.generate_comparison(master_results, refactoring_results)
        
        # Salvar resultados
        self.save_results(master_results, refactoring_results, comparison)
        
        return comparison
    
    def generate_comparison(self, master_results, refactoring_results):
        """Gera comparação entre resultados"""
        throughput_improvement = ((refactoring_results['throughput'] - master_results['throughput']) / 
                                  master_results['throughput']) * 100 if master_results['throughput'] > 0 else 0
        
        latency_improvement = ((master_results['avg_latency'] - refactoring_results['avg_latency']) / 
                              master_results['avg_latency']) * 100 if master_results['avg_latency'] > 0 else 0
        
        reliability_improvement = ((refactoring_results['success_rate'] - master_results['success_rate']) / 
                                  master_results['success_rate']) * 100 if master_results['success_rate'] > 0 else 0
        
        comparison = {
            'timestamp': datetime.now().isoformat(),
            'test_type': 'Clean Docker Performance Test',
            'throughput': {
                'master': master_results['throughput'],
                'refactoring': refactoring_results['throughput'],
                'improvement_percentage': throughput_improvement,
                'winner': 'refactoring' if refactoring_results['throughput'] > master_results['throughput'] else 'master'
            },
            'latency': {
                'master': master_results['avg_latency'],
                'refactoring': refactoring_results['avg_latency'],
                'improvement_percentage': latency_improvement,
                'winner': 'refactoring' if refactoring_results['avg_latency'] < master_results['avg_latency'] else 'master'
            },
            'reliability': {
                'master': master_results['success_rate'],
                'refactoring': refactoring_results['success_rate'],
                'improvement_percentage': reliability_improvement,
                'winner': 'refactoring' if refactoring_results['success_rate'] > master_results['success_rate'] else 'master'
            }
        }
        
        self.print_comparison(comparison)
        return comparison
    
    def print_comparison(self, comparison):
        """Imprime comparação"""
        print(f"\n🏆 RESULTADO FINAL - CLEAN DOCKER TEST")
        print("=" * 50)
        
        print(f"🚀 THROUGHPUT:")
        print(f"   Master: {comparison['throughput']['master']:.2f} req/s")
        print(f"   Refactoring: {comparison['throughput']['refactoring']:.2f} req/s")
        print(f"   Melhoria: {comparison['throughput']['improvement_percentage']:+.2f}%")
        print(f"   🏆 Vencedor: {comparison['throughput']['winner'].upper()}")
        
        print(f"\n⏱️ LATÊNCIA:")
        print(f"   Master: {comparison['latency']['master']:.2f} ms")
        print(f"   Refactoring: {comparison['latency']['refactoring']:.2f} ms")
        print(f"   Melhoria: {comparison['latency']['improvement_percentage']:+.2f}%")
        print(f"   🏆 Vencedor: {comparison['latency']['winner'].upper()}")
        
        print(f"\n🎯 CONFIABILIDADE:")
        print(f"   Master: {comparison['reliability']['master']:.2f}%")
        print(f"   Refactoring: {comparison['reliability']['refactoring']:.2f}%")
        print(f"   Melhoria: {comparison['reliability']['improvement_percentage']:+.2f}%")
        print(f"   🏆 Vencedor: {comparison['reliability']['winner'].upper()}")
        
        # Resultado final
        ref_wins = sum(1 for metric in ['throughput', 'latency', 'reliability'] 
                      if comparison[metric]['winner'] == 'refactoring')
        
        print(f"\n🏆 RESULTADO GERAL:")
        print(f"   Vitórias Refactoring: {ref_wins}/3")
        
        if ref_wins >= 2:
            print("   ✅ REFACTORING-CLEAN-ARCHITECTURE-V2.1 VENCEU!")
        else:
            print("   ✅ MASTER teve melhor performance")
    
    def save_results(self, master_results, refactoring_results, comparison):
        """Salva resultados"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"clean_docker_performance_comparison_{timestamp}.json"
        
        full_results = {
            'test_info': {
                'type': 'Clean Docker Performance Test',
                'timestamp': datetime.now().isoformat(),
                'environment': 'WSL Ubuntu with Clean Docker Environment',
                'methodology': 'Complete environment cleanup between branch tests'
            },
            'master_results': master_results,
            'refactoring_results': refactoring_results,
            'comparison': comparison
        }
        
        with open(filename, 'w') as f:
            json.dump(full_results, f, indent=2)
        
        print(f"\n💾 Resultados salvos em: {filename}")

def main():
    tester = CleanDockerPerformanceTester()
    
    print("🧹 Clean Docker Performance Tester")
    print("Ambiente limpo para cada branch")
    print("=" * 50)
    
    comparison = tester.compare_branches()
    
    if comparison:
        print("\n✅ TESTE CLEAN DOCKER CONCLUÍDO!")
    else:
        print("\n❌ TESTE FALHOU")

if __name__ == "__main__":
    main()
