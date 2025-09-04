#!/usr/bin/env python3
"""
KBNT Performance Test - Simulação de Carga
==========================================

Este script simula um teste de performance para avaliar diferentes 
estratégias de deployment, sem depender da infraestrutura Docker.

Gera relatório completo de análise de performance simulada.
"""

import asyncio
import time
import json
import uuid
import random
from datetime import datetime, timezone
from dataclasses import dataclass
from typing import List, Dict, Any
import aiohttp
import requests

@dataclass
class PerformanceResult:
    """Resultado de uma estratégia de performance"""
    strategy: str
    total_requests: int
    successful_requests: int
    failed_requests: int
    avg_response_time: float
    min_response_time: float
    max_response_time: float
    requests_per_second: float
    throughput_mb_per_sec: float
    cpu_usage: float
    memory_usage: float
    network_io: float
    
    def success_rate(self) -> float:
        return (self.successful_requests / self.total_requests) * 100 if self.total_requests > 0 else 0

class PerformanceSimulator:
    """Simulador de performance para diferentes estratégias"""
    
    def __init__(self):
        self.strategies = {
            'free-tier': {
                'name': 'Free Tier Strategy',
                'description': 'Configuração mínima para recursos limitados',
                'containers': 8,
                'cpu_cores': 2,
                'memory_gb': 4,
                'network_bandwidth': '100 Mbps',
                'base_latency': 50,  # ms
                'reliability_factor': 0.85,  # 85% de confiabilidade
                'scaling_limit': 100
            },
            'scalable-simple': {
                'name': 'Scalable Simple Strategy',
                'description': 'Configuração balanceada para crescimento moderado',
                'containers': 15,
                'cpu_cores': 4,
                'memory_gb': 8,
                'network_bandwidth': '1 Gbps',
                'base_latency': 30,  # ms
                'reliability_factor': 0.92,  # 92% de confiabilidade
                'scaling_limit': 500
            },
            'scalable-complete': {
                'name': 'Scalable Complete Strategy',
                'description': 'Configuração completa para alta demanda',
                'containers': 25,
                'cpu_cores': 8,
                'memory_gb': 16,
                'network_bandwidth': '10 Gbps',
                'base_latency': 15,  # ms
                'reliability_factor': 0.97,  # 97% de confiabilidade
                'scaling_limit': 2000
            },
            'enterprise': {
                'name': 'Enterprise Strategy',
                'description': 'Configuração empresarial para produção crítica',
                'containers': 40,
                'cpu_cores': 16,
                'memory_gb': 32,
                'network_bandwidth': '25 Gbps',
                'base_latency': 8,   # ms
                'reliability_factor': 0.99,  # 99% de confiabilidade
                'scaling_limit': 10000
            }
        }

    def simulate_request(self, strategy_config: Dict, request_index: int, total_requests: int) -> Dict:
        """Simula uma requisição individual"""
        
        # Fatores de carga baseados na posição no teste
        load_factor = min(request_index / (total_requests * 0.3), 1.0)  # Aumenta até 30% do teste
        
        # Latência base + variação por carga
        base_latency = strategy_config['base_latency']
        latency_ms = base_latency * (1 + load_factor * 0.5) + random.uniform(-5, 15)
        
        # Simula falhas baseado na confiabilidade
        success = random.random() < strategy_config['reliability_factor']
        
        # Simula uso de recursos
        cpu_usage = min(20 + (load_factor * 60) + random.uniform(-10, 20), 100)
        memory_usage = min(30 + (load_factor * 40) + random.uniform(-15, 25), 100)
        network_io = random.uniform(0.5, 3.5)  # MB/s por request
        
        return {
            'success': success,
            'response_time_ms': max(latency_ms, 1),  # Mínimo 1ms
            'cpu_usage': max(cpu_usage, 0),
            'memory_usage': max(memory_usage, 0),
            'network_io_mb': network_io,
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'request_size_kb': random.uniform(0.5, 2.0),
            'response_size_kb': random.uniform(1.0, 5.0)
        }

    async def run_simulation(self, strategy: str, num_requests: int = 1000, duration_seconds: int = 10) -> PerformanceResult:
        """Executa simulação de performance para uma estratégia"""
        
        print(f"🚀 Executando simulação: {self.strategies[strategy]['name']}")
        print(f"   📊 Requisições: {num_requests} | ⏱️  Duração: {duration_seconds}s")
        
        strategy_config = self.strategies[strategy]
        results = []
        
        start_time = time.time()
        
        # Simula requisições distribuídas no tempo
        request_interval = duration_seconds / num_requests
        
        for i in range(num_requests):
            # Simula timing real
            if i > 0:
                await asyncio.sleep(max(request_interval / 1000, 0.001))  # Min 1ms
            
            result = self.simulate_request(strategy_config, i, num_requests)
            results.append(result)
            
            # Progress indicator
            if (i + 1) % 100 == 0 or i == num_requests - 1:
                progress = ((i + 1) / num_requests) * 100
                print(f"   ⏳ Progresso: {progress:.1f}% ({i + 1}/{num_requests})")
        
        end_time = time.time()
        total_duration = end_time - start_time
        
        # Calcula métricas
        successful_requests = sum(1 for r in results if r['success'])
        failed_requests = num_requests - successful_requests
        
        response_times = [r['response_time_ms'] for r in results if r['success']]
        avg_response_time = sum(response_times) / len(response_times) if response_times else 0
        min_response_time = min(response_times) if response_times else 0
        max_response_time = max(response_times) if response_times else 0
        
        requests_per_second = num_requests / total_duration
        
        avg_cpu = sum(r['cpu_usage'] for r in results) / len(results)
        avg_memory = sum(r['memory_usage'] for r in results) / len(results)
        total_network_io = sum(r['network_io_mb'] for r in results)
        throughput_mb_per_sec = total_network_io / total_duration
        
        return PerformanceResult(
            strategy=strategy,
            total_requests=num_requests,
            successful_requests=successful_requests,
            failed_requests=failed_requests,
            avg_response_time=avg_response_time,
            min_response_time=min_response_time,
            max_response_time=max_response_time,
            requests_per_second=requests_per_second,
            throughput_mb_per_sec=throughput_mb_per_sec,
            cpu_usage=avg_cpu,
            memory_usage=avg_memory,
            network_io=total_network_io
        )

    def generate_report(self, results: List[PerformanceResult]) -> Dict:
        """Gera relatório comparativo detalhado"""
        
        report = {
            'metadata': {
                'timestamp': datetime.now(timezone.utc).isoformat(),
                'test_type': 'Performance Simulation',
                'total_strategies': len(results),
                'generated_by': 'KBNT Performance Simulator v1.0'
            },
            'test_parameters': {
                'requests_per_strategy': results[0].total_requests if results else 0,
                'duration_seconds': 10,
                'concurrency_model': 'Simulated Async'
            },
            'results': []
        }
        
        # Ordena resultados por requests per second
        sorted_results = sorted(results, key=lambda x: x.requests_per_second, reverse=True)
        
        for i, result in enumerate(sorted_results):
            strategy_config = self.strategies[result.strategy]
            
            result_data = {
                'rank': i + 1,
                'strategy': result.strategy,
                'name': strategy_config['name'],
                'description': strategy_config['description'],
                'infrastructure': {
                    'containers': strategy_config['containers'],
                    'cpu_cores': strategy_config['cpu_cores'],
                    'memory_gb': strategy_config['memory_gb'],
                    'network_bandwidth': strategy_config['network_bandwidth'],
                    'scaling_limit': strategy_config['scaling_limit']
                },
                'performance_metrics': {
                    'total_requests': result.total_requests,
                    'successful_requests': result.successful_requests,
                    'failed_requests': result.failed_requests,
                    'success_rate_percent': round(result.success_rate(), 2),
                    'requests_per_second': round(result.requests_per_second, 2),
                    'avg_response_time_ms': round(result.avg_response_time, 2),
                    'min_response_time_ms': round(result.min_response_time, 2),
                    'max_response_time_ms': round(result.max_response_time, 2),
                    'throughput_mb_per_sec': round(result.throughput_mb_per_sec, 2)
                },
                'resource_usage': {
                    'avg_cpu_percent': round(result.cpu_usage, 2),
                    'avg_memory_percent': round(result.memory_usage, 2),
                    'total_network_io_mb': round(result.network_io, 2)
                },
                'cost_efficiency': {
                    'requests_per_container': round(result.successful_requests / strategy_config['containers'], 2),
                    'throughput_per_cpu_core': round(result.requests_per_second / strategy_config['cpu_cores'], 2),
                    'efficiency_score': round((result.success_rate() * result.requests_per_second) / (strategy_config['containers'] * 10), 2)
                }
            }
            
            report['results'].append(result_data)
        
        # Adiciona análise comparativa
        best_performance = sorted_results[0]
        worst_performance = sorted_results[-1]
        
        report['analysis'] = {
            'best_strategy': {
                'name': self.strategies[best_performance.strategy]['name'],
                'strategy': best_performance.strategy,
                'requests_per_second': round(best_performance.requests_per_second, 2),
                'success_rate': round(best_performance.success_rate(), 2)
            },
            'worst_strategy': {
                'name': self.strategies[worst_performance.strategy]['name'],
                'strategy': worst_performance.strategy,
                'requests_per_second': round(worst_performance.requests_per_second, 2),
                'success_rate': round(worst_performance.success_rate(), 2)
            },
            'performance_gap': {
                'rps_difference': round(best_performance.requests_per_second - worst_performance.requests_per_second, 2),
                'success_rate_difference': round(best_performance.success_rate() - worst_performance.success_rate(), 2),
                'performance_multiplier': round(best_performance.requests_per_second / worst_performance.requests_per_second, 2) if worst_performance.requests_per_second > 0 else 0
            },
            'recommendations': self._generate_recommendations(sorted_results)
        }
        
        return report

    def _generate_recommendations(self, results: List[PerformanceResult]) -> Dict:
        """Gera recomendações baseadas nos resultados"""
        
        best = results[0]
        
        recommendations = {
            'production_ready': [],
            'cost_optimization': [],
            'scalability': [],
            'reliability': []
        }
        
        for result in results:
            strategy_config = self.strategies[result.strategy]
            
            # Recomendações por categoria
            if result.success_rate() >= 95:
                recommendations['production_ready'].append({
                    'strategy': result.strategy,
                    'reason': f"Alta confiabilidade ({result.success_rate():.1f}% de sucesso)"
                })
            
            if result.strategy == 'free-tier' and result.success_rate() >= 80:
                recommendations['cost_optimization'].append({
                    'strategy': result.strategy,
                    'reason': "Melhor custo-benefício para projetos pequenos"
                })
            
            if strategy_config['scaling_limit'] >= 1000:
                recommendations['scalability'].append({
                    'strategy': result.strategy,
                    'reason': f"Suporta até {strategy_config['scaling_limit']} req/s"
                })
            
            if result.success_rate() >= 90:
                recommendations['reliability'].append({
                    'strategy': result.strategy,
                    'reason': f"Confiabilidade de {result.success_rate():.1f}%"
                })
        
        return recommendations

async def main():
    """Função principal - executa teste completo"""
    print("=" * 60)
    print("🎯 KBNT KAFKA LOGS - TESTE DE PERFORMANCE SIMULADO")
    print("=" * 60)
    print()
    
    simulator = PerformanceSimulator()
    
    # Parâmetros do teste
    num_requests = 1000  # Total de requisições por estratégia
    duration = 10       # Duração em segundos
    
    print(f"📋 Parâmetros do Teste:")
    print(f"   • Requisições por estratégia: {num_requests}")
    print(f"   • Duração: {duration} segundos")
    print(f"   • Estratégias: {len(simulator.strategies)}")
    print()
    
    # Executa simulação para todas as estratégias
    results = []
    for strategy_name in simulator.strategies.keys():
        print(f"🔄 Testando: {simulator.strategies[strategy_name]['name']}")
        result = await simulator.run_simulation(strategy_name, num_requests, duration)
        results.append(result)
        print(f"   ✅ Concluído: {result.successful_requests}/{result.total_requests} sucessos")
        print(f"   📈 Performance: {result.requests_per_second:.1f} req/s")
        print()
    
    # Gera relatório
    print("📊 Gerando relatório comparativo...")
    report = simulator.generate_report(results)
    
    # Salva relatório
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    report_filename = f"performance_simulation_report_{timestamp}.json"
    
    with open(report_filename, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    print(f"💾 Relatório salvo: {report_filename}")
    print()
    
    # Mostra resumo
    print("📈 RESUMO DOS RESULTADOS")
    print("-" * 40)
    
    for i, result_data in enumerate(report['results']):
        print(f"{result_data['rank']}. {result_data['name']}")
        print(f"   Strategy: {result_data['strategy']}")
        print(f"   RPS: {result_data['performance_metrics']['requests_per_second']}")
        print(f"   Success: {result_data['performance_metrics']['success_rate_percent']}%")
        print(f"   Avg Latency: {result_data['performance_metrics']['avg_response_time_ms']}ms")
        print(f"   Containers: {result_data['infrastructure']['containers']}")
        print()
    
    # Mostra análise
    analysis = report['analysis']
    print("🏆 MELHOR ESTRATÉGIA")
    print("-" * 20)
    print(f"Nome: {analysis['best_strategy']['name']}")
    print(f"Performance: {analysis['best_strategy']['requests_per_second']} req/s")
    print(f"Confiabilidade: {analysis['best_strategy']['success_rate']}%")
    print()
    
    print("💡 RECOMENDAÇÕES")
    print("-" * 20)
    
    if analysis['recommendations']['production_ready']:
        print("🚀 Para Produção:")
        for rec in analysis['recommendations']['production_ready']:
            print(f"   • {rec['strategy']}: {rec['reason']}")
    
    if analysis['recommendations']['cost_optimization']:
        print("💰 Custo-Benefício:")
        for rec in analysis['recommendations']['cost_optimization']:
            print(f"   • {rec['strategy']}: {rec['reason']}")
    
    if analysis['recommendations']['scalability']:
        print("📈 Escalabilidade:")
        for rec in analysis['recommendations']['scalability']:
            print(f"   • {rec['strategy']}: {rec['reason']}")
    
    print()
    print("✅ Teste de performance simulado concluído!")
    print(f"📄 Relatório completo disponível em: {report_filename}")

if __name__ == "__main__":
    asyncio.run(main())
