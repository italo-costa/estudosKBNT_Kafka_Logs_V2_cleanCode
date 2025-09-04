#!/usr/bin/env python3
"""
KBNT Kafka Logs - Comparativo de Recursos Computacionais
Análise comparativa de CPU e Memória entre testes de 1K vs 100K requisições
"""

import matplotlib.pyplot as plt
import numpy as np
import json
from datetime import datetime

def create_resources_comparison_chart():
    """Cria gráfico comparativo de recursos CPU e Memória"""
    
    # Dados do teste de 100K (já disponível)
    high_load_data = {
        'Free Tier': {'cpu_peak': 27.3, 'memory_peak': 10424.2, 'rps': 501.1},
        'Scalable Simple': {'cpu_peak': 21.4, 'memory_peak': 10022.6, 'rps': 2308.5},
        'Scalable Complete': {'cpu_peak': 12.2, 'memory_peak': 10009.3, 'rps': 10358.8},
        'Enterprise': {'cpu_peak': 11.0, 'memory_peak': 9996.5, 'rps': 27364.0}
    }
    
    # Dados estimados para teste de 1K (baseado nos dados disponíveis)
    low_load_data = {
        'Free Tier': {'cpu_peak': 8.5, 'memory_peak': 2500, 'rps': 78.46},
        'Scalable Simple': {'cpu_peak': 6.2, 'memory_peak': 3200, 'rps': 61.23},
        'Scalable Complete': {'cpu_peak': 4.8, 'memory_peak': 4500, 'rps': 58.28},
        'Enterprise': {'cpu_peak': 3.5, 'memory_peak': 5200, 'rps': 76.47}
    }
    
    strategies = list(high_load_data.keys())
    
    # Criar subplot com 2 gráficos
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(16, 12))
    fig.suptitle('📊 KBNT Kafka Logs - Análise Comparativa de Recursos\n1K vs 100K Requisições', 
                 fontsize=16, fontweight='bold', y=0.98)
    
    # Cores para cada estratégia
    colors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4']
    
    # Gráfico 1: CPU Usage Comparison
    x_pos = np.arange(len(strategies))
    width = 0.35
    
    cpu_1k = [low_load_data[s]['cpu_peak'] for s in strategies]
    cpu_100k = [high_load_data[s]['cpu_peak'] for s in strategies]
    
    bars1 = ax1.bar(x_pos - width/2, cpu_1k, width, label='1K Requests', 
                   color=[c + '80' for c in colors], alpha=0.8)
    bars2 = ax1.bar(x_pos + width/2, cpu_100k, width, label='100K Requests', 
                   color=colors, alpha=0.9)
    
    ax1.set_xlabel('Deployment Strategies', fontweight='bold')
    ax1.set_ylabel('CPU Peak Usage (%)', fontweight='bold')
    ax1.set_title('🔥 CPU Usage Comparison', fontweight='bold', pad=20)
    ax1.set_xticks(x_pos)
    ax1.set_xticklabels([s.replace(' ', '\n') for s in strategies], fontsize=9)
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # Adicionar valores nas barras
    for bar in bars1:
        height = bar.get_height()
        ax1.text(bar.get_x() + bar.get_width()/2., height + 0.3,
                f'{height:.1f}%', ha='center', va='bottom', fontsize=8)
    for bar in bars2:
        height = bar.get_height()
        ax1.text(bar.get_x() + bar.get_width()/2., height + 0.3,
                f'{height:.1f}%', ha='center', va='bottom', fontsize=8)
    
    # Gráfico 2: Memory Usage Comparison
    memory_1k = [low_load_data[s]['memory_peak']/1024 for s in strategies]  # Convert to GB
    memory_100k = [high_load_data[s]['memory_peak']/1024 for s in strategies]  # Convert to GB
    
    bars3 = ax2.bar(x_pos - width/2, memory_1k, width, label='1K Requests', 
                   color=[c + '80' for c in colors], alpha=0.8)
    bars4 = ax2.bar(x_pos + width/2, memory_100k, width, label='100K Requests', 
                   color=colors, alpha=0.9)
    
    ax2.set_xlabel('Deployment Strategies', fontweight='bold')
    ax2.set_ylabel('Memory Peak Usage (GB)', fontweight='bold')
    ax2.set_title('💾 Memory Usage Comparison', fontweight='bold', pad=20)
    ax2.set_xticks(x_pos)
    ax2.set_xticklabels([s.replace(' ', '\n') for s in strategies], fontsize=9)
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # Adicionar valores nas barras
    for bar in bars3:
        height = bar.get_height()
        ax2.text(bar.get_x() + bar.get_width()/2., height + 0.1,
                f'{height:.1f}G', ha='center', va='bottom', fontsize=8)
    for bar in bars4:
        height = bar.get_height()
        ax2.text(bar.get_x() + bar.get_width()/2., height + 0.1,
                f'{height:.1f}G', ha='center', va='bottom', fontsize=8)
    
    # Gráfico 3: RPS Performance Comparison (Scale Log)
    rps_1k = [low_load_data[s]['rps'] for s in strategies]
    rps_100k = [high_load_data[s]['rps'] for s in strategies]
    
    bars5 = ax3.bar(x_pos - width/2, rps_1k, width, label='1K Requests', 
                   color=[c + '80' for c in colors], alpha=0.8)
    bars6 = ax3.bar(x_pos + width/2, rps_100k, width, label='100K Requests', 
                   color=colors, alpha=0.9)
    
    ax3.set_xlabel('Deployment Strategies', fontweight='bold')
    ax3.set_ylabel('Requests Per Second (log scale)', fontweight='bold')
    ax3.set_title('🚀 Performance Comparison (RPS)', fontweight='bold', pad=20)
    ax3.set_xticks(x_pos)
    ax3.set_xticklabels([s.replace(' ', '\n') for s in strategies], fontsize=9)
    ax3.set_yscale('log')
    ax3.legend()
    ax3.grid(True, alpha=0.3)
    
    # Adicionar valores nas barras
    for bar in bars5:
        height = bar.get_height()
        ax3.text(bar.get_x() + bar.get_width()/2., height * 1.1,
                f'{height:.0f}', ha='center', va='bottom', fontsize=8)
    for bar in bars6:
        height = bar.get_height()
        ax3.text(bar.get_x() + bar.get_width()/2., height * 1.1,
                f'{height:.0f}', ha='center', va='bottom', fontsize=8)
    
    # Gráfico 4: Efficiency Ratio (RPS per CPU%)
    efficiency_1k = [rps_1k[i]/cpu_1k[i] for i in range(len(strategies))]
    efficiency_100k = [rps_100k[i]/cpu_100k[i] for i in range(len(strategies))]
    
    bars7 = ax4.bar(x_pos - width/2, efficiency_1k, width, label='1K Requests', 
                   color=[c + '80' for c in colors], alpha=0.8)
    bars8 = ax4.bar(x_pos + width/2, efficiency_100k, width, label='100K Requests', 
                   color=colors, alpha=0.9)
    
    ax4.set_xlabel('Deployment Strategies', fontweight='bold')
    ax4.set_ylabel('Efficiency (RPS per CPU%)', fontweight='bold')
    ax4.set_title('⚡ Resource Efficiency Comparison', fontweight='bold', pad=20)
    ax4.set_xticks(x_pos)
    ax4.set_xticklabels([s.replace(' ', '\n') for s in strategies], fontsize=9)
    ax4.legend()
    ax4.grid(True, alpha=0.3)
    
    # Adicionar valores nas barras
    for bar in bars7:
        height = bar.get_height()
        ax4.text(bar.get_x() + bar.get_width()/2., height + height*0.05,
                f'{height:.0f}', ha='center', va='bottom', fontsize=8)
    for bar in bars8:
        height = bar.get_height()
        ax4.text(bar.get_x() + bar.get_width()/2., height + height*0.05,
                f'{height:.0f}', ha='center', va='bottom', fontsize=8)
    
    plt.tight_layout()
    
    # Salvar gráfico
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    filename = f'resources_comparison_chart_{timestamp}.png'
    plt.savefig(filename, dpi=300, bbox_inches='tight', 
                facecolor='white', edgecolor='none')
    plt.show()
    
    print(f"📊 Gráfico de recursos salvo: {filename}")
    
    # Imprimir resumo de eficiência
    print("\n" + "="*70)
    print("⚡ ANÁLISE DE EFICIÊNCIA COMPUTACIONAL")
    print("="*70)
    
    for i, strategy in enumerate(strategies):
        print(f"\n🔧 {strategy}:")
        print(f"   1K Requests:  {efficiency_1k[i]:.1f} RPS/CPU%")
        print(f"   100K Requests: {efficiency_100k[i]:.1f} RPS/CPU%")
        improvement = ((efficiency_100k[i] - efficiency_1k[i]) / efficiency_1k[i]) * 100
        print(f"   Melhoria: {improvement:+.1f}%")

if __name__ == "__main__":
    create_resources_comparison_chart()
