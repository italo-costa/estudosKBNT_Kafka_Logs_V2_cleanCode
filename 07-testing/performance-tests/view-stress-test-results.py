#!/usr/bin/env python3
"""
Visualizador de Gráficos dos Testes de Stress
Abre e exibe os gráficos gerados pelos testes
"""

import os
import sys
from pathlib import Path
import subprocess
import json

def show_test_summary():
    """Mostra resumo dos resultados dos testes"""
    print("📊 RESUMO DOS TESTES DE STRESS E CARGA")
    print("=" * 50)
    
    # Buscar o arquivo de relatório mais recente
    workspace = Path(__file__).parent
    report_files = list(workspace.glob("stress_test_comprehensive_report_*.json"))
    
    if not report_files:
        print("❌ Nenhum relatório encontrado")
        return
    
    latest_report = max(report_files, key=lambda x: x.stat().st_mtime)
    print(f"📄 Relatório: {latest_report.name}")
    
    try:
        with open(latest_report, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Estatísticas gerais
        stats = data['aggregated_statistics']
        print(f"\n🎯 Estatísticas Gerais:")
        print(f"   📊 Total de testes: {stats['total_tests_executed']}")
        print(f"   📝 Total de requisições: {stats['total_requests_sent']:,}")
        print(f"   ✅ Requisições bem-sucedidas: {stats['total_successful_requests']:,}")
        print(f"   📈 Taxa de sucesso: {stats['overall_success_rate']:.1f}%")
        print(f"   ⏱️ Tempo médio: {stats['overall_avg_response_time']:.1f}ms")
        print(f"   📊 P95: {stats['overall_p95_response_time']:.1f}ms")
        print(f"   📊 P99: {stats['overall_p99_response_time']:.1f}ms")
        
        # Insights de performance
        insights = data.get('performance_insights', {})
        print(f"\n🚀 Insights de Performance:")
        print(f"   📈 Melhor throughput: {insights.get('best_throughput', 0):.1f} req/s")
        print(f"   ⏱️ Pior tempo de resposta: {insights.get('worst_response_time', 0):.1f}ms")
        if 'most_stable_test' in insights:
            print(f"   🎯 Teste mais estável: {insights['most_stable_test']}")
        
        # Resultados por teste
        print(f"\n📋 Resultados Detalhados:")
        test_results = data['test_results']
        
        for test_name, result in test_results.items():
            clean_name = test_name.replace('api_gateway_', '').replace('_', ' ').title()
            status = "✅ SUCESSO" if result['success_rate'] > 90 else "⚠️ DEGRADADO" if result['success_rate'] > 50 else "❌ FALHOU"
            
            print(f"   {status} {clean_name}")
            print(f"      📊 {result['total_requests']} requisições | "
                  f"🚀 {result['requests_per_second']:.1f} req/s | "
                  f"⏱️ {result['avg_response_time']:.1f}ms | "
                  f"✅ {result['success_rate']:.1f}%")
        
    except Exception as e:
        print(f"❌ Erro ao ler relatório: {e}")

def list_generated_graphs():
    """Lista os gráficos gerados"""
    print("\n📈 GRÁFICOS GERADOS")
    print("=" * 30)
    
    graphs_dir = Path(__file__).parent / 'stress_test_graphs'
    
    if not graphs_dir.exists():
        print("❌ Diretório de gráficos não encontrado")
        return []
    
    graph_files = list(graphs_dir.glob("*.png"))
    
    if not graph_files:
        print("❌ Nenhum gráfico encontrado")
        return []
    
    graph_descriptions = {
        'dashboard': '📊 Dashboard Principal - Métricas Essenciais',
        'scalability': '📈 Análise de Escalabilidade - Throughput vs Carga',
        'distribution': '📉 Distribuição de Tempos de Resposta',
        'timeline': '⏰ Timeline das Requisições ao Longo do Tempo',
        'comparative': '🔄 Análise Comparativa entre Endpoints'
    }
    
    available_graphs = []
    for graph_file in sorted(graph_files):
        graph_type = graph_file.stem.split('_')[0]
        description = graph_descriptions.get(graph_type, f"📊 {graph_type.title()}")
        
        print(f"✅ {description}")
        print(f"   📁 {graph_file.name}")
        available_graphs.append(graph_file)
    
    return available_graphs

def open_graph(graph_path):
    """Abre um gráfico usando o visualizador padrão do sistema"""
    try:
        if sys.platform.startswith('win'):
            os.startfile(graph_path)
        elif sys.platform.startswith('darwin'):  # macOS
            subprocess.run(['open', graph_path])
        else:  # Linux
            subprocess.run(['xdg-open', graph_path])
        
        print(f"🖼️ Abrindo: {graph_path.name}")
        return True
        
    except Exception as e:
        print(f"❌ Erro ao abrir gráfico: {e}")
        return False

def open_graphs_directory():
    """Abre o diretório de gráficos no Windows Explorer"""
    graphs_dir = Path(__file__).parent / 'stress_test_graphs'
    
    if not graphs_dir.exists():
        print("❌ Diretório de gráficos não encontrado")
        return False
    
    try:
        if sys.platform.startswith('win'):
            subprocess.run(['explorer', str(graphs_dir)])
        elif sys.platform.startswith('darwin'):  # macOS
            subprocess.run(['open', str(graphs_dir)])
        else:  # Linux
            subprocess.run(['xdg-open', str(graphs_dir)])
        
        print(f"📁 Abrindo diretório: {graphs_dir}")
        return True
        
    except Exception as e:
        print(f"❌ Erro ao abrir diretório: {e}")
        return False

def interactive_menu():
    """Menu interativo para visualizar os resultados"""
    print("\n🎯 MENU INTERATIVO")
    print("=" * 25)
    
    graphs = list_generated_graphs()
    
    if not graphs:
        return
    
    while True:
        print(f"\n📋 Opções disponíveis:")
        print(f"0️⃣  Sair")
        print(f"1️⃣  Abrir diretório de gráficos")
        print(f"2️⃣  Abrir todos os gráficos")
        
        for i, graph in enumerate(graphs, 3):
            graph_type = graph.stem.split('_')[0]
            print(f"{i}️⃣  Abrir gráfico: {graph_type.title()}")
        
        try:
            choice = input(f"\n➡️ Escolha uma opção (0-{len(graphs)+2}): ").strip()
            
            if choice == '0':
                print("👋 Saindo...")
                break
            elif choice == '1':
                open_graphs_directory()
            elif choice == '2':
                print("🖼️ Abrindo todos os gráficos...")
                for graph in graphs:
                    open_graph(graph)
                break
            else:
                choice_num = int(choice)
                if 3 <= choice_num <= len(graphs) + 2:
                    graph_index = choice_num - 3
                    open_graph(graphs[graph_index])
                else:
                    print("❌ Opção inválida!")
                    
        except (ValueError, IndexError):
            print("❌ Opção inválida!")
        except KeyboardInterrupt:
            print("\n👋 Saindo...")
            break

def main():
    """Função principal"""
    print("🔍 VISUALIZADOR DE RESULTADOS DOS TESTES DE STRESS")
    print("=" * 55)
    print("📊 Análise Visual dos Resultados de Performance")
    print("🐳 Ambiente: Docker WSL Ubuntu")
    print("🎯 Foco: API Gateway")
    print("=" * 55)
    
    # Mostrar resumo dos testes
    show_test_summary()
    
    # Menu interativo
    interactive_menu()

if __name__ == "__main__":
    main()
