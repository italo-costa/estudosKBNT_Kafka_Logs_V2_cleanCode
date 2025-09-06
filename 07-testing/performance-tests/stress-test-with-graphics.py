#!/usr/bin/env python3
"""
Testes de Stress e Carga com Visualização Gráfica
Executa testes abrangentes na aplicação dockerizada no WSL
e gera gráficos detalhados dos resultados
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

class StressTestManager:
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
        
        # Endpoints para teste
        self.endpoints = {
            'api_gateway_health': 'http://localhost:8080/actuator/health',
            'api_gateway_info': 'http://localhost:8080/actuator/info',
            'virtual_stock_health': 'http://localhost:8084/actuator/health',
            'virtual_stock_status': 'http://localhost:8084/api/v1/virtual-stock/status',
            'log_producer_health': 'http://localhost:8081/actuator/health',
            'log_consumer_health': 'http://localhost:8082/actuator/health',
            'log_analytics_health': 'http://localhost:8083/actuator/health',
            'kbnt_consumer_health': 'http://localhost:8085/actuator/health'
        }
        
    def check_docker_status(self):
        """Verifica status do Docker no WSL"""
        print("🐳 Verificando Docker no ambiente Linux virtualizado (WSL)...")
        
        try:
            # Verifica Docker
            result = subprocess.run(['wsl', 'docker', '--version'], capture_output=True, text=True)
            if result.returncode == 0:
                print(f"✅ Docker WSL: {result.stdout.strip()}")
            else:
                print("❌ Docker não encontrado no WSL")
                return False
                
            # Verifica Docker Compose
            result = subprocess.run(['wsl', 'docker-compose', '--version'], capture_output=True, text=True)
            if result.returncode == 0:
                print(f"✅ Docker Compose WSL: {result.stdout.strip()}")
            else:
                print("❌ Docker Compose não encontrado no WSL")
                return False
                
            # Verifica se o daemon está rodando
            result = subprocess.run(['wsl', 'docker', 'info'], capture_output=True, text=True)
            if result.returncode == 0:
                print("✅ Docker daemon está rodando no WSL")
                print(f"🐧 Sistema: Ubuntu WSL2")
                return True
            else:
                print("❌ Docker daemon não está rodando no WSL")
                return False
                
        except Exception as e:
            print(f"❌ Erro ao verificar Docker: {e}")
            return False
    
    def start_application(self):
        """Inicia a aplicação usando Docker Compose no WSL"""
        print("\n🚀 Iniciando aplicação no WSL...")
        
        try:
            wsl_path = str(self.microservices_path).replace('\\', '/').replace('C:', '/mnt/c')
            
            # Para containers existentes
            print("🧹 Limpando ambiente...")
            subprocess.run([
                'wsl', 'bash', '-c', 
                f'cd {wsl_path} && docker-compose down -v --remove-orphans'
            ], capture_output=True)
            
            # Inicia os serviços
            print("📦 Iniciando containers...")
            result = subprocess.run([
                'wsl', 'bash', '-c',
                f'cd {wsl_path} && docker-compose up -d'
            ], capture_output=True, text=True)
            
            if result.returncode == 0:
                print("✅ Aplicação iniciada com sucesso no WSL")
                return True
            else:
                print(f"❌ Erro ao iniciar aplicação: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ Erro ao iniciar aplicação: {e}")
            return False
    
    def wait_for_services(self, timeout=300):
        """Aguarda os serviços ficarem disponíveis"""
        print(f"\n⏰ Aguardando serviços ficarem disponíveis (timeout: {timeout}s)...")
        
        start_time = time.time()
        healthy_services = set()
        
        while time.time() - start_time < timeout:
            current_healthy = set()
            
            for service_name, url in self.endpoints.items():
                try:
                    response = requests.get(url, timeout=5)
                    if response.status_code == 200:
                        current_healthy.add(service_name)
                        if service_name not in healthy_services:
                            print(f"✅ {service_name} está disponível")
                except:
                    pass
            
            healthy_services.update(current_healthy)
            
            # Se pelo menos o API Gateway e 2 outros serviços estão healthy
            if len(current_healthy) >= 3 and 'api_gateway_health' in current_healthy:
                print(f"\n✅ {len(current_healthy)} serviços disponíveis. Iniciando testes...")
                return True
            
            time.sleep(10)
            elapsed = int(time.time() - start_time)
            print(f"⏳ Aguardando... ({elapsed}s/{timeout}s) - {len(current_healthy)} serviços prontos")
        
        print(f"❌ Timeout aguardando serviços ({len(healthy_services)} prontos)")
        return False
    
    def single_request(self, endpoint_name, url, request_id):
        """Executa uma única requisição e coleta métricas"""
        try:
            start_time = time.time()
            response = requests.get(url, timeout=30)
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
                'response_time': 30000,  # timeout
                'timestamp': datetime.now(),
                'success': False,
                'error': str(e),
                'content_length': 0
            }
    
    def load_test(self, endpoint_name, url, num_requests=1000, max_workers=50):
        """Executa teste de carga em um endpoint específico"""
        print(f"\n🎯 Teste de carga: {endpoint_name} ({num_requests} requisições)")
        
        results = []
        start_time = time.time()
        
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            futures = []
            for i in range(num_requests):
                future = executor.submit(self.single_request, endpoint_name, url, i)
                futures.append(future)
            
            # Coleta resultados conforme completam
            for future in as_completed(futures):
                result = future.result()
                results.append(result)
                
                # Progress feedback
                if len(results) % 100 == 0:
                    elapsed = time.time() - start_time
                    print(f"  📊 {len(results)}/{num_requests} concluídas ({elapsed:.1f}s)")
        
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
        
        print(f"✅ Teste concluído: {stats['success_rate']:.1f}% sucesso, "
              f"{stats['requests_per_second']:.1f} req/s, "
              f"{stats['avg_response_time']:.1f}ms média")
        
        return stats
    
    def stress_test_suite(self):
        """Executa uma suíte completa de testes de stress"""
        print("\n🔥 Iniciando suíte de testes de stress e carga...")
        
        test_scenarios = [
            # Testes básicos de saúde
            ('api_gateway_health', 500, 20),
            ('virtual_stock_health', 500, 20),
            
            # Testes de endpoints funcionais
            ('virtual_stock_status', 1000, 30),
            ('api_gateway_info', 1000, 30),
            
            # Testes de alta carga
            ('api_gateway_health', 2000, 50),
            ('virtual_stock_health', 2000, 50),
            
            # Teste de stress extremo
            ('api_gateway_health', 5000, 100),
        ]
        
        all_results = {}
        
        for endpoint_name, num_requests, max_workers in test_scenarios:
            if endpoint_name in self.endpoints:
                url = self.endpoints[endpoint_name]
                
                print(f"\n{'='*60}")
                print(f"🎯 TESTE: {endpoint_name}")
                print(f"📝 URL: {url}")
                print(f"📊 Requisições: {num_requests}")
                print(f"👥 Workers: {max_workers}")
                print(f"{'='*60}")
                
                result = self.load_test(endpoint_name, url, num_requests, max_workers)
                all_results[f"{endpoint_name}_{num_requests}"] = result
                
                # Pausa entre testes para não sobrecarregar
                time.sleep(5)
        
        self.test_results = all_results
        return all_results
    
    def generate_performance_graphs(self):
        """Gera gráficos detalhados dos resultados dos testes"""
        print("\n📊 Gerando gráficos de performance...")
        
        if not self.test_results:
            print("❌ Nenhum resultado de teste disponível")
            return
        
        # Criar diretório para gráficos
        graphs_dir = self.workspace_root / 'performance_graphs'
        graphs_dir.mkdir(exist_ok=True)
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # 1. Gráfico de Tempo de Resposta
        self._create_response_time_graph(graphs_dir, timestamp)
        
        # 2. Gráfico de Taxa de Sucesso
        self._create_success_rate_graph(graphs_dir, timestamp)
        
        # 3. Gráfico de Requests por Segundo
        self._create_throughput_graph(graphs_dir, timestamp)
        
        # 4. Gráfico de Percentis
        self._create_percentile_graph(graphs_dir, timestamp)
        
        # 5. Gráfico de Distribuição de Tempo de Resposta
        self._create_response_distribution_graph(graphs_dir, timestamp)
        
        # 6. Gráfico de Timeline de Requisições
        self._create_timeline_graph(graphs_dir, timestamp)
        
        print(f"✅ Gráficos salvos em: {graphs_dir}")
        
    def _create_response_time_graph(self, graphs_dir, timestamp):
        """Cria gráfico de tempo de resposta médio"""
        fig, ax = plt.subplots(figsize=(12, 8))
        
        test_names = []
        avg_times = []
        colors = []
        
        for test_name, result in self.test_results.items():
            test_names.append(test_name.replace('_', '\n'))
            avg_times.append(result['avg_response_time'])
            
            # Cor baseada na performance
            if result['avg_response_time'] < 100:
                colors.append('green')
            elif result['avg_response_time'] < 500:
                colors.append('orange')
            else:
                colors.append('red')
        
        bars = ax.bar(test_names, avg_times, color=colors, alpha=0.7)
        
        # Adicionar valores nas barras
        for bar, value in zip(bars, avg_times):
            height = bar.get_height()
            ax.text(bar.get_x() + bar.get_width()/2., height + 5,
                   f'{value:.1f}ms', ha='center', va='bottom', fontweight='bold')
        
        ax.set_title('Tempo de Resposta Médio por Teste', fontsize=16, fontweight='bold')
        ax.set_ylabel('Tempo de Resposta (ms)', fontsize=12)
        ax.set_xlabel('Cenários de Teste', fontsize=12)
        ax.grid(True, alpha=0.3)
        
        plt.xticks(rotation=45, ha='right')
        plt.tight_layout()
        plt.savefig(graphs_dir / f'response_time_{timestamp}.png', dpi=300, bbox_inches='tight')
        plt.close()
        
    def _create_success_rate_graph(self, graphs_dir, timestamp):
        """Cria gráfico de taxa de sucesso"""
        fig, ax = plt.subplots(figsize=(12, 8))
        
        test_names = []
        success_rates = []
        
        for test_name, result in self.test_results.items():
            test_names.append(test_name.replace('_', '\n'))
            success_rates.append(result['success_rate'])
        
        bars = ax.bar(test_names, success_rates, 
                     color=['green' if rate >= 95 else 'orange' if rate >= 90 else 'red' for rate in success_rates],
                     alpha=0.7)
        
        # Adicionar valores nas barras
        for bar, value in zip(bars, success_rates):
            height = bar.get_height()
            ax.text(bar.get_x() + bar.get_width()/2., height + 0.5,
                   f'{value:.1f}%', ha='center', va='bottom', fontweight='bold')
        
        ax.set_title('Taxa de Sucesso por Teste', fontsize=16, fontweight='bold')
        ax.set_ylabel('Taxa de Sucesso (%)', fontsize=12)
        ax.set_xlabel('Cenários de Teste', fontsize=12)
        ax.set_ylim(0, 105)
        ax.grid(True, alpha=0.3)
        
        # Linha de referência
        ax.axhline(y=95, color='red', linestyle='--', alpha=0.5, label='Meta: 95%')
        ax.legend()
        
        plt.xticks(rotation=45, ha='right')
        plt.tight_layout()
        plt.savefig(graphs_dir / f'success_rate_{timestamp}.png', dpi=300, bbox_inches='tight')
        plt.close()
        
    def _create_throughput_graph(self, graphs_dir, timestamp):
        """Cria gráfico de throughput (requisições por segundo)"""
        fig, ax = plt.subplots(figsize=(12, 8))
        
        test_names = []
        throughput = []
        
        for test_name, result in self.test_results.items():
            test_names.append(test_name.replace('_', '\n'))
            throughput.append(result['requests_per_second'])
        
        bars = ax.bar(test_names, throughput, color='skyblue', alpha=0.7)
        
        # Adicionar valores nas barras
        for bar, value in zip(bars, throughput):
            height = bar.get_height()
            ax.text(bar.get_x() + bar.get_width()/2., height + 1,
                   f'{value:.1f}', ha='center', va='bottom', fontweight='bold')
        
        ax.set_title('Throughput (Requisições por Segundo)', fontsize=16, fontweight='bold')
        ax.set_ylabel('Requisições/segundo', fontsize=12)
        ax.set_xlabel('Cenários de Teste', fontsize=12)
        ax.grid(True, alpha=0.3)
        
        plt.xticks(rotation=45, ha='right')
        plt.tight_layout()
        plt.savefig(graphs_dir / f'throughput_{timestamp}.png', dpi=300, bbox_inches='tight')
        plt.close()
        
    def _create_percentile_graph(self, graphs_dir, timestamp):
        """Cria gráfico de percentis de tempo de resposta"""
        fig, ax = plt.subplots(figsize=(14, 8))
        
        test_names = []
        p50_times = []
        p95_times = []
        p99_times = []
        
        for test_name, result in self.test_results.items():
            test_names.append(test_name.replace('_', '\n'))
            p50_times.append(result['median_response_time'])
            p95_times.append(result['p95_response_time'])
            p99_times.append(result['p99_response_time'])
        
        x = np.arange(len(test_names))
        width = 0.25
        
        ax.bar(x - width, p50_times, width, label='P50 (Mediana)', alpha=0.8)
        ax.bar(x, p95_times, width, label='P95', alpha=0.8)
        ax.bar(x + width, p99_times, width, label='P99', alpha=0.8)
        
        ax.set_title('Percentis de Tempo de Resposta', fontsize=16, fontweight='bold')
        ax.set_ylabel('Tempo de Resposta (ms)', fontsize=12)
        ax.set_xlabel('Cenários de Teste', fontsize=12)
        ax.set_xticks(x)
        ax.set_xticklabels(test_names)
        ax.legend()
        ax.grid(True, alpha=0.3)
        
        plt.xticks(rotation=45, ha='right')
        plt.tight_layout()
        plt.savefig(graphs_dir / f'percentiles_{timestamp}.png', dpi=300, bbox_inches='tight')
        plt.close()
        
    def _create_response_distribution_graph(self, graphs_dir, timestamp):
        """Cria histograma de distribuição dos tempos de resposta"""
        fig, axes = plt.subplots(2, 2, figsize=(16, 12))
        axes = axes.flatten()
        
        for i, (test_name, result) in enumerate(self.test_results.items()):
            if i >= 4:  # Mostra apenas os primeiros 4 testes
                break
                
            ax = axes[i]
            response_times = result['response_times']
            
            if response_times:
                ax.hist(response_times, bins=50, alpha=0.7, edgecolor='black')
                ax.axvline(result['avg_response_time'], color='red', linestyle='--', 
                          label=f'Média: {result["avg_response_time"]:.1f}ms')
                ax.axvline(result['median_response_time'], color='green', linestyle='--',
                          label=f'Mediana: {result["median_response_time"]:.1f}ms')
            
            ax.set_title(test_name.replace('_', ' '), fontsize=12, fontweight='bold')
            ax.set_xlabel('Tempo de Resposta (ms)')
            ax.set_ylabel('Frequência')
            ax.legend()
            ax.grid(True, alpha=0.3)
        
        # Remove eixos não utilizados
        for i in range(len(self.test_results), 4):
            axes[i].remove()
        
        plt.suptitle('Distribuição dos Tempos de Resposta', fontsize=16, fontweight='bold')
        plt.tight_layout()
        plt.savefig(graphs_dir / f'distribution_{timestamp}.png', dpi=300, bbox_inches='tight')
        plt.close()
        
    def _create_timeline_graph(self, graphs_dir, timestamp):
        """Cria gráfico de timeline das requisições"""
        fig, ax = plt.subplots(figsize=(16, 10))
        
        colors = plt.cm.Set3(np.linspace(0, 1, len(self.test_results)))
        
        for i, (test_name, result) in enumerate(self.test_results.items()):
            timestamps = [r['timestamp'] for r in result['raw_results']]
            response_times = [r['response_time'] for r in result['raw_results']]
            
            # Pega apenas uma amostra para visualização
            sample_size = min(200, len(timestamps))
            sample_indices = np.random.choice(len(timestamps), sample_size, replace=False)
            
            sample_timestamps = [timestamps[i] for i in sample_indices]
            sample_response_times = [response_times[i] for i in sample_indices]
            
            ax.scatter(sample_timestamps, sample_response_times, 
                      alpha=0.6, s=20, color=colors[i], label=test_name.replace('_', ' '))
        
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
        
    def save_detailed_report(self):
        """Salva relatório detalhado em JSON"""
        print("\n📝 Salvando relatório detalhado...")
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        report_file = self.workspace_root / f'stress_test_report_{timestamp}.json'
        
        # Preparar dados para serialização (remover objetos datetime)
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
                'duration_seconds': (datetime.now() - self.start_time).total_seconds()
            },
            'environment': {
                'docker_platform': 'WSL Ubuntu',
                'test_endpoints': self.endpoints
            },
            'test_results': serializable_results,
            'summary': {
                'total_tests': len(self.test_results),
                'total_requests': sum(r['total_requests'] for r in self.test_results.values()),
                'overall_success_rate': sum(r['success_rate'] * r['total_requests'] for r in self.test_results.values()) / 
                                      sum(r['total_requests'] for r in self.test_results.values()) if self.test_results else 0
            }
        }
        
        with open(report_file, 'w', encoding='utf-8') as f:
            json.dump(report_data, f, indent=2, ensure_ascii=False)
        
        print(f"✅ Relatório salvo: {report_file}")
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
    print("🔥 TESTE DE STRESS E CARGA COM VISUALIZAÇÃO GRÁFICA")
    print("=" * 60)
    print("🐳 Ambiente: Docker no WSL Ubuntu")
    print("📊 Testes: Stress, Carga e Performance")
    print("📈 Saída: Gráficos e Relatórios Detalhados")
    print("=" * 60)
    
    workspace_root = Path(__file__).parent
    manager = StressTestManager(workspace_root)
    
    try:
        # 1. Verificar Docker
        if not manager.check_docker_status():
            print("❌ Docker não está disponível no WSL")
            return 1
        
        # 2. Instalar dependências se necessário
        try:
            import matplotlib.pyplot as plt
            import seaborn as sns
            import pandas as pd
            import numpy as np
        except ImportError:
            print("📦 Instalando dependências para gráficos...")
            subprocess.run([sys.executable, '-m', 'pip', 'install', 
                          'matplotlib', 'seaborn', 'pandas', 'numpy'], check=True)
            print("✅ Dependências instaladas")
        
        # 3. Iniciar aplicação
        if not manager.start_application():
            print("❌ Falha ao iniciar aplicação")
            return 1
        
        # 4. Aguardar serviços
        if not manager.wait_for_services():
            print("❌ Serviços não ficaram disponíveis")
            return 1
        
        # 5. Executar testes de stress
        print("\n🎯 Iniciando bateria de testes...")
        manager.stress_test_suite()
        
        # 6. Gerar gráficos
        manager.generate_performance_graphs()
        
        # 7. Salvar relatório
        manager.save_detailed_report()
        
        # 8. Mostrar resumo
        print(f"\n{'='*60}")
        print("📊 RESUMO DOS TESTES")
        print(f"{'='*60}")
        
        total_requests = sum(r['total_requests'] for r in manager.test_results.values())
        avg_success_rate = sum(r['success_rate'] * r['total_requests'] for r in manager.test_results.values()) / total_requests if total_requests > 0 else 0
        
        print(f"🎯 Total de testes: {len(manager.test_results)}")
        print(f"📝 Total de requisições: {total_requests:,}")
        print(f"✅ Taxa de sucesso geral: {avg_success_rate:.1f}%")
        print(f"📈 Gráficos gerados: performance_graphs/")
        print(f"📄 Relatório: stress_test_report_*.json")
        
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
