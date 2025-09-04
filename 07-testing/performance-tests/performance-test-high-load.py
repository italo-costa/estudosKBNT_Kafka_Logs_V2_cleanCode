#!/usr/bin/env python3
"""
KBNT Performance Test - Simulação de Alta Carga (100K Requests)
===============================================================

Script otimizado para testes de performance com 100.000+ requisições,
incluindo análise detalhada de CPU/Memória e correlação de atributos.
"""

import asyncio
import time
import json
import uuid
import random
import psutil
import numpy as np
import matplotlib.pyplot as plt
from datetime import datetime, timezone
from dataclasses import dataclass
from typing import List, Dict, Any, Tuple
from collections import defaultdict
import gc
import threading
import os

@dataclass
class DetailedPerformanceResult:
    """Resultado detalhado com métricas de sistema"""
    strategy: str
    name: str
    total_requests: int
    successful_requests: int
    failed_requests: int
    avg_response_time: float
    min_response_time: float
    max_response_time: float
    p50_response_time: float
    p95_response_time: float
    p99_response_time: float
    requests_per_second: float
    throughput_mb_per_sec: float
    avg_cpu_percent: float
    peak_cpu_percent: float
    avg_memory_percent: float
    peak_memory_percent: float
    avg_memory_mb: float
    peak_memory_mb: float
    total_network_io_mb: float
    concurrent_connections: int
    containers: int
    cpu_cores: int
    memory_gb: int
    
    # Métricas de correlação por tecnologia
    kafka_messages: int
    postgres_queries: int
    elasticsearch_operations: int
    redis_operations: int
    api_gateway_requests: int
    
    # Atributos de tráfego
    stock_operations: Dict[str, int]
    distribution_centers: Dict[str, int]
    product_categories: Dict[str, int]
    
    def success_rate(self) -> float:
        return (self.successful_requests / self.total_requests) * 100 if self.total_requests > 0 else 0

class SystemMetricsCollector:
    """Coletor de métricas de sistema em tempo real"""
    
    def __init__(self):
        self.cpu_samples = []
        self.memory_samples = []
        self.network_samples = []
        self.collecting = False
        self.thread = None
        
    def start_collection(self):
        """Inicia coleta de métricas"""
        self.collecting = True
        self.cpu_samples = []
        self.memory_samples = []
        self.network_samples = []
        self.thread = threading.Thread(target=self._collect_metrics)
        self.thread.daemon = True
        self.thread.start()
        
    def stop_collection(self):
        """Para coleta de métricas"""
        self.collecting = False
        if self.thread:
            self.thread.join(timeout=2)
            
    def _collect_metrics(self):
        """Coleta métricas em thread separada"""
        start_network = psutil.net_io_counters()
        
        while self.collecting:
            try:
                # CPU
                cpu_percent = psutil.cpu_percent(interval=0.1)
                self.cpu_samples.append(cpu_percent)
                
                # Memória
                memory = psutil.virtual_memory()
                self.memory_samples.append({
                    'percent': memory.percent,
                    'used_mb': memory.used / (1024 * 1024)
                })
                
                # Network (diferencial)
                current_network = psutil.net_io_counters()
                network_mb = (current_network.bytes_sent + current_network.bytes_recv - 
                             start_network.bytes_sent - start_network.bytes_recv) / (1024 * 1024)
                self.network_samples.append(network_mb)
                
                time.sleep(0.5)  # Sample a cada 500ms
                
            except Exception as e:
                print(f"⚠️ Erro na coleta de métricas: {e}")
                break
    
    def get_metrics_summary(self) -> Dict[str, float]:
        """Retorna resumo das métricas coletadas"""
        if not self.cpu_samples or not self.memory_samples:
            return {
                'avg_cpu_percent': 0.0,
                'peak_cpu_percent': 0.0,
                'avg_memory_percent': 0.0,
                'peak_memory_percent': 0.0,
                'avg_memory_mb': 0.0,
                'peak_memory_mb': 0.0,
                'total_network_io_mb': 0.0
            }
        
        memory_percents = [m['percent'] for m in self.memory_samples]
        memory_mbs = [m['used_mb'] for m in self.memory_samples]
        
        return {
            'avg_cpu_percent': np.mean(self.cpu_samples),
            'peak_cpu_percent': np.max(self.cpu_samples),
            'avg_memory_percent': np.mean(memory_percents),
            'peak_memory_percent': np.max(memory_percents),
            'avg_memory_mb': np.mean(memory_mbs),
            'peak_memory_mb': np.max(memory_mbs),
            'total_network_io_mb': self.network_samples[-1] if self.network_samples else 0.0
        }

class HighLoadPerformanceSimulator:
    """Simulador otimizado para alta carga"""
    
    def __init__(self):
        self.strategies = {
            'free-tier': {
                'name': 'Free Tier Strategy',
                'description': 'Configuração mínima para recursos limitados',
                'containers': 8,
                'cpu_cores': 2,
                'memory_gb': 4,
                'network_bandwidth': '100 Mbps',
                'scaling_limit': 500,
                'base_latency': 75.0,
                'failure_rate': 0.14,
                'concurrent_limit': 50
            },
            'scalable-simple': {
                'name': 'Scalable Simple Strategy',
                'description': 'Configuração balanceada para crescimento moderado',
                'containers': 15,
                'cpu_cores': 4,
                'memory_gb': 8,
                'network_bandwidth': '1 Gbps',
                'scaling_limit': 1000,
                'base_latency': 45.0,
                'failure_rate': 0.08,
                'concurrent_limit': 150
            },
            'scalable-complete': {
                'name': 'Scalable Complete Strategy',
                'description': 'Configuração completa para alta demanda',
                'containers': 25,
                'cpu_cores': 8,
                'memory_gb': 16,
                'network_bandwidth': '10 Gbps',
                'scaling_limit': 5000,
                'base_latency': 25.0,
                'failure_rate': 0.03,
                'concurrent_limit': 500
            },
            'enterprise': {
                'name': 'Enterprise Strategy',
                'description': 'Configuração empresarial para máxima performance',
                'containers': 40,
                'cpu_cores': 16,
                'memory_gb': 32,
                'network_bandwidth': '100 Gbps',
                'scaling_limit': 20000,
                'base_latency': 15.0,
                'failure_rate': 0.01,
                'concurrent_limit': 2000
            }
        }
        
        # Atributos de tráfego para correlação
        self.operations = ['ADD', 'REMOVE', 'SET', 'TRANSFER']
        self.distribution_centers = ['DC-SP01', 'DC-RJ01', 'DC-MG01', 'DC-RS01', 'DC-PR01']
        self.product_categories = ['SMARTPHONE', 'NOTEBOOK', 'TABLET', 'MONITOR', 'TECLADO', 'MOUSE']
        
    async def simulate_strategy(self, strategy_key: str, config: Dict, num_requests: int) -> DetailedPerformanceResult:
        """Simula uma estratégia específica com alta carga"""
        print(f"🚀 Executando simulação: {config['name']}")
        print(f"   📊 Requisições: {num_requests:,} | 🔧 Containers: {config['containers']}")
        
        # Iniciar coleta de métricas
        metrics_collector = SystemMetricsCollector()
        metrics_collector.start_collection()
        
        # Variáveis de resultado
        response_times = []
        successful = 0
        failed = 0
        
        # Contadores por tecnologia
        kafka_messages = 0
        postgres_queries = 0
        elasticsearch_ops = 0
        redis_ops = 0
        api_gateway_reqs = 0
        
        # Contadores de atributos
        stock_ops = defaultdict(int)
        dc_counts = defaultdict(int)
        product_counts = defaultdict(int)
        
        start_time = time.time()
        concurrent_tasks = []
        semaphore = asyncio.Semaphore(config['concurrent_limit'])
        
        async def process_request(request_id: int):
            async with semaphore:
                # Simular latência baseada na configuração
                base_latency = config['base_latency']
                latency_variation = random.uniform(0.5, 1.5)
                
                # Adicionar latência baseada na carga
                load_factor = min(len(concurrent_tasks) / config['concurrent_limit'], 1.0)
                latency = base_latency * latency_variation * (1 + load_factor * 0.5)
                
                # Simular processamento
                await asyncio.sleep(latency / 1000)  # Converter para segundos
                
                # Determinar sucesso/falha
                if random.random() > config['failure_rate']:
                    return {
                        'success': True,
                        'response_time': latency,
                        'operation': random.choice(self.operations),
                        'dc': random.choice(self.distribution_centers),
                        'product': random.choice(self.product_categories)
                    }
                else:
                    return {
                        'success': False,
                        'response_time': latency * 2,  # Erros demoram mais
                        'operation': 'FAILED',
                        'dc': 'UNKNOWN',
                        'product': 'UNKNOWN'
                    }
        
        # Processar requests em batches para otimizar memória
        batch_size = 1000
        batches = [range(i, min(i + batch_size, num_requests)) for i in range(0, num_requests, batch_size)]
        
        for batch_idx, batch in enumerate(batches):
            print(f"   ⏳ Processando batch {batch_idx + 1}/{len(batches)} ({len(batch)} requests)")
            
            # Criar tasks para o batch
            tasks = [process_request(req_id) for req_id in batch]
            
            # Executar batch
            batch_results = await asyncio.gather(*tasks, return_exceptions=True)
            
            # Processar resultados
            for result in batch_results:
                if isinstance(result, dict):
                    response_times.append(result['response_time'])
                    
                    if result['success']:
                        successful += 1
                        
                        # Contar por tecnologia (simulado)
                        kafka_messages += 1
                        if result['operation'] in ['ADD', 'REMOVE']:
                            postgres_queries += 1
                        if result['operation'] == 'SET':
                            elasticsearch_ops += 1
                        redis_ops += 1
                        api_gateway_reqs += 1
                        
                        # Contar atributos
                        stock_ops[result['operation']] += 1
                        dc_counts[result['dc']] += 1
                        product_counts[result['product']] += 1
                    else:
                        failed += 1
                        
            # Progress
            completed = (batch_idx + 1) * batch_size
            progress = min(completed / num_requests * 100, 100)
            print(f"   📈 Progresso: {progress:.1f}% ({min(completed, num_requests):,}/{num_requests:,})")
            
            # Limpar memória
            if batch_idx % 10 == 0:
                gc.collect()
        
        end_time = time.time()
        duration = end_time - start_time
        
        # Parar coleta de métricas
        metrics_collector.stop_collection()
        system_metrics = metrics_collector.get_metrics_summary()
        
        # Calcular estatísticas
        if response_times:
            avg_response_time = np.mean(response_times)
            min_response_time = np.min(response_times)
            max_response_time = np.max(response_times)
            p50_response_time = np.percentile(response_times, 50)
            p95_response_time = np.percentile(response_times, 95)
            p99_response_time = np.percentile(response_times, 99)
        else:
            avg_response_time = min_response_time = max_response_time = 0
            p50_response_time = p95_response_time = p99_response_time = 0
        
        rps = successful / duration if duration > 0 else 0
        throughput = (successful * 0.5) / duration if duration > 0 else 0  # Estimativa KB por request
        
        print(f"   ✅ Concluído: {successful:,}/{num_requests:,} sucessos")
        print(f"   📈 Performance: {rps:.1f} req/s")
        print(f"   💾 Uso de Memória: {system_metrics['avg_memory_mb']:.1f} MB (pico: {system_metrics['peak_memory_mb']:.1f} MB)")
        print(f"   🔥 Uso de CPU: {system_metrics['avg_cpu_percent']:.1f}% (pico: {system_metrics['peak_cpu_percent']:.1f}%)")
        
        return DetailedPerformanceResult(
            strategy=strategy_key,
            name=config['name'],
            total_requests=num_requests,
            successful_requests=successful,
            failed_requests=failed,
            avg_response_time=avg_response_time,
            min_response_time=min_response_time,
            max_response_time=max_response_time,
            p50_response_time=p50_response_time,
            p95_response_time=p95_response_time,
            p99_response_time=p99_response_time,
            requests_per_second=rps,
            throughput_mb_per_sec=throughput,
            avg_cpu_percent=system_metrics['avg_cpu_percent'],
            peak_cpu_percent=system_metrics['peak_cpu_percent'],
            avg_memory_percent=system_metrics['avg_memory_percent'],
            peak_memory_percent=system_metrics['peak_memory_percent'],
            avg_memory_mb=system_metrics['avg_memory_mb'],
            peak_memory_mb=system_metrics['peak_memory_mb'],
            total_network_io_mb=system_metrics['total_network_io_mb'],
            concurrent_connections=config['concurrent_limit'],
            containers=config['containers'],
            cpu_cores=config['cpu_cores'],
            memory_gb=config['memory_gb'],
            kafka_messages=kafka_messages,
            postgres_queries=postgres_queries,
            elasticsearch_operations=elasticsearch_ops,
            redis_operations=redis_ops,
            api_gateway_requests=api_gateway_reqs,
            stock_operations=dict(stock_ops),
            distribution_centers=dict(dc_counts),
            product_categories=dict(product_counts)
        )
    
    async def run_high_load_test(self, num_requests: int = 100000):
        """Executa teste de alta carga"""
        print("=" * 70)
        print("🎯 KBNT KAFKA LOGS - TESTE DE ALTA CARGA")
        print("=" * 70)
        print(f"📊 Requisições por estratégia: {num_requests:,}")
        print(f"🔧 Total de requisições: {num_requests * len(self.strategies):,}")
        print(f"⏱️ Estratégias: {len(self.strategies)}")
        print("=" * 70)
        print()
        
        results = []
        
        for strategy_key, config in self.strategies.items():
            print(f"🔄 Testando: {config['name']}")
            result = await self.simulate_strategy(strategy_key, config, num_requests)
            results.append(result)
            print()
        
        return results

def create_comparison_charts(results_1k: List, results_100k: List):
    """Cria gráficos de comparação entre testes 1K e 100K"""
    
    # Configurar matplotlib
    plt.style.use('default')
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(16, 12))
    fig.suptitle('Comparação de Performance: 1K vs 100K Requests', fontsize=16, fontweight='bold')
    
    strategies = [r.name for r in results_100k]
    
    # 1. RPS Comparison
    rps_1k = [72.5, 75.8, 79.3, 77.5]  # Dados médios dos testes anteriores
    rps_100k = [r.requests_per_second for r in results_100k]
    
    x = np.arange(len(strategies))
    width = 0.35
    
    ax1.bar(x - width/2, rps_1k, width, label='1K Requests', color='skyblue', alpha=0.8)
    ax1.bar(x + width/2, rps_100k, width, label='100K Requests', color='orange', alpha=0.8)
    ax1.set_xlabel('Estratégias')
    ax1.set_ylabel('Requests per Second')
    ax1.set_title('Performance: RPS Comparison')
    ax1.set_xticks(x)
    ax1.set_xticklabels([s.split()[0] for s in strategies], rotation=45)
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # 2. CPU Usage
    cpu_avg = [r.avg_cpu_percent for r in results_100k]
    cpu_peak = [r.peak_cpu_percent for r in results_100k]
    
    ax2.bar(x - width/2, cpu_avg, width, label='Avg CPU %', color='lightgreen', alpha=0.8)
    ax2.bar(x + width/2, cpu_peak, width, label='Peak CPU %', color='red', alpha=0.8)
    ax2.set_xlabel('Estratégias')
    ax2.set_ylabel('CPU Usage (%)')
    ax2.set_title('CPU Usage: Average vs Peak')
    ax2.set_xticks(x)
    ax2.set_xticklabels([s.split()[0] for s in strategies], rotation=45)
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # 3. Memory Usage
    mem_avg = [r.avg_memory_mb for r in results_100k]
    mem_peak = [r.peak_memory_mb for r in results_100k]
    
    ax3.bar(x - width/2, mem_avg, width, label='Avg Memory (MB)', color='lightblue', alpha=0.8)
    ax3.bar(x + width/2, mem_peak, width, label='Peak Memory (MB)', color='darkblue', alpha=0.8)
    ax3.set_xlabel('Estratégias')
    ax3.set_ylabel('Memory Usage (MB)')
    ax3.set_title('Memory Usage: Average vs Peak')
    ax3.set_xticks(x)
    ax3.set_xticklabels([s.split()[0] for s in strategies], rotation=45)
    ax3.legend()
    ax3.grid(True, alpha=0.3)
    
    # 4. Success Rate Comparison
    success_1k = [86.1, 92.8, 97.1, 99.0]  # Dados médios anteriores
    success_100k = [r.success_rate() for r in results_100k]
    
    ax4.bar(x - width/2, success_1k, width, label='1K Requests', color='lightcoral', alpha=0.8)
    ax4.bar(x + width/2, success_100k, width, label='100K Requests', color='darkgreen', alpha=0.8)
    ax4.set_xlabel('Estratégias')
    ax4.set_ylabel('Success Rate (%)')
    ax4.set_title('Success Rate Comparison')
    ax4.set_xticks(x)
    ax4.set_xticklabels([s.split()[0] for s in strategies], rotation=45)
    ax4.legend()
    ax4.grid(True, alpha=0.3)
    
    plt.tight_layout()
    filename = f"performance_comparison_chart_{datetime.now().strftime('%Y%m%d_%H%M%S')}.png"
    plt.savefig(filename, dpi=300, bbox_inches='tight')
    print(f"📊 Gráfico salvo: {filename}")
    plt.close()
    
    return filename

async def main():
    """Função principal"""
    simulator = HighLoadPerformanceSimulator()
    
    # Executar teste de 100K
    results_100k = await simulator.run_high_load_test(100000)
    
    # Gerar relatório JSON
    report = {
        'metadata': {
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'test_type': 'High Load Performance Test',
            'total_requests': 400000,
            'requests_per_strategy': 100000,
            'strategies_tested': len(results_100k)
        },
        'results': []
    }
    
    for result in results_100k:
        report['results'].append({
            'strategy': result.strategy,
            'name': result.name,
            'performance': {
                'total_requests': result.total_requests,
                'successful_requests': result.successful_requests,
                'success_rate_percent': result.success_rate(),
                'requests_per_second': result.requests_per_second,
                'avg_response_time_ms': result.avg_response_time,
                'p95_response_time_ms': result.p95_response_time,
                'p99_response_time_ms': result.p99_response_time
            },
            'system_resources': {
                'avg_cpu_percent': result.avg_cpu_percent,
                'peak_cpu_percent': result.peak_cpu_percent,
                'avg_memory_mb': result.avg_memory_mb,
                'peak_memory_mb': result.peak_memory_mb,
                'total_network_io_mb': result.total_network_io_mb
            },
            'technology_correlation': {
                'kafka_messages': result.kafka_messages,
                'postgres_queries': result.postgres_queries,
                'elasticsearch_operations': result.elasticsearch_operations,
                'redis_operations': result.redis_operations,
                'api_gateway_requests': result.api_gateway_requests
            },
            'traffic_attributes': {
                'stock_operations': result.stock_operations,
                'distribution_centers': result.distribution_centers,
                'product_categories': result.product_categories
            }
        })
    
    # Salvar relatório
    filename = f"high_load_performance_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False, default=str)
    
    print("=" * 70)
    print("📊 RESUMO DO TESTE DE ALTA CARGA")
    print("=" * 70)
    
    # Ordenar por RPS
    sorted_results = sorted(results_100k, key=lambda x: x.requests_per_second, reverse=True)
    
    for i, result in enumerate(sorted_results, 1):
        print(f"{i}. {result.name}")
        print(f"   RPS: {result.requests_per_second:.1f}")
        print(f"   Sucesso: {result.success_rate():.1f}%")
        print(f"   CPU: {result.avg_cpu_percent:.1f}% (pico: {result.peak_cpu_percent:.1f}%)")
        print(f"   Memória: {result.avg_memory_mb:.1f} MB (pico: {result.peak_memory_mb:.1f} MB)")
        print(f"   P95 Latency: {result.p95_response_time:.1f}ms")
        print()
    
    # Criar gráficos de comparação
    create_comparison_charts([], results_100k)
    
    print(f"💾 Relatório completo salvo: {filename}")
    print("✅ Teste de alta carga concluído!")

if __name__ == "__main__":
    asyncio.run(main())
