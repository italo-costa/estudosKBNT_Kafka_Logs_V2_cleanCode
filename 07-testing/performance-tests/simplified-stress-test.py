#!/usr/bin/env python3
"""
Testes de Stress e Carga Simplificado com Visualização Gráfica
Foca nos serviços principais que estão funcionando
"""

import os
import sys
import time
import json
import requests
import threading
import subprocess
import statistics
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import seaborn as sns
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
from collections import defaultdict

class SimplifiedStressTestManager:
    def __init__(self, workspace_root):
        self.workspace_root = Path(workspace_root)
        self.microservices_path = self.workspace_root / '05-microservices'
        self.compose_file = self.microservices_path / 'docker-compose.yml'
        self.results = defaultdict(list)
        self.test_results = {}
        self.start_time = datetime.now()
        
        # Configurar estilo dos gráficos
        plt.style.use('seaborn-v0_8')
        sns.set_palette("husl")
        
        # Endpoints para teste - apenas os básicos que funcionam
        self.endpoints = {
            'api_gateway_health': 'http://localhost:8080/actuator/health',
            'api_gateway_info': 'http://localhost:8080/actuator/info',
        }
        
    def check_docker_status(self):
        """Verifica status do Docker no WSL"""
        print("🐳 Verificando Docker no ambiente Linux virtualizado (WSL)...")
        
        try:
            result = subprocess.run(['wsl', 'docker', '--version'], capture_output=True, text=True)
            if result.returncode == 0:
                print(f"✅ Docker WSL: {result.stdout.strip()}")
                return True
            else:
                print("❌ Docker não encontrado no WSL")
                return False
                
        except Exception as e:
            print(f"❌ Erro ao verificar Docker: {e}")
            return False
    
    def start_api_gateway_only(self):
        """Inicia apenas o API Gateway para testes"""
        print("\n🚀 Iniciando API Gateway no WSL...")
        
        try:
            wsl_path = str(self.microservices_path).replace('\\', '/').replace('C:', '/mnt/c')
            
            # Para containers existentes
            print("🧹 Limpando ambiente...")
            subprocess.run([
                'wsl', 'bash', '-c', 
                f'cd {wsl_path} && docker-compose down -v --remove-orphans'
            ], capture_output=True)
            
            # Inicia apenas o API Gateway
            print("📦 Iniciando API Gateway...")
            result = subprocess.run([
                'wsl', 'bash', '-c',
                f'cd {wsl_path} && docker-compose up -d api-gateway'
            ], capture_output=True, text=True)
            
            if result.returncode == 0:
                print("✅ API Gateway iniciado com sucesso no WSL")
                return True
            else:
                print(f"❌ Erro ao iniciar API Gateway: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ Erro ao iniciar aplicação: {e}")
            return False
    
    def wait_for_api_gateway(self, timeout=120):
        """Aguarda o API Gateway ficar disponível"""
        print(f"\n⏰ Aguardando API Gateway ficar disponível (timeout: {timeout}s)...")
        
        start_time = time.time()
        
        while time.time() - start_time < timeout:
            try:
                response = requests.get(self.endpoints['api_gateway_health'], timeout=5)
                if response.status_code == 200:
                    print("✅ API Gateway está disponível!")
                    return True
            except:
                pass
            
            elapsed = int(time.time() - start_time)
            print(f"⏳ Aguardando... ({elapsed}s/{timeout}s)")
            time.sleep(5)
        
        print(f"❌ Timeout aguardando API Gateway")
        return False
    
    def single_request(self, endpoint_name, url, request_id):
        """Executa uma única requisição e coleta métricas"""
        try:
            start_time = time.time()
            response = requests.get(url, timeout=10)
            end_time = time.time()
            
            response_time = (end_time - start_time) * 1000  # em ms
            
            return {
                'request_id': request_id,
                'endpoint': endpoint_name,
                'url': url,
                'status_code': response.status_code,
                'response_time': response_time,
                'timestamp': datetime.now(),
                'success': 200 <= response.status_code < 400,
                'content_length': len(response.content) if response.content else 0
            }
        except Exception as e:
            return {
                'request_id': request_id,
                'endpoint': endpoint_name,
                'url': url,
                'status_code': 0,
                'response_time': 10000,  # timeout
                'timestamp': datetime.now(),
                'success': False,
                'error': str(e),
                'content_length': 0
            }
    
    def load_test(self, endpoint_name, url, num_requests=1000, max_workers=20):
        """Executa teste de carga em um endpoint específico"""
        print(f"\n🎯 Teste de carga: {endpoint_name} ({num_requests} requisições, {max_workers} workers)")
        
        results = []
        start_time = time.time()
        
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            futures = []
            for i in range(num_requests):
                future = executor.submit(self.single_request, endpoint_name, url, i)
                futures.append(future)
            
            # Coleta resultados conforme completam
            completed = 0
            for future in as_completed(futures):
                result = future.result()
                results.append(result)
                completed += 1
                
                # Progress feedback
                if completed % 100 == 0:
                    elapsed = time.time() - start_time
                    rate = completed / elapsed if elapsed > 0 else 0
                    print(f"  📊 {completed}/{num_requests} concluídas ({elapsed:.1f}s, {rate:.1f} req/s)")
        
        end_time = time.time()
        total_time = end_time - start_time
        
        # Análise dos resultados
        successful = [r for r in results if r['success']]
        failed = [r for r in results if not r['success']]
        
        response_times = [r['response_time'] for r in successful]
        
        stats = {
            'endpoint': endpoint_name,
            'total_requests': num_requests,
            'successful_requests': len(successful),
            'failed_requests': len(failed),
            'success_rate': len(successful) / num_requests * 100,
            'total_time': total_time,
            'requests_per_second': num_requests / total_time,
            'response_times': response_times,
            'avg_response_time': statistics.mean(response_times) if response_times else 0,
            'median_response_time': statistics.median(response_times) if response_times else 0,
            'min_response_time': min(response_times) if response_times else 0,
            'max_response_time': max(response_times) if response_times else 0,
            'p95_response_time': np.percentile(response_times, 95) if response_times else 0,
            'p99_response_time': np.percentile(response_times, 99) if response_times else 0,
            'raw_results': results
        }
        
        print(f"✅ Teste concluído:")
        print(f"   📊 Taxa de sucesso: {stats['success_rate']:.1f}%")
        print(f"   🚀 Throughput: {stats['requests_per_second']:.1f} req/s")
        print(f"   ⏱️ Tempo médio: {stats['avg_response_time']:.1f}ms")
        print(f"   📈 P95: {stats['p95_response_time']:.1f}ms")
        print(f"   📈 P99: {stats['p99_response_time']:.1f}ms")
        
        return stats
    
    def stress_test_suite(self):
        """Executa uma suíte progressiva de testes de stress"""
        print("\n🔥 Iniciando suíte de testes de stress e carga...")
        
        test_scenarios = [
            # Testes progressivos
            ('api_gateway_health', 100, 5),    # Warmup
            ('api_gateway_health', 500, 10),   # Baixa carga
            ('api_gateway_health', 1000, 20),  # Média carga
            ('api_gateway_health', 2000, 30),  # Alta carga
            ('api_gateway_health', 5000, 50),  # Stress test
            
            # Testes no endpoint info
            ('api_gateway_info', 100, 5),
            ('api_gateway_info', 500, 10),
            ('api_gateway_info', 1000, 20),
            ('api_gateway_info', 2000, 30),
        ]
        
        all_results = {}
        
        for i, (endpoint_name, num_requests, max_workers) in enumerate(test_scenarios, 1):
            if endpoint_name in self.endpoints:
                url = self.endpoints[endpoint_name]
                
                print(f"\n{'='*80}")
                print(f"🎯 TESTE {i}/{len(test_scenarios)}: {endpoint_name}")
                print(f"📝 URL: {url}")
                print(f"📊 Requisições: {num_requests:,}")
                print(f"👥 Workers concorrentes: {max_workers}")
                print(f"{'='*80}")
                
                result = self.load_test(endpoint_name, url, num_requests, max_workers)
                test_key = f"{endpoint_name}_{num_requests}_workers_{max_workers}"
                all_results[test_key] = result
                
                # Pausa entre testes para não sobrecarregar
                if i < len(test_scenarios):
                    print("⏸️ Pausa de 3 segundos entre testes...")
                    time.sleep(3)
        
        self.test_results = all_results
        return all_results
    
    def generate_comprehensive_graphs(self):
        """Gera gráficos abrangentes dos resultados dos testes"""
        print("\n📊 Gerando gráficos de performance...")
        
        if not self.test_results:
            print("❌ Nenhum resultado de teste disponível")
            return
        
        # Criar diretório para gráficos
        graphs_dir = self.workspace_root / 'stress_test_graphs'
        graphs_dir.mkdir(exist_ok=True)
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # 1. Dashboard de Métricas Principais
        self._create_main_dashboard(graphs_dir, timestamp)
        
        # 2. Análise de Escalabilidade
        self._create_scalability_analysis(graphs_dir, timestamp)
        
        # 3. Distribuição de Tempos de Resposta
        self._create_response_distribution(graphs_dir, timestamp)
        
        # 4. Timeline de Performance
        self._create_performance_timeline(graphs_dir, timestamp)
        
        # 5. Análise Comparativa
        self._create_comparative_analysis(graphs_dir, timestamp)
        
        print(f"✅ Gráficos salvos em: {graphs_dir}")
        
    def _create_main_dashboard(self, graphs_dir, timestamp):
        """Cria dashboard principal com métricas essenciais"""
        fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(20, 16))
        
        # Preparar dados
        test_names = []
        throughput = []
        avg_response = []
        success_rates = []
        p95_times = []
        
        for test_name, result in self.test_results.items():
            clean_name = test_name.replace('api_gateway_', '').replace('_', ' ')
            test_names.append(clean_name)
            throughput.append(result['requests_per_second'])
            avg_response.append(result['avg_response_time'])
            success_rates.append(result['success_rate'])
            p95_times.append(result['p95_response_time'])
        
        # 1. Throughput
        bars1 = ax1.bar(range(len(test_names)), throughput, color='skyblue', alpha=0.8)
        ax1.set_title('Throughput (Requisições/segundo)', fontsize=14, fontweight='bold')
        ax1.set_ylabel('Req/s')
        ax1.set_xticks(range(len(test_names)))
        ax1.set_xticklabels(test_names, rotation=45, ha='right')
        ax1.grid(True, alpha=0.3)
        
        # Adicionar valores nas barras
        for bar, value in zip(bars1, throughput):
            height = bar.get_height()
            ax1.text(bar.get_x() + bar.get_width()/2., height + 1,
                    f'{value:.0f}', ha='center', va='bottom', fontweight='bold')
        
        # 2. Tempo de Resposta Médio
        bars2 = ax2.bar(range(len(test_names)), avg_response, color='lightcoral', alpha=0.8)
        ax2.set_title('Tempo de Resposta Médio', fontsize=14, fontweight='bold')
        ax2.set_ylabel('Tempo (ms)')
        ax2.set_xticks(range(len(test_names)))
        ax2.set_xticklabels(test_names, rotation=45, ha='right')
        ax2.grid(True, alpha=0.3)
        
        for bar, value in zip(bars2, avg_response):
            height = bar.get_height()
            ax2.text(bar.get_x() + bar.get_width()/2., height + 1,
                    f'{value:.0f}ms', ha='center', va='bottom', fontweight='bold')
        
        # 3. Taxa de Sucesso
        colors3 = ['green' if rate >= 95 else 'orange' if rate >= 90 else 'red' for rate in success_rates]
        bars3 = ax3.bar(range(len(test_names)), success_rates, color=colors3, alpha=0.8)
        ax3.set_title('Taxa de Sucesso', fontsize=14, fontweight='bold')
        ax3.set_ylabel('Sucesso (%)')
        ax3.set_ylim(0, 105)
        ax3.set_xticks(range(len(test_names)))
        ax3.set_xticklabels(test_names, rotation=45, ha='right')
        ax3.axhline(y=95, color='red', linestyle='--', alpha=0.5, label='Meta: 95%')
        ax3.grid(True, alpha=0.3)
        ax3.legend()
        
        for bar, value in zip(bars3, success_rates):
            height = bar.get_height()
            ax3.text(bar.get_x() + bar.get_width()/2., height + 0.5,
                    f'{value:.1f}%', ha='center', va='bottom', fontweight='bold')
        
        # 4. P95 Response Time
        bars4 = ax4.bar(range(len(test_names)), p95_times, color='mediumpurple', alpha=0.8)
        ax4.set_title('P95 Tempo de Resposta', fontsize=14, fontweight='bold')
        ax4.set_ylabel('Tempo (ms)')
        ax4.set_xticks(range(len(test_names)))
        ax4.set_xticklabels(test_names, rotation=45, ha='right')
        ax4.grid(True, alpha=0.3)
        
        for bar, value in zip(bars4, p95_times):
            height = bar.get_height()
            ax4.text(bar.get_x() + bar.get_width()/2., height + 1,
                    f'{value:.0f}ms', ha='center', va='bottom', fontweight='bold')
        
        plt.suptitle('Dashboard de Performance - Testes de Stress API Gateway', 
                    fontsize=18, fontweight='bold', y=0.98)
        plt.tight_layout()
        plt.subplots_adjust(top=0.93)
        plt.savefig(graphs_dir / f'dashboard_{timestamp}.png', dpi=300, bbox_inches='tight')
        plt.close()
        
    def _create_scalability_analysis(self, graphs_dir, timestamp):
        """Cria análise de escalabilidade baseada no número de requisições"""
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(18, 8))
        
        # Separar resultados por endpoint
        health_results = []
        info_results = []
        
        for test_name, result in self.test_results.items():
            if 'health' in test_name:
                health_results.append((result['total_requests'], result))
            elif 'info' in test_name:
                info_results.append((result['total_requests'], result))
        
        # Ordenar por número de requisições
        health_results.sort(key=lambda x: x[0])
        info_results.sort(key=lambda x: x[0])
        
        # Gráfico 1: Throughput vs Carga
        if health_results:
            health_requests = [r[0] for r in health_results]
            health_throughput = [r[1]['requests_per_second'] for r in health_results]
            ax1.plot(health_requests, health_throughput, 'o-', label='Health Endpoint', 
                    linewidth=2, markersize=8)
        
        if info_results:
            info_requests = [r[0] for r in info_results]
            info_throughput = [r[1]['requests_per_second'] for r in info_results]
            ax1.plot(info_requests, info_throughput, 's-', label='Info Endpoint', 
                    linewidth=2, markersize=8)
        
        ax1.set_title('Escalabilidade: Throughput vs Carga', fontsize=14, fontweight='bold')
        ax1.set_xlabel('Número de Requisições')
        ax1.set_ylabel('Throughput (req/s)')
        ax1.legend()
        ax1.grid(True, alpha=0.3)
        
        # Gráfico 2: Tempo de Resposta vs Carga
        if health_results:
            health_response_times = [r[1]['avg_response_time'] for r in health_results]
            ax2.plot(health_requests, health_response_times, 'o-', label='Health Endpoint', 
                    linewidth=2, markersize=8)
        
        if info_results:
            info_response_times = [r[1]['avg_response_time'] for r in info_results]
            ax2.plot(info_requests, info_response_times, 's-', label='Info Endpoint', 
                    linewidth=2, markersize=8)
        
        ax2.set_title('Escalabilidade: Tempo de Resposta vs Carga', fontsize=14, fontweight='bold')
        ax2.set_xlabel('Número de Requisições')
        ax2.set_ylabel('Tempo de Resposta Médio (ms)')
        ax2.legend()
        ax2.grid(True, alpha=0.3)
        
        plt.tight_layout()
        plt.savefig(graphs_dir / f'scalability_{timestamp}.png', dpi=300, bbox_inches='tight')
        plt.close()
        
    def _create_response_distribution(self, graphs_dir, timestamp):
        """Cria histogramas de distribuição dos tempos de resposta"""
        # Pegar alguns testes representativos
        representative_tests = list(self.test_results.items())[:6]
        
        fig, axes = plt.subplots(2, 3, figsize=(20, 12))
        axes = axes.flatten()
        
        for i, (test_name, result) in enumerate(representative_tests):
            if i >= 6:
                break
                
            ax = axes[i]
            response_times = result['response_times']
            
            if response_times:
                # Histograma
                ax.hist(response_times, bins=30, alpha=0.7, edgecolor='black', color='skyblue')
                
                # Linhas de referência
                ax.axvline(result['avg_response_time'], color='red', linestyle='--', 
                          label=f'Média: {result["avg_response_time"]:.1f}ms', linewidth=2)
                ax.axvline(result['median_response_time'], color='green', linestyle='--',
                          label=f'Mediana: {result["median_response_time"]:.1f}ms', linewidth=2)
                ax.axvline(result['p95_response_time'], color='orange', linestyle='--',
                          label=f'P95: {result["p95_response_time"]:.1f}ms', linewidth=2)
            
            clean_name = test_name.replace('api_gateway_', '').replace('_', ' ')
            ax.set_title(clean_name, fontsize=12, fontweight='bold')
            ax.set_xlabel('Tempo de Resposta (ms)')
            ax.set_ylabel('Frequência')
            ax.legend(fontsize=8)
            ax.grid(True, alpha=0.3)
        
        # Remove eixos não utilizados
        for i in range(len(representative_tests), 6):
            axes[i].remove()
        
        plt.suptitle('Distribuição dos Tempos de Resposta', fontsize=16, fontweight='bold')
        plt.tight_layout()
        plt.savefig(graphs_dir / f'distribution_{timestamp}.png', dpi=300, bbox_inches='tight')
        plt.close()
        
    def _create_performance_timeline(self, graphs_dir, timestamp):
        """Cria timeline das requisições ao longo do tempo"""
        fig, ax = plt.subplots(figsize=(16, 10))
        
        colors = plt.cm.tab10(np.linspace(0, 1, len(self.test_results)))
        
        for i, (test_name, result) in enumerate(self.test_results.items()):
            timestamps = [r['timestamp'] for r in result['raw_results']]
            response_times = [r['response_time'] for r in result['raw_results']]
            
            # Pega uma amostra para visualização
            sample_size = min(100, len(timestamps))
            if sample_size > 0:
                sample_indices = np.random.choice(len(timestamps), sample_size, replace=False)
                sample_timestamps = [timestamps[idx] for idx in sample_indices]
                sample_response_times = [response_times[idx] for idx in sample_indices]
                
                clean_name = test_name.replace('api_gateway_', '').replace('_', ' ')
                ax.scatter(sample_timestamps, sample_response_times, 
                          alpha=0.6, s=30, color=colors[i], label=clean_name)
        
        ax.set_title('Timeline dos Tempos de Resposta', fontsize=16, fontweight='bold')
        ax.set_xlabel('Timestamp', fontsize=12)
        ax.set_ylabel('Tempo de Resposta (ms)', fontsize=12)
        ax.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
        ax.grid(True, alpha=0.3)
        
        # Format x-axis
        ax.xaxis.set_major_formatter(mdates.DateFormatter('%H:%M:%S'))
        plt.xticks(rotation=45)
        
        plt.tight_layout()
        plt.savefig(graphs_dir / f'timeline_{timestamp}.png', dpi=300, bbox_inches='tight')
        plt.close()
        
    def _create_comparative_analysis(self, graphs_dir, timestamp):
        """Cria análise comparativa entre endpoints"""
        fig, ax = plt.subplots(figsize=(14, 10))
        
        # Agrupar por endpoint
        health_tests = [(k, v) for k, v in self.test_results.items() if 'health' in k]
        info_tests = [(k, v) for k, v in self.test_results.items() if 'info' in k]
        
        # Preparar dados para boxplot
        health_response_times = []
        info_response_times = []
        
        for _, result in health_tests:
            health_response_times.extend(result['response_times'][:500])  # Limitar para visualização
            
        for _, result in info_tests:
            info_response_times.extend(result['response_times'][:500])  # Limitar para visualização
        
        data_to_plot = []
        labels = []
        
        if health_response_times:
            data_to_plot.append(health_response_times)
            labels.append('Health Endpoint')
            
        if info_response_times:
            data_to_plot.append(info_response_times)
            labels.append('Info Endpoint')
        
        if data_to_plot:
            bp = ax.boxplot(data_to_plot, labels=labels, patch_artist=True)
            
            # Colorir as caixas
            colors = ['lightblue', 'lightcoral']
            for patch, color in zip(bp['boxes'], colors[:len(bp['boxes'])]):
                patch.set_facecolor(color)
                patch.set_alpha(0.7)
        
        ax.set_title('Análise Comparativa: Distribuição dos Tempos de Resposta', 
                    fontsize=14, fontweight='bold')
        ax.set_ylabel('Tempo de Resposta (ms)')
        ax.grid(True, alpha=0.3)
        
        plt.tight_layout()
        plt.savefig(graphs_dir / f'comparative_{timestamp}.png', dpi=300, bbox_inches='tight')
        plt.close()
        
    def save_comprehensive_report(self):
        """Salva relatório abrangente em JSON"""
        print("\n📝 Salvando relatório detalhado...")
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        report_file = self.workspace_root / f'stress_test_comprehensive_report_{timestamp}.json'
        
        # Calcular estatísticas agregadas
        total_requests = sum(r['total_requests'] for r in self.test_results.values())
        total_successful = sum(r['successful_requests'] for r in self.test_results.values())
        
        all_response_times = []
        for result in self.test_results.values():
            all_response_times.extend(result['response_times'])
        
        # Preparar dados para serialização
        serializable_results = {}
        for test_name, result in self.test_results.items():
            serializable_result = result.copy()
            
            # Converter timestamps para strings
            for raw_result in serializable_result['raw_results']:
                raw_result['timestamp'] = raw_result['timestamp'].isoformat()
            
            serializable_results[test_name] = serializable_result
        
        report_data = {
            'test_execution': {
                'start_time': self.start_time.isoformat(),
                'end_time': datetime.now().isoformat(),
                'duration_seconds': (datetime.now() - self.start_time).total_seconds(),
                'test_type': 'Simplified Stress Test - API Gateway Focus'
            },
            'environment': {
                'docker_platform': 'WSL Ubuntu',
                'container_focus': 'API Gateway Only',
                'test_endpoints': self.endpoints
            },
            'aggregated_statistics': {
                'total_tests_executed': len(self.test_results),
                'total_requests_sent': total_requests,
                'total_successful_requests': total_successful,
                'overall_success_rate': (total_successful / total_requests * 100) if total_requests > 0 else 0,
                'overall_avg_response_time': statistics.mean(all_response_times) if all_response_times else 0,
                'overall_p95_response_time': np.percentile(all_response_times, 95) if all_response_times else 0,
                'overall_p99_response_time': np.percentile(all_response_times, 99) if all_response_times else 0,
            },
            'test_results': serializable_results,
            'performance_insights': {
                'best_throughput': max((r['requests_per_second'] for r in self.test_results.values()), default=0),
                'worst_response_time': max((r['avg_response_time'] for r in self.test_results.values()), default=0),
                'most_stable_test': min(self.test_results.items(), 
                                      key=lambda x: x[1]['max_response_time'] - x[1]['min_response_time'])[0] if self.test_results else None
            }
        }
        
        with open(report_file, 'w', encoding='utf-8') as f:
            json.dump(report_data, f, indent=2, ensure_ascii=False)
        
        print(f"✅ Relatório abrangente salvo: {report_file}")
        return report_file
        
    def cleanup_application(self):
        """Para e limpa a aplicação"""
        print("\n🧹 Limpando ambiente...")
        
        try:
            wsl_path = str(self.microservices_path).replace('\\', '/').replace('C:', '/mnt/c')
            subprocess.run([
                'wsl', 'bash', '-c',
                f'cd {wsl_path} && docker-compose down -v'
            ], capture_output=True)
            print("✅ Aplicação parada e limpa")
        except Exception as e:
            print(f"⚠️ Erro na limpeza: {e}")

def main():
    """Função principal"""
    print("🔥 TESTE DE STRESS SIMPLIFICADO COM VISUALIZAÇÃO GRÁFICA")
    print("=" * 70)
    print("🎯 Foco: API Gateway (Serviço Principal)")
    print("🐳 Ambiente: Docker no WSL Ubuntu") 
    print("📊 Testes: Progressivos de Carga e Stress")
    print("📈 Saída: Gráficos Detalhados e Relatórios")
    print("=" * 70)
    
    workspace_root = Path(__file__).parent
    manager = SimplifiedStressTestManager(workspace_root)
    
    try:
        # 1. Verificar Docker
        if not manager.check_docker_status():
            print("❌ Docker não está disponível no WSL")
            return 1
        
        # 2. Iniciar API Gateway
        if not manager.start_api_gateway_only():
            print("❌ Falha ao iniciar API Gateway")
            return 1
        
        # 3. Aguardar API Gateway
        if not manager.wait_for_api_gateway():
            print("❌ API Gateway não ficou disponível")
            return 1
        
        # 4. Executar testes de stress
        print("\n🎯 Iniciando bateria de testes progressivos...")
        manager.stress_test_suite()
        
        # 5. Gerar gráficos abrangentes
        manager.generate_comprehensive_graphs()
        
        # 6. Salvar relatório
        manager.save_comprehensive_report()
        
        # 7. Mostrar resumo detalhado
        print(f"\n{'='*70}")
        print("📊 RESUMO FINAL DOS TESTES")
        print(f"{'='*70}")
        
        total_requests = sum(r['total_requests'] for r in manager.test_results.values())
        total_successful = sum(r['successful_requests'] for r in manager.test_results.values())
        avg_success_rate = (total_successful / total_requests * 100) if total_requests > 0 else 0
        
        # Melhor e pior performance
        best_throughput = max((r['requests_per_second'] for r in manager.test_results.values()), default=0)
        worst_response = max((r['avg_response_time'] for r in manager.test_results.values()), default=0)
        
        print(f"🎯 Total de cenários testados: {len(manager.test_results)}")
        print(f"📝 Total de requisições enviadas: {total_requests:,}")
        print(f"✅ Requisições bem-sucedidas: {total_successful:,}")
        print(f"📊 Taxa de sucesso geral: {avg_success_rate:.1f}%")
        print(f"🚀 Melhor throughput: {best_throughput:.1f} req/s")
        print(f"⏱️ Pior tempo de resposta: {worst_response:.1f}ms")
        print(f"📈 Gráficos salvos: stress_test_graphs/")
        print(f"📄 Relatório: stress_test_comprehensive_report_*.json")
        print(f"⏰ Duração total: {(datetime.now() - manager.start_time).total_seconds():.1f}s")
        
        if avg_success_rate >= 95:
            print("\n🎉 EXCELENTE! API Gateway passou em todos os testes de stress!")
        elif avg_success_rate >= 90:
            print("\n✅ BOM! API Gateway mostrou boa resistência ao stress")
        else:
            print("\n⚠️ ATENÇÃO! API Gateway apresentou problemas sob stress")
        
        return 0
        
    except KeyboardInterrupt:
        print("\n⚠️ Teste interrompido pelo usuário")
        return 1
    except Exception as e:
        print(f"\n❌ Erro durante execução: {e}")
        import traceback
        traceback.print_exc()
        return 1
    finally:
        # Sempre limpa o ambiente
        manager.cleanup_application()

if __name__ == "__main__":
    exit(main())
