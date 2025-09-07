#!/usr/bin/env python3
"""
Performance Test Tool for Branch Comparison
Testa throughput e latência em ambas as branches
"""

import requests
import time
import statistics
import json
import threading
import concurrent.futures
from datetime import datetime
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd

class PerformanceTester:
    def __init__(self, base_url="http://localhost:8080", num_requests=1000):
        self.base_url = base_url
        self.num_requests = num_requests
        self.results = {
            "latencies": [],
            "response_times": [],
            "success_count": 0,
            "error_count": 0,
            "start_time": None,
            "end_time": None,
            "throughput": 0,
            "avg_latency": 0,
            "p95_latency": 0,
            "p99_latency": 0
        }
        
    def make_request(self, endpoint="/api/health"):
        """Faz uma requisição e mede o tempo de resposta"""
        start_time = time.time()
        try:
            response = requests.get(f"{self.base_url}{endpoint}", timeout=30)
            end_time = time.time()
            
            latency = (end_time - start_time) * 1000  # em millisegundos
            
            if response.status_code == 200:
                return {"success": True, "latency": latency, "status_code": response.status_code}
            else:
                return {"success": False, "latency": latency, "status_code": response.status_code}
                
        except Exception as e:
            end_time = time.time()
            latency = (end_time - start_time) * 1000
            return {"success": False, "latency": latency, "error": str(e)}
    
    def run_sequential_test(self):
        """Executa teste sequencial para medir latência"""
        print(f"🔄 Executando {self.num_requests} requisições sequenciais...")
        
        self.results["start_time"] = time.time()
        
        for i in range(self.num_requests):
            if i % 100 == 0:
                print(f"   Progresso: {i}/{self.num_requests}")
                
            result = self.make_request()
            
            if result["success"]:
                self.results["success_count"] += 1
            else:
                self.results["error_count"] += 1
                
            self.results["latencies"].append(result["latency"])
            
        self.results["end_time"] = time.time()
        self.calculate_metrics()
    
    def run_concurrent_test(self, max_workers=50):
        """Executa teste concorrente para medir throughput"""
        print(f"🚀 Executando {self.num_requests} requisições concorrentes (workers: {max_workers})...")
        
        self.results["start_time"] = time.time()
        
        with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
            # Submete todas as tarefas
            futures = [executor.submit(self.make_request) for _ in range(self.num_requests)]
            
            # Coleta os resultados
            for i, future in enumerate(concurrent.futures.as_completed(futures)):
                if i % 100 == 0:
                    print(f"   Progresso: {i}/{self.num_requests}")
                    
                result = future.result()
                
                if result["success"]:
                    self.results["success_count"] += 1
                else:
                    self.results["error_count"] += 1
                    
                self.results["latencies"].append(result["latency"])
        
        self.results["end_time"] = time.time()
        self.calculate_metrics()
    
    def calculate_metrics(self):
        """Calcula métricas de performance"""
        total_time = self.results["end_time"] - self.results["start_time"]
        
        # Throughput (requests por segundo)
        self.results["throughput"] = self.num_requests / total_time
        
        # Latências
        if self.results["latencies"]:
            self.results["avg_latency"] = statistics.mean(self.results["latencies"])
            self.results["p95_latency"] = statistics.quantiles(self.results["latencies"], n=20)[18]  # 95th percentile
            self.results["p99_latency"] = statistics.quantiles(self.results["latencies"], n=100)[98]  # 99th percentile
            self.results["min_latency"] = min(self.results["latencies"])
            self.results["max_latency"] = max(self.results["latencies"])
    
    def print_results(self, branch_name):
        """Imprime resultados formatados"""
        print(f"\n📊 RESULTADOS DE PERFORMANCE - {branch_name.upper()}")
        print("=" * 60)
        print(f"Total de Requisições: {self.num_requests}")
        print(f"Requisições Bem-sucedidas: {self.results['success_count']}")
        print(f"Requisições com Erro: {self.results['error_count']}")
        print(f"Taxa de Sucesso: {(self.results['success_count']/self.num_requests)*100:.2f}%")
        print(f"\n🚀 THROUGHPUT:")
        print(f"   Requisições/segundo: {self.results['throughput']:.2f}")
        print(f"\n⏱️ LATÊNCIA:")
        print(f"   Média: {self.results['avg_latency']:.2f} ms")
        print(f"   Mínima: {self.results['min_latency']:.2f} ms")
        print(f"   Máxima: {self.results['max_latency']:.2f} ms")
        print(f"   P95: {self.results['p95_latency']:.2f} ms")
        print(f"   P99: {self.results['p99_latency']:.2f} ms")
        print(f"\n⏰ TEMPO TOTAL: {self.results['end_time'] - self.results['start_time']:.2f} segundos")
    
    def save_results(self, filename):
        """Salva resultados em arquivo JSON"""
        with open(filename, 'w') as f:
            json.dump(self.results, f, indent=2)
        print(f"💾 Resultados salvos em: {filename}")

class BranchComparator:
    def __init__(self, num_requests=1000):
        self.num_requests = num_requests
        self.results = {
            "refactoring": None,
            "master": None,
            "comparison": {}
        }
    
    def test_current_branch(self, branch_name):
        """Testa a branch atual"""
        print(f"\n🔍 TESTANDO BRANCH: {branch_name}")
        print("=" * 50)
        
        # Verificar se serviços estão rodando
        if not self.check_services():
            print("❌ Serviços não estão disponíveis. Inicie os microserviços primeiro.")
            return None
        
        # Teste de latência (sequencial)
        print("\n1️⃣ TESTE DE LATÊNCIA (Sequencial)")
        latency_tester = PerformanceTester(num_requests=200)  # Menos requisições para latência
        latency_tester.run_sequential_test()
        
        # Teste de throughput (concorrente)
        print("\n2️⃣ TESTE DE THROUGHPUT (Concorrente)")
        throughput_tester = PerformanceTester(num_requests=self.num_requests)
        throughput_tester.run_concurrent_test()
        
        # Resultados combinados
        combined_results = {
            "branch": branch_name,
            "latency_test": latency_tester.results,
            "throughput_test": throughput_tester.results,
            "timestamp": datetime.now().isoformat()
        }
        
        # Imprimir resultados
        print("\n📊 RESUMO DOS RESULTADOS:")
        print(f"Branch: {branch_name}")
        print(f"Throughput: {throughput_tester.results['throughput']:.2f} req/s")
        print(f"Latência Média: {latency_tester.results['avg_latency']:.2f} ms")
        print(f"Latência P95: {latency_tester.results['p95_latency']:.2f} ms")
        
        return combined_results
    
    def check_services(self):
        """Verifica se os serviços estão disponíveis"""
        try:
            response = requests.get("http://localhost:8080/api/health", timeout=5)
            return response.status_code == 200
        except:
            return False
    
    def compare_branches(self, refactoring_results, master_results):
        """Compara resultados entre branches"""
        print(f"\n🔄 COMPARAÇÃO ENTRE BRANCHES")
        print("=" * 50)
        
        # Throughput comparison
        ref_throughput = refactoring_results["throughput_test"]["throughput"]
        master_throughput = master_results["throughput_test"]["throughput"]
        throughput_improvement = ((ref_throughput - master_throughput) / master_throughput) * 100
        
        # Latency comparison
        ref_latency = refactoring_results["latency_test"]["avg_latency"]
        master_latency = master_results["latency_test"]["avg_latency"]
        latency_improvement = ((master_latency - ref_latency) / master_latency) * 100
        
        comparison = {
            "throughput": {
                "refactoring": ref_throughput,
                "master": master_throughput,
                "improvement_percentage": throughput_improvement,
                "winner": "refactoring" if ref_throughput > master_throughput else "master"
            },
            "latency": {
                "refactoring": ref_latency,
                "master": master_latency,
                "improvement_percentage": latency_improvement,
                "winner": "refactoring" if ref_latency < master_latency else "master"
            }
        }
        
        # Imprimir comparação
        print(f"🚀 THROUGHPUT:")
        print(f"   Refactoring: {ref_throughput:.2f} req/s")
        print(f"   Master: {master_throughput:.2f} req/s")
        print(f"   Melhoria: {throughput_improvement:+.2f}%")
        print(f"   Vencedor: {comparison['throughput']['winner'].upper()}")
        
        print(f"\n⏱️ LATÊNCIA:")
        print(f"   Refactoring: {ref_latency:.2f} ms")
        print(f"   Master: {master_latency:.2f} ms")
        print(f"   Melhoria: {latency_improvement:+.2f}%")
        print(f"   Vencedor: {comparison['latency']['winner'].upper()}")
        
        # Determinar vencedor geral
        ref_wins = sum(1 for metric in comparison.values() if metric["winner"] == "refactoring")
        overall_winner = "refactoring" if ref_wins >= 1 else "master"
        
        print(f"\n🏆 VENCEDOR GERAL: {overall_winner.upper()}")
        
        return comparison
    
    def generate_report(self, results, filename="performance_comparison_report.json"):
        """Gera relatório completo"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        report_filename = f"performance_report_{timestamp}.json"
        
        with open(report_filename, 'w') as f:
            json.dump(results, f, indent=2)
        
        print(f"\n📋 Relatório completo salvo em: {report_filename}")
        return report_filename

def main():
    """Função principal para teste da branch atual"""
    import sys
    
    print("🎯 TESTE DE PERFORMANCE - BRANCH ATUAL")
    print("=" * 50)
    
    num_requests = 1000
    if len(sys.argv) > 1:
        try:
            num_requests = int(sys.argv[1])
        except:
            pass
    
    comparator = BranchComparator(num_requests)
    
    # Detectar branch atual
    try:
        import subprocess
        result = subprocess.run(['git', 'branch', '--show-current'], 
                              capture_output=True, text=True)
        current_branch = result.stdout.strip()
    except:
        current_branch = "unknown"
    
    print(f"Branch atual detectada: {current_branch}")
    
    # Testar branch atual
    results = comparator.test_current_branch(current_branch)
    
    if results:
        # Salvar resultados
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"performance_test_{current_branch}_{timestamp}.json"
        
        with open(filename, 'w') as f:
            json.dump(results, f, indent=2)
        
        print(f"\n✅ Teste concluído! Resultados salvos em: {filename}")
    else:
        print("\n❌ Teste falhou. Verifique se os serviços estão rodando.")

if __name__ == "__main__":
    main()
