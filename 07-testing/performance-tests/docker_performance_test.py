#!/usr/bin/env python3
"""
Teste de Performance Otimizado para Ambiente WSL Docker
"""

import requests
import time
import statistics
import json
from datetime import datetime
import concurrent.futures
import threading

class DockerPerformanceTester:
    def __init__(self, base_url="http://localhost:8080", num_requests=1000):
        self.base_url = base_url
        self.num_requests = num_requests
        self.results = {
            "latencies": [],
            "success_count": 0,
            "error_count": 0,
            "start_time": None,
            "end_time": None,
            "throughput": 0,
            "avg_latency": 0,
            "p95_latency": 0,
            "p99_latency": 0,
            "min_latency": 0,
            "max_latency": 0
        }
    
    def wait_for_services(self, timeout=300):
        """Aguarda serviços ficarem disponíveis"""
        print("⏳ Aguardando serviços ficarem disponíveis...")
        start_time = time.time()
        
        endpoints_to_check = [
            "http://localhost:8080/actuator/health",
            "http://localhost:8081/actuator/health", 
            "http://localhost:8082/actuator/health",
            "http://localhost:8083/actuator/health"
        ]
        
        while time.time() - start_time < timeout:
            ready_services = 0
            
            for endpoint in endpoints_to_check:
                try:
                    response = requests.get(endpoint, timeout=5)
                    if response.status_code == 200:
                        ready_services += 1
                except:
                    pass
            
            print(f"   Serviços prontos: {ready_services}/{len(endpoints_to_check)}")
            
            if ready_services >= 2:  # Pelo menos 2 serviços prontos
                print("✅ Serviços suficientes disponíveis!")
                time.sleep(5)  # Aguarda mais um pouco para estabilizar
                return True
            
            time.sleep(10)
        
        print(f"❌ Timeout aguardando serviços ({timeout}s)")
        return False
    
    def make_request(self, endpoint="/actuator/health"):
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
    
    def run_performance_test(self, test_type="concurrent"):
        """Executa teste de performance"""
        
        # Aguardar serviços
        if not self.wait_for_services():
            print("❌ Serviços não estão disponíveis")
            return False
        
        print(f"🚀 Executando teste de {self.num_requests} requisições ({test_type})...")
        
        self.results["start_time"] = time.time()
        
        if test_type == "concurrent":
            self._run_concurrent_test()
        else:
            self._run_sequential_test()
        
        self.results["end_time"] = time.time()
        self._calculate_metrics()
        return True
    
    def _run_concurrent_test(self, max_workers=20):
        """Executa teste concorrente"""
        with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
            futures = [executor.submit(self.make_request) for _ in range(self.num_requests)]
            
            for i, future in enumerate(concurrent.futures.as_completed(futures)):
                if i % 200 == 0:
                    print(f"   Progresso: {i}/{self.num_requests}")
                    
                result = future.result()
                self._process_result(result)
    
    def _run_sequential_test(self):
        """Executa teste sequencial"""
        for i in range(self.num_requests):
            if i % 200 == 0:
                print(f"   Progresso: {i}/{self.num_requests}")
                
            result = self.make_request()
            self._process_result(result)
    
    def _process_result(self, result):
        """Processa resultado de uma requisição"""
        if result["success"]:
            self.results["success_count"] += 1
        else:
            self.results["error_count"] += 1
            
        self.results["latencies"].append(result["latency"])
    
    def _calculate_metrics(self):
        """Calcula métricas de performance"""
        total_time = self.results["end_time"] - self.results["start_time"]
        
        # Throughput (requests por segundo)
        self.results["throughput"] = self.num_requests / total_time
        
        # Latências
        if self.results["latencies"]:
            self.results["avg_latency"] = statistics.mean(self.results["latencies"])
            self.results["min_latency"] = min(self.results["latencies"])
            self.results["max_latency"] = max(self.results["latencies"])
            
            # Percentis
            sorted_latencies = sorted(self.results["latencies"])
            n = len(sorted_latencies)
            self.results["p95_latency"] = sorted_latencies[int(n * 0.95)]
            self.results["p99_latency"] = sorted_latencies[int(n * 0.99)]
    
    def print_results(self, branch_name="current"):
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
    
    def save_results(self, branch_name="current"):
        """Salva resultados em arquivo"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"performance_test_{branch_name}_{timestamp}.json"
        
        test_data = {
            "branch": branch_name,
            "timestamp": datetime.now().isoformat(),
            "test_config": {
                "num_requests": self.num_requests,
                "base_url": self.base_url
            },
            "results": self.results
        }
        
        with open(filename, 'w') as f:
            json.dump(test_data, f, indent=2)
        
        print(f"💾 Resultados salvos em: {filename}")
        return filename

def main():
    print("🎯 TESTE DE PERFORMANCE - DOCKER WSL ENVIRONMENT")
    print("=" * 60)
    
    # Detectar branch atual
    try:
        import subprocess
        result = subprocess.run(['git', 'branch', '--show-current'], 
                              capture_output=True, text=True)
        current_branch = result.stdout.strip()
    except:
        current_branch = "unknown"
    
    print(f"Branch atual: {current_branch}")
    
    # Configurar teste
    num_requests = 1000
    tester = DockerPerformanceTester(num_requests=num_requests)
    
    # Executar teste
    if tester.run_performance_test("concurrent"):
        tester.print_results(current_branch)
        filename = tester.save_results(current_branch)
        
        print(f"\n✅ Teste concluído com sucesso!")
        print(f"📋 Arquivo de resultados: {filename}")
        
        return tester.results
    else:
        print("\n❌ Teste falhou - serviços não disponíveis")
        return None

if __name__ == "__main__":
    main()
