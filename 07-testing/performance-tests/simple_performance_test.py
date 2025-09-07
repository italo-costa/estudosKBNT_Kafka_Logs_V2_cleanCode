#!/usr/bin/env python3
"""
Teste Simples de Performance com Timeout Estendido
"""

import requests
import time
import statistics
import json
from datetime import datetime

def wait_for_service(url, timeout=600):
    """Aguarda um serviço específico ficar disponível"""
    print(f"⏳ Aguardando {url}...")
    start_time = time.time()
    
    while time.time() - start_time < timeout:
        try:
            response = requests.get(url, timeout=10)
            if response.status_code == 200:
                print(f"✅ {url} está disponível!")
                return True
        except Exception as e:
            print(f"   Tentando... ({int(time.time() - start_time)}s) - {str(e)[:50]}")
        
        time.sleep(15)
    
    print(f"❌ Timeout para {url}")
    return False

def simple_performance_test(base_url, num_requests=1000):
    """Teste simples de performance"""
    print(f"\n🚀 Executando teste de {num_requests} requisições em {base_url}")
    
    latencies = []
    success_count = 0
    error_count = 0
    
    start_time = time.time()
    
    for i in range(num_requests):
        if i % 100 == 0:
            print(f"   Progresso: {i}/{num_requests}")
        
        req_start = time.time()
        try:
            response = requests.get(base_url, timeout=30)
            req_end = time.time()
            
            latency = (req_end - req_start) * 1000
            latencies.append(latency)
            
            if response.status_code == 200:
                success_count += 1
            else:
                error_count += 1
                
        except Exception as e:
            req_end = time.time()
            latency = (req_end - req_start) * 1000
            latencies.append(latency)
            error_count += 1
    
    end_time = time.time()
    total_time = end_time - start_time
    
    # Calcular métricas
    throughput = num_requests / total_time
    avg_latency = statistics.mean(latencies) if latencies else 0
    
    results = {
        "num_requests": num_requests,
        "success_count": success_count,
        "error_count": error_count,
        "total_time": total_time,
        "throughput": throughput,
        "avg_latency": avg_latency,
        "min_latency": min(latencies) if latencies else 0,
        "max_latency": max(latencies) if latencies else 0,
        "p95_latency": statistics.quantiles(latencies, n=20)[18] if len(latencies) >= 20 else 0,
        "p99_latency": statistics.quantiles(latencies, n=100)[98] if len(latencies) >= 100 else 0,
        "success_rate": (success_count / num_requests) * 100
    }
    
    return results

def print_results(results, branch_name):
    """Imprime resultados"""
    print(f"\n📊 RESULTADOS - {branch_name.upper()}")
    print("=" * 50)
    print(f"Requisições: {results['num_requests']}")
    print(f"Sucessos: {results['success_count']}")
    print(f"Erros: {results['error_count']}")
    print(f"Taxa de Sucesso: {results['success_rate']:.2f}%")
    print(f"Throughput: {results['throughput']:.2f} req/s")
    print(f"Latência Média: {results['avg_latency']:.2f} ms")
    print(f"Latência P95: {results['p95_latency']:.2f} ms")
    print(f"Latência P99: {results['p99_latency']:.2f} ms")
    print(f"Tempo Total: {results['total_time']:.2f} s")

def main():
    print("🎯 TESTE SIMPLES DE PERFORMANCE")
    print("=" * 40)
    
    # Detectar branch atual
    try:
        import subprocess
        result = subprocess.run(['git', 'branch', '--show-current'], 
                              capture_output=True, text=True)
        current_branch = result.stdout.strip()
    except:
        current_branch = "unknown"
    
    print(f"Branch atual: {current_branch}")
    
    # URLs para testar
    test_urls = [
        "http://localhost:8080/actuator/health",
        "http://localhost:8081/actuator/health",
        "http://localhost:8082/actuator/health", 
        "http://localhost:8083/actuator/health"
    ]
    
    # Encontrar um serviço que funciona
    working_url = None
    for url in test_urls:
        if wait_for_service(url, timeout=120):
            working_url = url
            break
    
    if not working_url:
        print("❌ Nenhum serviço disponível para teste")
        return
    
    # Executar teste
    print(f"\n🎯 Testando com {working_url}")
    results = simple_performance_test(working_url, 1000)
    
    # Mostrar resultados
    print_results(results, current_branch)
    
    # Salvar resultados
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"simple_performance_{current_branch}_{timestamp}.json"
    
    test_data = {
        "branch": current_branch,
        "timestamp": datetime.now().isoformat(),
        "test_url": working_url,
        "results": results
    }
    
    with open(filename, 'w') as f:
        json.dump(test_data, f, indent=2)
    
    print(f"\n💾 Resultados salvos em: {filename}")

if __name__ == "__main__":
    main()
