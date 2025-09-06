#!/usr/bin/env python3
"""
KBNT Kafka Logs - Performance Test Runner (Threading Version)
Executa 1000 requisições de teste de performance usando threading
"""

import time
import threading
import json
import urllib.request
import urllib.error
from typing import List, Dict
from dataclasses import dataclass, asdict
from datetime import datetime
import statistics
import concurrent.futures
from queue import Queue

@dataclass
class RequestResult:
    request_id: int
    status_code: int
    response_time_ms: float
    timestamp: str
    success: bool
    error: str = None

class PerformanceTestRunner:
    def __init__(self, base_url: str = "http://localhost:8080"):
        self.base_url = base_url
        self.results: List[RequestResult] = []
        
    async def make_request(self, session: aiohttp.ClientSession, request_id: int) -> RequestResult:
        """Faz uma requisição individual"""
        start_time = time.time()
        timestamp = datetime.now().isoformat()
        
        try:
            async with session.get(f"{self.base_url}/actuator/health", timeout=10) as response:
                end_time = time.time()
                response_time_ms = (end_time - start_time) * 1000
                
                return RequestResult(
                    request_id=request_id,
                    status_code=response.status,
                    response_time_ms=response_time_ms,
                    timestamp=timestamp,
                    success=response.status == 200
                )
        except Exception as e:
            end_time = time.time()
            response_time_ms = (end_time - start_time) * 1000
            
            return RequestResult(
                request_id=request_id,
                status_code=0,
                response_time_ms=response_time_ms,
                timestamp=timestamp,
                success=False,
                error=str(e)
            )
    
    async def run_load_test(self, total_requests: int = 1000, concurrent_requests: int = 50):
        """Executa teste de carga com 1000 requisições"""
        print(f"🚀 Starting load test: {total_requests} requests, {concurrent_requests} concurrent")
        print("=" * 70)
        
        start_time = time.time()
        
        # Configurar cliente HTTP
        connector = aiohttp.TCPConnector(limit=concurrent_requests * 2)
        timeout = aiohttp.ClientTimeout(total=30)
        
        async with aiohttp.ClientSession(connector=connector, timeout=timeout) as session:
            # Verificar se serviço está rodando
            print("🔍 Checking service availability...")
            test_result = await self.make_request(session, 0)
            
            if not test_result.success:
                print(f"❌ Service not available: {test_result.error}")
                print(f"💡 Make sure API Gateway is running on {self.base_url}")
                return
            
            print(f"✅ Service is available (response time: {test_result.response_time_ms:.2f}ms)")
            print()
            
            # Executar requisições em lotes
            batch_size = concurrent_requests
            completed = 0
            
            for batch_start in range(0, total_requests, batch_size):
                batch_end = min(batch_start + batch_size, total_requests)
                batch_requests = []
                
                # Criar lote de requisições
                for i in range(batch_start, batch_end):
                    batch_requests.append(self.make_request(session, i + 1))
                
                # Executar lote concorrentemente
                batch_results = await asyncio.gather(*batch_requests, return_exceptions=True)
                
                # Processar resultados
                for result in batch_results:
                    if isinstance(result, RequestResult):
                        self.results.append(result)
                        completed += 1
                
                # Progress update
                progress = (completed / total_requests) * 100
                print(f"📊 Progress: {completed}/{total_requests} ({progress:.1f}%) - Last batch: {len(batch_requests)} requests")
        
        end_time = time.time()
        total_duration = end_time - start_time
        
        # Análise dos resultados
        self.analyze_results(total_duration)
    
    def analyze_results(self, total_duration: float):
        """Analisa e exibe resultados do teste"""
        if not self.results:
            print("❌ No results to analyze")
            return
        
        print("\n" + "=" * 70)
        print("📊 PERFORMANCE TEST RESULTS")
        print("=" * 70)
        
        # Métricas gerais
        total_requests = len(self.results)
        successful_requests = len([r for r in self.results if r.success])
        failed_requests = total_requests - successful_requests
        success_rate = (successful_requests / total_requests) * 100
        
        print(f"📈 General Metrics:")
        print(f"   Total Requests: {total_requests}")
        print(f"   Successful: {successful_requests}")
        print(f"   Failed: {failed_requests}")
        print(f"   Success Rate: {success_rate:.2f}%")
        print(f"   Total Duration: {total_duration:.2f}s")
        
        # Throughput
        requests_per_second = total_requests / total_duration
        print(f"   Requests/Second: {requests_per_second:.2f} RPS")
        
        # Métricas de resposta (apenas requests bem-sucedidas)
        successful_response_times = [r.response_time_ms for r in self.results if r.success]
        
        if successful_response_times:
            avg_response_time = statistics.mean(successful_response_times)
            median_response_time = statistics.median(successful_response_times)
            min_response_time = min(successful_response_times)
            max_response_time = max(successful_response_times)
            
            # Percentis
            sorted_times = sorted(successful_response_times)
            p95_index = int(0.95 * len(sorted_times))
            p99_index = int(0.99 * len(sorted_times))
            p95_response_time = sorted_times[p95_index]
            p99_response_time = sorted_times[p99_index]
            
            print(f"\n⏱️  Response Time Metrics:")
            print(f"   Average: {avg_response_time:.2f}ms")
            print(f"   Median: {median_response_time:.2f}ms")
            print(f"   Min: {min_response_time:.2f}ms")
            print(f"   Max: {max_response_time:.2f}ms")
            print(f"   95th Percentile: {p95_response_time:.2f}ms")
            print(f"   99th Percentile: {p99_response_time:.2f}ms")
        
        # Análise de erros
        if failed_requests > 0:
            print(f"\n❌ Error Analysis:")
            error_types = {}
            for result in self.results:
                if not result.success:
                    error_key = result.error or f"HTTP {result.status_code}"
                    error_types[error_key] = error_types.get(error_key, 0) + 1
            
            for error, count in error_types.items():
                print(f"   {error}: {count} occurrences")
        
        # Salvar relatório
        self.save_report(total_duration, requests_per_second)
        
        # Conclusão
        print(f"\n🎯 Performance Assessment:")
        if requests_per_second > 1000:
            print(f"   ✅ EXCELLENT: {requests_per_second:.0f} RPS - High performance system")
        elif requests_per_second > 500:
            print(f"   ✅ GOOD: {requests_per_second:.0f} RPS - Good performance")
        elif requests_per_second > 100:
            print(f"   ⚠️  MODERATE: {requests_per_second:.0f} RPS - Acceptable performance")
        else:
            print(f"   ❌ LOW: {requests_per_second:.0f} RPS - Performance needs improvement")
    
    def save_report(self, total_duration: float, rps: float):
        """Salva relatório detalhado em JSON"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        report_file = f"performance_report_{timestamp}.json"
        
        successful_requests = [r for r in self.results if r.success]
        successful_response_times = [r.response_time_ms for r in successful_requests]
        
        report = {
            "test_info": {
                "timestamp": datetime.now().isoformat(),
                "base_url": self.base_url,
                "total_requests": len(self.results),
                "total_duration_seconds": total_duration
            },
            "performance_metrics": {
                "requests_per_second": rps,
                "success_rate_percent": (len(successful_requests) / len(self.results)) * 100,
                "avg_response_time_ms": statistics.mean(successful_response_times) if successful_response_times else 0,
                "p95_response_time_ms": sorted(successful_response_times)[int(0.95 * len(successful_response_times))] if successful_response_times else 0,
                "p99_response_time_ms": sorted(successful_response_times)[int(0.99 * len(successful_response_times))] if successful_response_times else 0
            },
            "detailed_results": [asdict(result) for result in self.results]
        }
        
        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2)
        
        print(f"\n📄 Detailed report saved: {report_file}")

async def main():
    # Configurações do teste
    BASE_URL = "http://localhost:8080"
    TOTAL_REQUESTS = 1000
    CONCURRENT_REQUESTS = 50
    
    print("🎯 KBNT Kafka Logs - Performance Test Suite")
    print("=" * 70)
    print(f"Target: {BASE_URL}")
    print(f"Total Requests: {TOTAL_REQUESTS}")
    print(f"Concurrent Requests: {CONCURRENT_REQUESTS}")
    print()
    
    runner = PerformanceTestRunner(BASE_URL)
    await runner.run_load_test(TOTAL_REQUESTS, CONCURRENT_REQUESTS)

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n🛑 Test interrupted by user")
    except Exception as e:
        print(f"\n❌ Test failed: {e}")
