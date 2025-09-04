#!/usr/bin/env python3
"""
Performance Test Simplificado para KBNT Kafka Logs - Free Tier Strategy
Teste 1000 requisições em 10 segundos para avaliar performance
Versão simplificada com teste direto nos serviços
"""

import asyncio
import aiohttp
import json
import time
import statistics
from datetime import datetime
import requests

class SimplePerformanceTest:
    def __init__(self):
        self.base_urls = [
            "http://localhost:8090",  # API Gateway
            "http://localhost:8086",  # Virtual Stock Direct
            "http://localhost:8087"   # Virtual Stock Health
        ]
        self.results = {
            'total_requests': 0,
            'successful_requests': 0,
            'failed_requests': 0,
            'response_times': [],
            'errors': [],
            'start_time': None,
            'end_time': None,
            'working_url': None
        }
    
    def test_connectivity(self):
        """Test which endpoints are working"""
        print("🔍 Testando conectividade dos serviços...")
        
        test_endpoints = [
            ("API Gateway Health", "http://localhost:8090/actuator/health"),
            ("API Gateway Virtual Stock", "http://localhost:8090/api/v1/virtual-stock/stocks"),
            ("Virtual Stock Health", "http://localhost:8087/actuator/health"),
            ("Virtual Stock Direct", "http://localhost:8086/api/v1/virtual-stock/stocks"),
        ]
        
        for name, url in test_endpoints:
            try:
                response = requests.get(url, timeout=3)
                status = "✅ OK" if response.status_code < 400 else f"❌ HTTP {response.status_code}"
                print(f"  {name}: {status}")
                
                if response.status_code < 400 and 'virtual-stock/stocks' in url:
                    self.results['working_url'] = url.replace('/stocks', '')
                    
            except Exception as e:
                print(f"  {name}: ❌ {str(e)[:50]}")
    
    def simple_sync_test(self, target_requests=100, duration=10):
        """Execute a simple synchronous test"""
        if not self.results['working_url']:
            print("❌ Nenhum endpoint funcional encontrado!")
            return
        
        print(f"🚀 Executando teste com {target_requests} requisições em {duration}s")
        print(f"📍 Usando endpoint: {self.results['working_url']}")
        
        self.results['start_time'] = time.time()
        requests_per_second = target_requests // duration
        
        for batch in range(duration):
            batch_start = time.time()
            
            for i in range(requests_per_second):
                request_id = batch * requests_per_second + i
                self.make_sync_request(request_id)
            
            # Control timing
            batch_duration = time.time() - batch_start
            if batch_duration < 1.0:
                time.sleep(1.0 - batch_duration)
            
            print(f"📊 Batch {batch + 1}/{duration}: {self.results['successful_requests']}/{self.results['total_requests']} sucessos")
        
        self.results['end_time'] = time.time()
    
    def make_sync_request(self, request_id):
        """Make a single synchronous HTTP request"""
        start_time = time.time()
        
        try:
            # Create stock data matching the expected format
            stock_data = {
                "productId": f"PROD_{request_id:06d}",
                "symbol": f"STK{request_id % 100:02d}",
                "productName": f"Product {request_id}",
                "initialQuantity": 100 + (request_id % 50),
                "unitPrice": 10.50 + (request_id % 20),
                "createdBy": "performance-test"
            }
            
            response = requests.post(
                f"{self.results['working_url']}/api/v1/virtual-stock/stocks",
                json=stock_data,
                timeout=3,
                headers={'Content-Type': 'application/json'}
            )
            
            end_time = time.time()
            response_time = end_time - start_time
            
            if response.status_code in [200, 201]:
                self.results['successful_requests'] += 1
                self.results['response_times'].append(response_time)
            else:
                self.results['failed_requests'] += 1
                error_msg = f"HTTP {response.status_code}: {response.text[:100]}"
                self.results['errors'].append(error_msg)
            
            self.results['total_requests'] += 1
                
        except requests.exceptions.Timeout:
            self.results['failed_requests'] += 1
            self.results['total_requests'] += 1
            self.results['errors'].append("Timeout")
            
        except Exception as e:
            self.results['failed_requests'] += 1
            self.results['total_requests'] += 1
            self.results['errors'].append(f"Exception: {str(e)[:100]}")
    
    def generate_report(self):
        """Generate performance test report"""
        if not self.results['start_time'] or not self.results['end_time']:
            return {"error": "Test not completed"}
        
        duration = self.results['end_time'] - self.results['start_time']
        actual_rps = self.results['total_requests'] / duration if duration > 0 else 0
        success_rate = (self.results['successful_requests'] / self.results['total_requests'] * 100) if self.results['total_requests'] > 0 else 0
        
        report = {
            "test_configuration": {
                "strategy": "Free Tier Strategy - Simplified Test",
                "endpoint_used": self.results['working_url'],
                "total_requests": self.results['total_requests'],
                "duration": round(duration, 2),
                "target_rps": 10  # 100 requests / 10 seconds
            },
            "results": {
                "successful_requests": self.results['successful_requests'],
                "failed_requests": self.results['failed_requests'],
                "success_rate_percent": round(success_rate, 2),
                "actual_rps": round(actual_rps, 2)
            },
            "response_times": {
                "count": len(self.results['response_times']),
                "avg_ms": round(statistics.mean(self.results['response_times']) * 1000, 2) if self.results['response_times'] else 0,
                "min_ms": round(min(self.results['response_times']) * 1000, 2) if self.results['response_times'] else 0,
                "max_ms": round(max(self.results['response_times']) * 1000, 2) if self.results['response_times'] else 0,
                "median_ms": round(statistics.median(self.results['response_times']) * 1000, 2) if self.results['response_times'] else 0
            },
            "errors": {
                "total_errors": self.results['failed_requests'],
                "error_samples": list(set(self.results['errors']))[:10]  # Show unique errors
            },
            "performance_analysis": self.analyze_performance(success_rate, actual_rps),
            "timestamp": datetime.now().isoformat()
        }
        
        return report
    
    def analyze_performance(self, success_rate, actual_rps):
        """Analyze performance and provide recommendations"""
        analysis = {
            "overall_rating": "Unknown",
            "bottlenecks": [],
            "recommendations": [],
            "free_tier_assessment": "Unknown"
        }
        
        # Free tier specific assessment
        if success_rate >= 90 and actual_rps >= 5:
            analysis["overall_rating"] = "Excellent for Free Tier"
            analysis["free_tier_assessment"] = "Free tier adequado para desenvolvimento"
        elif success_rate >= 70 and actual_rps >= 3:
            analysis["overall_rating"] = "Good for Free Tier"
            analysis["free_tier_assessment"] = "Free tier funcional mas limitado"
        else:
            analysis["overall_rating"] = "Poor Performance"
            analysis["free_tier_assessment"] = "Free tier insuficiente - requer upgrade"
        
        # Identify bottlenecks
        if success_rate < 80:
            analysis["bottlenecks"].append("Alta taxa de erro - serviços sobrecarregados")
            analysis["recommendations"].append("Considerar estratégia Scalable Simple")
        
        if actual_rps < 5:
            analysis["bottlenecks"].append("Baixo throughput - capacidade limitada")
            analysis["recommendations"].append("Implementar cache Redis")
            analysis["recommendations"].append("Otimizar conexões de banco")
        
        return analysis

def main():
    """Main execution function"""
    test = SimplePerformanceTest()
    
    print("=" * 60)
    print("🎯 KBNT Kafka Logs - Performance Test Free Tier (Simplificado)")
    print("=" * 60)
    
    # Test connectivity first
    test.test_connectivity()
    
    if not test.results['working_url']:
        print("❌ Não foi possível conectar a nenhum serviço!")
        print("💡 Verifique se os containers estão rodando:")
        print("   docker ps")
        return
    
    # Run simplified test
    test.simple_sync_test(target_requests=100, duration=10)
    
    # Generate report
    report = test.generate_report()
    
    print("\n" + "=" * 60)
    print("📊 RELATÓRIO DE PERFORMANCE - FREE TIER")
    print("=" * 60)
    
    # Save detailed report
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    report_file = f"RELATORIO-PERFORMANCE-FREE-TIER-SIMPLES-{timestamp}.json"
    
    with open(report_file, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    # Print summary
    print(f"\n🎯 Configuração do Teste:")
    print(f"   Estratégia: {report['test_configuration']['strategy']}")
    print(f"   Endpoint: {report['test_configuration']['endpoint_used']}")
    print(f"   Duração: {report['test_configuration']['duration']}s")
    
    print(f"\n📈 Resultados:")
    print(f"   Total de Requisições: {report['results']['successful_requests'] + report['results']['failed_requests']}")
    print(f"   Sucessos: {report['results']['successful_requests']}")
    print(f"   Falhas: {report['results']['failed_requests']}")
    print(f"   Taxa de Sucesso: {report['results']['success_rate_percent']}%")
    print(f"   RPS Alcançado: {report['results']['actual_rps']}")
    
    print(f"\n⏱️ Tempos de Resposta:")
    print(f"   Médio: {report['response_times']['avg_ms']}ms")
    print(f"   Mediana: {report['response_times']['median_ms']}ms")
    print(f"   Min/Max: {report['response_times']['min_ms']}ms / {report['response_times']['max_ms']}ms")
    
    print(f"\n🔍 Análise de Performance:")
    print(f"   Classificação: {report['performance_analysis']['overall_rating']}")
    print(f"   Avaliação Free Tier: {report['performance_analysis']['free_tier_assessment']}")
    
    if report['performance_analysis']['bottlenecks']:
        print(f"\n⚠️ Gargalos:")
        for bottleneck in report['performance_analysis']['bottlenecks']:
            print(f"   - {bottleneck}")
    
    if report['performance_analysis']['recommendations']:
        print(f"\n💡 Recomendações:")
        for rec in report['performance_analysis']['recommendations']:
            print(f"   - {rec}")
    
    if report['errors']['error_samples']:
        print(f"\n❌ Amostras de Erro:")
        for error in report['errors']['error_samples'][:5]:
            print(f"   - {error}")
    
    print(f"\n📄 Relatório completo: {report_file}")
    print("=" * 60)

if __name__ == "__main__":
    main()
