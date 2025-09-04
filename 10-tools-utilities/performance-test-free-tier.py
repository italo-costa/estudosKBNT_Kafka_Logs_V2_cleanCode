#!/usr/bin/env python3
"""
Performance Test for KBNT Kafka Logs - Free Tier Strategy
Test 1000 requests in 10 seconds to evaluate best configuration
"""

import asyncio
import aiohttp
import json
import time
import statistics
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor
import threading

class PerformanceTest:
    def __init__(self):
        self.base_url = "http://localhost:8090"
        self.results = {
            'total_requests': 0,
            'successful_requests': 0,
            'failed_requests': 0,
            'response_times': [],
            'errors': [],
            'start_time': None,
            'end_time': None,
            'rps_target': 100,  # 1000 requests / 10 seconds
            'duration': 10
        }
        
    async def make_request(self, session, request_id):
        """Make a single HTTP request"""
        start_time = time.time()
        
        try:
            # Create stock data matching the expected CreateStockRequest format
            stock_data = {
                "productId": f"PROD_{request_id:06d}",
                "symbol": f"STK{request_id % 100:02d}",
                "productName": f"Product {request_id}",
                "initialQuantity": 100 + (request_id % 50),
                "unitPrice": 10.50 + (request_id % 20),
                "createdBy": "performance-test"
            }
            
            async with session.post(
                f"{self.base_url}/api/v1/virtual-stock/stocks",
                json=stock_data,
                timeout=aiohttp.ClientTimeout(total=5)
            ) as response:
                end_time = time.time()
                response_time = end_time - start_time
                
                # Read response body for debugging
                response_text = await response.text()
                
                if response.status == 200 or response.status == 201:
                    self.results['successful_requests'] += 1
                    self.results['response_times'].append(response_time)
                else:
                    self.results['failed_requests'] += 1
                    error_msg = f"HTTP {response.status}: {response_text[:100]}"
                    self.results['errors'].append(error_msg)
                
                self.results['total_requests'] += 1
                
        except asyncio.TimeoutError:
            self.results['failed_requests'] += 1
            self.results['total_requests'] += 1
            self.results['errors'].append("Timeout")
            
        except Exception as e:
            self.results['failed_requests'] += 1
            self.results['total_requests'] += 1
            self.results['errors'].append(f"Exception: {str(e)[:100]}")
    
    async def wait_for_service_ready(self):
        """Wait for services to be ready"""
        print("🔄 Aguardando serviços ficarem prontos...")
        max_retries = 30
        retry_count = 0
        
        while retry_count < max_retries:
            try:
                async with aiohttp.ClientSession() as session:
                    async with session.get(
                        f"{self.base_url}/actuator/health",
                        timeout=aiohttp.ClientTimeout(total=2)
                    ) as response:
                        if response.status == 200:
                            print("✅ Serviços prontos!")
                            return True
            except:
                retry_count += 1
                print(f"⏳ Tentativa {retry_count}/{max_retries}...")
                await asyncio.sleep(2)
        
        print("❌ Serviços não ficaram prontos no tempo esperado")
        return False
    
    async def run_performance_test(self):
        """Execute the performance test"""
        print(f"🚀 Iniciando teste de performance: {self.results['rps_target'] * self.results['duration']} requisições em {self.results['duration']}s")
        
        # Wait for services
        if not await self.wait_for_service_ready():
            return
        
        self.results['start_time'] = time.time()
        
        # Create connector with increased limits
        connector = aiohttp.TCPConnector(
            limit=200,  # Total connection limit
            limit_per_host=100,  # Per host limit
            ttl_dns_cache=300,
            use_dns_cache=True
        )
        
        async with aiohttp.ClientSession(connector=connector) as session:
            # Generate tasks for all requests
            tasks = []
            
            for batch in range(self.results['duration']):  # 10 batches (1 per second)
                batch_tasks = []
                for i in range(self.results['rps_target']):  # 100 requests per batch
                    request_id = batch * self.results['rps_target'] + i
                    task = self.make_request(session, request_id)
                    batch_tasks.append(task)
                
                # Execute batch
                await asyncio.gather(*batch_tasks, return_exceptions=True)
                
                # Small delay to control RPS
                if batch < self.results['duration'] - 1:
                    await asyncio.sleep(0.1)
                
                print(f"📊 Batch {batch + 1}/{self.results['duration']} concluído")
        
        self.results['end_time'] = time.time()
    
    def generate_report(self):
        """Generate performance test report"""
        duration = self.results['end_time'] - self.results['start_time']
        actual_rps = self.results['total_requests'] / duration if duration > 0 else 0
        
        success_rate = (self.results['successful_requests'] / self.results['total_requests'] * 100) if self.results['total_requests'] > 0 else 0
        
        report = {
            "test_configuration": {
                "strategy": "Free Tier Strategy",
                "target_requests": self.results['rps_target'] * self.results['duration'],
                "target_duration": self.results['duration'],
                "target_rps": self.results['rps_target']
            },
            "results": {
                "total_requests": self.results['total_requests'],
                "successful_requests": self.results['successful_requests'],
                "failed_requests": self.results['failed_requests'],
                "success_rate_percent": round(success_rate, 2),
                "actual_duration": round(duration, 2),
                "actual_rps": round(actual_rps, 2)
            },
            "response_times": {
                "count": len(self.results['response_times']),
                "min_ms": round(min(self.results['response_times']) * 1000, 2) if self.results['response_times'] else 0,
                "max_ms": round(max(self.results['response_times']) * 1000, 2) if self.results['response_times'] else 0,
                "avg_ms": round(statistics.mean(self.results['response_times']) * 1000, 2) if self.results['response_times'] else 0,
                "median_ms": round(statistics.median(self.results['response_times']) * 1000, 2) if self.results['response_times'] else 0,
                "p95_ms": round(statistics.quantiles(self.results['response_times'], n=20)[18] * 1000, 2) if len(self.results['response_times']) > 20 else 0,
                "p99_ms": round(statistics.quantiles(self.results['response_times'], n=100)[98] * 1000, 2) if len(self.results['response_times']) > 100 else 0
            },
            "errors": {
                "total_errors": self.results['failed_requests'],
                "error_types": dict(zip(*zip(*[(e, self.results['errors'].count(e)) for e in set(self.results['errors'])]))) if self.results['errors'] else {}
            },
            "performance_analysis": self.analyze_performance(success_rate, actual_rps, self.results['response_times']),
            "timestamp": datetime.now().isoformat()
        }
        
        return report
    
    def analyze_performance(self, success_rate, actual_rps, response_times):
        """Analyze performance and provide recommendations"""
        analysis = {
            "overall_rating": "Unknown",
            "bottlenecks": [],
            "recommendations": [],
            "scalability_assessment": "Unknown"
        }
        
        # Overall rating based on success rate and performance
        if success_rate >= 95 and actual_rps >= 80:
            analysis["overall_rating"] = "Excellent"
        elif success_rate >= 90 and actual_rps >= 60:
            analysis["overall_rating"] = "Good"
        elif success_rate >= 80 and actual_rps >= 40:
            analysis["overall_rating"] = "Fair"
        else:
            analysis["overall_rating"] = "Poor"
        
        # Identify bottlenecks
        if success_rate < 90:
            analysis["bottlenecks"].append("High error rate indicates system overload")
        
        if response_times and statistics.mean(response_times) > 1.0:
            analysis["bottlenecks"].append("High average response time")
        
        if actual_rps < self.results['rps_target'] * 0.8:
            analysis["bottlenecks"].append("Unable to achieve target RPS")
        
        # Provide recommendations
        if success_rate < 95:
            analysis["recommendations"].append("Consider upgrading to Scalable Simple strategy")
            analysis["recommendations"].append("Add load balancer for better request distribution")
        
        if response_times and statistics.mean(response_times) > 0.5:
            analysis["recommendations"].append("Optimize database connections")
            analysis["recommendations"].append("Add Redis cache for frequently accessed data")
        
        if actual_rps < 80:
            analysis["recommendations"].append("Scale to multiple container instances")
            analysis["recommendations"].append("Implement async processing for heavy operations")
        
        # Scalability assessment
        if success_rate >= 95 and actual_rps >= 90:
            analysis["scalability_assessment"] = "Free tier handles load well - can proceed to production"
        elif success_rate >= 85 and actual_rps >= 70:
            analysis["scalability_assessment"] = "Moderate performance - consider scaling for production"
        else:
            analysis["scalability_assessment"] = "Poor performance - immediate upgrade recommended"
        
        return analysis

async def main():
    """Main execution function"""
    test = PerformanceTest()
    
    print("=" * 60)
    print("🎯 KBNT Kafka Logs - Performance Test Free Tier")
    print("=" * 60)
    
    await test.run_performance_test()
    report = test.generate_report()
    
    print("\n" + "=" * 60)
    print("📊 RELATÓRIO DE PERFORMANCE")
    print("=" * 60)
    
    # Save detailed report
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    report_file = f"RELATORIO-PERFORMANCE-FREE-TIER-{timestamp}.json"
    
    with open(report_file, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    # Print summary
    print(f"\n🎯 Configuração do Teste:")
    print(f"   Estratégia: {report['test_configuration']['strategy']}")
    print(f"   Target: {report['test_configuration']['target_requests']} requisições em {report['test_configuration']['target_duration']}s")
    print(f"   RPS Target: {report['test_configuration']['target_rps']}")
    
    print(f"\n📈 Resultados:")
    print(f"   Total de Requisições: {report['results']['total_requests']}")
    print(f"   Sucessos: {report['results']['successful_requests']}")
    print(f"   Falhas: {report['results']['failed_requests']}")
    print(f"   Taxa de Sucesso: {report['results']['success_rate_percent']}%")
    print(f"   RPS Alcançado: {report['results']['actual_rps']}")
    print(f"   Duração Real: {report['results']['actual_duration']}s")
    
    print(f"\n⏱️ Tempos de Resposta:")
    print(f"   Médio: {report['response_times']['avg_ms']}ms")
    print(f"   Mediana: {report['response_times']['median_ms']}ms")
    print(f"   P95: {report['response_times']['p95_ms']}ms")
    print(f"   P99: {report['response_times']['p99_ms']}ms")
    print(f"   Min/Max: {report['response_times']['min_ms']}ms / {report['response_times']['max_ms']}ms")
    
    print(f"\n🔍 Análise de Performance:")
    print(f"   Classificação Geral: {report['performance_analysis']['overall_rating']}")
    print(f"   Avaliação de Escalabilidade: {report['performance_analysis']['scalability_assessment']}")
    
    if report['performance_analysis']['bottlenecks']:
        print(f"\n⚠️ Gargalos Identificados:")
        for bottleneck in report['performance_analysis']['bottlenecks']:
            print(f"   - {bottleneck}")
    
    if report['performance_analysis']['recommendations']:
        print(f"\n💡 Recomendações:")
        for rec in report['performance_analysis']['recommendations']:
            print(f"   - {rec}")
    
    if report['errors']['error_types']:
        print(f"\n❌ Tipos de Erro:")
        for error_type, count in report['errors']['error_types'].items():
            print(f"   - {error_type}: {count}")
    
    print(f"\n📄 Relatório completo salvo em: {report_file}")
    print("=" * 60)

if __name__ == "__main__":
    asyncio.run(main())
