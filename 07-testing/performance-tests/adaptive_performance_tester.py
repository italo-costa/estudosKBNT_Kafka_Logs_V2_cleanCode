#!/usr/bin/env python3
"""
Adaptive Performance Tester for Both Branches
Adapts to different file structures in each branch
"""

import subprocess
import time
import json
import requests
import statistics
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed
import os

class AdaptivePerformanceTester:
    """Testador que se adapta às estruturas de cada branch"""
    
    def __init__(self):
        self.base_path = "/mnt/c/workspace/estudosKBNT_Kafka_Logs"
        self.results = {}
        
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
    
    def discover_branch_structure(self, branch_name):
        """Descobre a estrutura de arquivos da branch"""
        print(f"🔍 Descobrindo estrutura da branch {branch_name}...")
        
        # Primeiro checkout
        result = self.run_wsl_command(f"git checkout {branch_name}")
        if not result:
            print(f"❌ Falha ao fazer checkout de {branch_name}")
            return None
        
        # Procurar por docker-compose.yml em vários locais
        possible_paths = [
            "docker-compose.yml",
            "05-microservices/docker-compose.yml",
            "microservices/docker-compose.yml",
            "06-deployment/docker-compose.yml",
            "docker/docker-compose.yml"
        ]
        
        docker_compose_path = None
        for path in possible_paths:
            check_result = self.run_wsl_command(f"test -f {path} && echo 'found'")
            if check_result == "found":
                docker_compose_path = path
                print(f"✅ Encontrado docker-compose.yml em: {path}")
                break
        
        if not docker_compose_path:
            print("❌ Nenhum docker-compose.yml encontrado")
            return None
        
        # Descobrir portas dos serviços
        compose_content = self.run_wsl_command(f"cat {docker_compose_path}")
        ports = self.extract_ports_from_compose(compose_content)
        
        structure = {
            'branch': branch_name,
            'docker_compose_path': docker_compose_path,
            'ports': ports,
            'base_endpoints': [f"http://localhost:{port}" for port in ports]
        }
        
        print(f"📋 Estrutura descoberta para {branch_name}:")
        print(f"   Docker Compose: {docker_compose_path}")
        print(f"   Portas: {ports}")
        
        return structure
    
    def extract_ports_from_compose(self, compose_content):
        """Extrai portas do docker-compose.yml"""
        ports = []
        
        if not compose_content:
            return [8080, 8083, 8084, 8085, 8086, 8087]  # Default ports
        
        # Parse simples do YAML para encontrar portas
        lines = compose_content.split('\n')
        for line in lines:
            if 'ports:' in line or '"' in line and ':' in line:
                # Procurar padrões como "8080:8080" ou - "8080:8080"
                if ':' in line and any(char.isdigit() for char in line):
                    parts = line.split(':')
                    for part in parts:
                        # Extrair números que podem ser portas
                        numbers = ''.join(c for c in part if c.isdigit())
                        if len(numbers) == 4 and numbers.startswith('80'):  # Portas 80xx
                            port = int(numbers)
                            if port not in ports and 8000 <= port <= 9000:
                                ports.append(port)
        
        # Se não encontrou portas, usar default
        if not ports:
            ports = [8080, 8083, 8084, 8085, 8086, 8087]
        
        return sorted(list(set(ports)))
    
    def prepare_branch_environment(self, structure):
        """Prepara ambiente para uma branch específica"""
        branch_name = structure['branch']
        docker_compose_path = structure['docker_compose_path']
        
        print(f"\n🔄 Preparando ambiente para {branch_name}")
        
        # 1. Parar containers existentes
        print("⏹️ Parando containers existentes...")
        self.run_wsl_command(f"docker-compose -f {docker_compose_path} down", False)
        time.sleep(5)
        
        # 2. Fazer checkout da branch
        print(f"🌿 Checkout para {branch_name}...")
        result = self.run_wsl_command(f"git checkout {branch_name}")
        if not result:
            print(f"❌ Falha no checkout de {branch_name}")
            return False
        
        # 3. Build e start dos containers
        print("🔨 Rebuilding containers...")
        result = self.run_wsl_command(f"docker-compose -f {docker_compose_path} build", False)
        if not result:
            print("⚠️ Build falhou, tentando start sem rebuild...")
        
        print("🚀 Iniciando containers...")
        result = self.run_wsl_command(f"docker-compose -f {docker_compose_path} up -d", False)
        if not result:
            print(f"❌ Falha ao iniciar containers para {branch_name}")
            return False
        
        # 4. Aguardar estabilização
        print("⏳ Aguardando estabilização (45s)...")
        time.sleep(45)
        
        return True
    
    def discover_working_endpoints(self, structure):
        """Descobre endpoints que estão funcionando"""
        working_endpoints = []
        base_endpoints = structure['base_endpoints']
        
        print("🔍 Descobrindo endpoints funcionais...")
        
        # Testar endpoints base e variações
        test_paths = ['/', '/health', '/actuator/health', '/api/health', '/status']
        
        for base_url in base_endpoints[:4]:  # Testa primeiras 4 portas
            for path in test_paths:
                endpoint = f"{base_url}{path}"
                try:
                    response = requests.get(endpoint, timeout=3)
                    if response.status_code in [200, 404, 405]:  # Considera vivo
                        working_endpoints.append(endpoint)
                        print(f"✅ {endpoint}: {response.status_code}")
                        break  # Para na primeira URL que funciona para essa porta
                except:
                    continue
        
        if not working_endpoints:
            print("⚠️ Nenhum endpoint respondeu, usando endpoints base para teste de conectividade...")
            working_endpoints = base_endpoints[:3]  # Usa primeiros 3 como fallback
        
        print(f"📋 Endpoints para teste: {working_endpoints}")
        return working_endpoints
    
    def perform_load_test(self, endpoint, num_requests=500, max_workers=5):
        """Executa teste de carga simplificado"""
        print(f"🎯 Testando {endpoint} com {num_requests} requisições...")
        
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
                response = requests.get(endpoint, timeout=15)
                end = time.time()
                
                latency = (end - start) * 1000  # ms
                
                # Considera sucesso qualquer resposta (até 500 para medir conectividade)
                if response.status_code < 500:
                    return {'success': True, 'latency': latency}
                else:
                    return {'success': False, 'latency': latency}
                    
            except Exception as e:
                end = time.time()
                latency = (end - start) * 1000
                return {'success': False, 'latency': latency}
        
        # Executa requisições com menor concorrência
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            futures = [executor.submit(make_request) for _ in range(num_requests)]
            
            for future in as_completed(futures):
                result = future.result()
                
                if result['success']:
                    results['successful_requests'] += 1
                else:
                    results['failed_requests'] += 1
                
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
            results['p95_latency'] = sorted_latencies[int(n * 0.95)] if n > 0 else 0
            results['p99_latency'] = sorted_latencies[int(n * 0.99)] if n > 0 else 0
        else:
            results['avg_latency'] = 0
            results['min_latency'] = 0
            results['max_latency'] = 0
            results['p95_latency'] = 0
            results['p99_latency'] = 0
        
        results['success_rate'] = (results['successful_requests'] / num_requests) * 100
        results['throughput'] = results['successful_requests'] / results['total_time'] if results['total_time'] > 0 else 0
        
        print(f"✅ Sucesso: {results['successful_requests']}/{num_requests} ({results['success_rate']:.1f}%)")
        print(f"⏱️ Latência: {results['avg_latency']:.2f}ms")
        print(f"🚀 Throughput: {results['throughput']:.2f} req/s")
        
        return results
    
    def test_branch_performance(self, branch_name, num_requests=500):
        """Testa performance de uma branch"""
        print(f"\n🚀 TESTANDO PERFORMANCE: {branch_name}")
        print("=" * 60)
        
        # 1. Descobrir estrutura
        structure = self.discover_branch_structure(branch_name)
        if not structure:
            print(f"❌ Falha ao descobrir estrutura de {branch_name}")
            return None
        
        # 2. Preparar ambiente
        if not self.prepare_branch_environment(structure):
            print(f"❌ Falha ao preparar ambiente de {branch_name}")
            return None
        
        # 3. Descobrir endpoints funcionais
        working_endpoints = self.discover_working_endpoints(structure)
        
        if not working_endpoints:
            print(f"❌ Nenhum endpoint funcional para {branch_name}")
            return None
        
        # 4. Executar testes
        branch_results = {
            'branch': branch_name,
            'structure': structure,
            'timestamp': datetime.now().isoformat(),
            'endpoints': {},
            'summary': {}
        }
        
        all_latencies = []
        total_successful = 0
        total_failed = 0
        total_time = 0
        
        # Testa os primeiros 2 endpoints para não sobrecarregar
        for endpoint in working_endpoints[:2]:
            test_result = self.perform_load_test(endpoint, num_requests)
            branch_results['endpoints'][endpoint] = test_result
            
            all_latencies.extend(test_result['latencies'])
            total_successful += test_result['successful_requests']
            total_failed += test_result['failed_requests']
            total_time += test_result['total_time']
        
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
                'throughput': total_successful / total_time if total_time > 0 else 0,
                'total_time': total_time
            }
            
            sorted_latencies = sorted(all_latencies)
            n = len(sorted_latencies)
            branch_results['summary']['p95_latency'] = sorted_latencies[int(n * 0.95)]
            branch_results['summary']['p99_latency'] = sorted_latencies[int(n * 0.99)]
        
        return branch_results
    
    def compare_branches(self):
        """Compara performance entre master e refactoring"""
        print("🎯 INICIANDO COMPARAÇÃO ADAPTATIVA DE PERFORMANCE")
        print("=" * 70)
        
        # Testar master
        print("\n" + "="*50)
        print("TESTANDO BRANCH MASTER")
        print("="*50)
        master_results = self.test_branch_performance("master", 400)
        
        if not master_results:
            print("❌ Falha ao testar branch master")
            return None
        
        # Testar refactoring
        print("\n" + "="*50)
        print("TESTANDO BRANCH REFACTORING")
        print("="*50)
        refactoring_results = self.test_branch_performance("refactoring-clean-architecture-v2.1", 400)
        
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
        
        # Cálculo de melhorias
        throughput_improvement = ((ref_summary['throughput'] - master_summary['throughput']) / 
                                  master_summary['throughput']) * 100 if master_summary['throughput'] > 0 else 0
        
        latency_improvement = ((master_summary['avg_latency'] - ref_summary['avg_latency']) / 
                              master_summary['avg_latency']) * 100 if master_summary['avg_latency'] > 0 else 0
        
        reliability_improvement = ((ref_summary['success_rate'] - master_summary['success_rate']) / 
                                  master_summary['success_rate']) * 100 if master_summary['success_rate'] > 0 else 0
        
        comparison = {
            'timestamp': datetime.now().isoformat(),
            'test_type': 'Adaptive Real Environment Docker Performance Test',
            'throughput': {
                'master': master_summary['throughput'],
                'refactoring': ref_summary['throughput'],
                'improvement_percentage': throughput_improvement,
                'winner': 'refactoring' if ref_summary['throughput'] > master_summary['throughput'] else 'master'
            },
            'latency': {
                'master': master_summary['avg_latency'],
                'refactoring': ref_summary['avg_latency'],
                'improvement_percentage': latency_improvement,
                'winner': 'refactoring' if ref_summary['avg_latency'] < master_summary['avg_latency'] else 'master'
            },
            'reliability': {
                'master': master_summary['success_rate'],
                'refactoring': ref_summary['success_rate'],
                'improvement_percentage': reliability_improvement,
                'winner': 'refactoring' if ref_summary['success_rate'] > master_summary['success_rate'] else 'master'
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
        
        print(f"\n🏆 RESULTADO FINAL:")
        print(f"   Vitórias Refactoring: {ref_wins}/3")
        
        if ref_wins >= 2:
            print("   ✅ REFACTORING-CLEAN-ARCHITECTURE-V2.1 VENCEU!")
            print("   A Clean Architecture demonstrou superioridade!")
        else:
            print("   ✅ MASTER teve melhor performance")
    
    def save_results(self, master_results, refactoring_results, comparison):
        """Salva resultados completos"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"adaptive_performance_comparison_{timestamp}.json"
        
        full_results = {
            'test_info': {
                'type': 'Adaptive Real Environment Docker Performance Test',
                'timestamp': datetime.now().isoformat(),
                'environment': 'WSL Ubuntu with Docker',
                'methodology': 'Branch-specific structure discovery and testing',
                'description': 'Adaptive testing that discovers and uses each branch\'s file structure'
            },
            'master_results': master_results,
            'refactoring_results': refactoring_results,
            'comparison': comparison
        }
        
        with open(filename, 'w') as f:
            json.dump(full_results, f, indent=2)
        
        print(f"\n💾 Resultados completos salvos em: {filename}")
        return filename

def main():
    tester = AdaptivePerformanceTester()
    
    print("🔧 Testador de Performance Adaptativo")
    print("Descobre automaticamente a estrutura de cada branch")
    print("=" * 60)
    
    comparison = tester.compare_branches()
    
    if comparison:
        print(f"\n✅ TESTE ADAPTATIVO CONCLUÍDO!")
        print("Performance real testada em ambiente Linux Docker!")
    else:
        print(f"\n❌ TESTE FALHOU - Verifique logs para detalhes")

if __name__ == "__main__":
    main()
