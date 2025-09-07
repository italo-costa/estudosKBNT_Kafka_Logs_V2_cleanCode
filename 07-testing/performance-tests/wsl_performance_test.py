#!/usr/bin/env python3
"""
WSL Performance Test - Executa dentro do ambiente WSL
"""

import requests
import time
import statistics
import json
from datetime import datetime
import subprocess
import sys

def run_wsl_performance_test():
    """Executa teste de performance dentro do WSL"""
    
    wsl_script = '''
import requests
import time
import statistics
import json
from datetime import datetime

def test_service(url, num_requests=1000):
    print(f"Testing {url} with {num_requests} requests...")
    
    latencies = []
    success_count = 0
    error_count = 0
    
    # Wait for service
    print("Waiting for service to be ready...")
    for i in range(30):
        try:
            response = requests.get(url, timeout=5)
            if response.status_code == 200:
                print(f"✅ Service ready: {url}")
                break
        except:
            pass
        time.sleep(2)
    else:
        print(f"❌ Service not ready: {url}")
        return None
    
    # Run test
    start_time = time.time()
    
    for i in range(num_requests):
        if i % 100 == 0:
            print(f"Progress: {i}/{num_requests}")
        
        req_start = time.time()
        try:
            response = requests.get(url, timeout=30)
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
    
    # Calculate metrics
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
        "success_rate": (success_count / num_requests) * 100
    }
    
    return results

# Main test
url = "http://localhost:8080/actuator/health"
results = test_service(url, 1000)

if results:
    print(f"\\n📊 RESULTS:")
    print(f"Success Rate: {results['success_rate']:.2f}%")
    print(f"Throughput: {results['throughput']:.2f} req/s")
    print(f"Avg Latency: {results['avg_latency']:.2f} ms")
    print(f"Min Latency: {results['min_latency']:.2f} ms")
    print(f"Max Latency: {results['max_latency']:.2f} ms")
    
    # Save results
    with open("/mnt/c/workspace/estudosKBNT_Kafka_Logs/wsl_performance_results.json", "w") as f:
        json.dump(results, f, indent=2)
    
    print("\\n✅ Results saved to wsl_performance_results.json")
else:
    print("❌ Test failed")
'''
    
    return wsl_script

def main():
    print("🎯 WSL PERFORMANCE TEST")
    print("=" * 40)
    
    # Detectar branch atual
    try:
        result = subprocess.run(['git', 'branch', '--show-current'], 
                              capture_output=True, text=True)
        current_branch = result.stdout.strip()
        print(f"Branch atual: {current_branch}")
    except:
        current_branch = "unknown"
    
    # Criar script Python temporário
    script_content = run_wsl_performance_test()
    
    with open("temp_wsl_test.py", "w") as f:
        f.write(script_content)
    
    try:
        # Executar script dentro do WSL
        print("\n🚀 Executando teste dentro do WSL...")
        
        wsl_command = [
            'wsl', '-d', 'Ubuntu', 
            'python3', '-c', script_content
        ]
        
        result = subprocess.run(wsl_command, capture_output=True, text=True, timeout=900)
        
        print("STDOUT:")
        print(result.stdout)
        
        if result.stderr:
            print("STDERR:")
            print(result.stderr)
        
        # Verificar se arquivo de resultado foi criado
        try:
            with open("wsl_performance_results.json", "r") as f:
                results = json.load(f)
            
            print(f"\n📋 RESUMO FINAL - {current_branch.upper()}:")
            print(f"Taxa de Sucesso: {results['success_rate']:.2f}%")
            print(f"Throughput: {results['throughput']:.2f} req/s")
            print(f"Latência Média: {results['avg_latency']:.2f} ms")
            
            # Salvar com timestamp
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            final_filename = f"performance_test_{current_branch}_{timestamp}.json"
            
            final_results = {
                "branch": current_branch,
                "timestamp": datetime.now().isoformat(),
                "environment": "WSL Docker",
                "results": results
            }
            
            with open(final_filename, "w") as f:
                json.dump(final_results, f, indent=2)
            
            print(f"💾 Resultados finais salvos em: {final_filename}")
            
        except FileNotFoundError:
            print("❌ Arquivo de resultados não encontrado")
        
    except subprocess.TimeoutExpired:
        print("❌ Timeout na execução do teste")
    except Exception as e:
        print(f"❌ Erro na execução: {e}")
    
    finally:
        # Limpar arquivo temporário
        try:
            import os
            os.remove("temp_wsl_test.py")
        except:
            pass

if __name__ == "__main__":
    main()
