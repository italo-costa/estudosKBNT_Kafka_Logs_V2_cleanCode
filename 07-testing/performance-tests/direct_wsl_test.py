#!/usr/bin/env python3
"""
Direct WSL Performance Test
"""

import subprocess
import json
from datetime import datetime

def main():
    print("Performance Test - WSL Direct Execution")
    print("=" * 50)
    
    # Detectar branch atual
    try:
        result = subprocess.run(['git', 'branch', '--show-current'], 
                              capture_output=True, text=True)
        current_branch = result.stdout.strip()
        print(f"Branch: {current_branch}")
    except:
        current_branch = "unknown"
    
    # Script simples para executar no WSL
    wsl_command = '''
python3 -c "
import requests
import time
import statistics
import json

def test_performance():
    url = 'http://localhost:8080/actuator/health'
    num_requests = 1000
    
    print('Waiting for service...')
    for i in range(30):
        try:
            resp = requests.get(url, timeout=5)
            if resp.status_code == 200:
                print('Service ready!')
                break
        except:
            pass
        time.sleep(2)
    else:
        print('Service not ready')
        return None
    
    print(f'Running {num_requests} requests...')
    latencies = []
    success = 0
    errors = 0
    
    start_time = time.time()
    
    for i in range(num_requests):
        if i % 200 == 0:
            print(f'Progress: {i}/{num_requests}')
        
        req_start = time.time()
        try:
            resp = requests.get(url, timeout=30)
            req_end = time.time()
            latency = (req_end - req_start) * 1000
            latencies.append(latency)
            if resp.status_code == 200:
                success += 1
            else:
                errors += 1
        except:
            req_end = time.time()
            latency = (req_end - req_start) * 1000
            latencies.append(latency)
            errors += 1
    
    end_time = time.time()
    total_time = end_time - start_time
    throughput = num_requests / total_time
    avg_latency = statistics.mean(latencies) if latencies else 0
    success_rate = (success / num_requests) * 100
    
    results = {
        'requests': num_requests,
        'success': success,
        'errors': errors,
        'success_rate': success_rate,
        'total_time': total_time,
        'throughput': throughput,
        'avg_latency': avg_latency,
        'min_latency': min(latencies) if latencies else 0,
        'max_latency': max(latencies) if latencies else 0
    }
    
    print(f'Results:')
    print(f'Success Rate: {success_rate:.2f}%')
    print(f'Throughput: {throughput:.2f} req/s')
    print(f'Avg Latency: {avg_latency:.2f} ms')
    print(f'Min Latency: {results[\\\"min_latency\\\"]:.2f} ms')
    print(f'Max Latency: {results[\\\"max_latency\\\"]:.2f} ms')
    
    # Save results
    with open('/mnt/c/workspace/estudosKBNT_Kafka_Logs/wsl_test_results.json', 'w') as f:
        json.dump(results, f, indent=2)
    
    print('Results saved!')

test_performance()
"
'''
    
    try:
        print("\nExecuting performance test in WSL...")
        
        # Executar no WSL
        result = subprocess.run([
            'wsl', '-d', 'Ubuntu', 'bash', '-c', wsl_command
        ], capture_output=True, text=True, timeout=900)
        
        print("Output:")
        print(result.stdout)
        
        if result.stderr:
            print("Errors:")
            print(result.stderr)
        
        # Verificar resultados
        try:
            with open("wsl_test_results.json", "r") as f:
                results = json.load(f)
            
            # Salvar resultado final
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            final_filename = f"performance_refactoring_{timestamp}.json"
            
            final_data = {
                "branch": current_branch,
                "timestamp": datetime.now().isoformat(),
                "environment": "WSL_Docker",
                "test_results": results
            }
            
            with open(final_filename, "w") as f:
                json.dump(final_data, f, indent=2)
            
            print(f"\nFINAL RESULTS - {current_branch}:")
            print(f"Success Rate: {results['success_rate']:.2f}%")
            print(f"Throughput: {results['throughput']:.2f} req/s")
            print(f"Average Latency: {results['avg_latency']:.2f} ms")
            print(f"Results saved to: {final_filename}")
            
            return results
            
        except FileNotFoundError:
            print("Results file not found")
            return None
        
    except subprocess.TimeoutExpired:
        print("Test timed out")
        return None
    except Exception as e:
        print(f"Error: {e}")
        return None

if __name__ == "__main__":
    main()
