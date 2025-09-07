#!/usr/bin/env python3
"""
Automated Branch Comparison Tool
Automatically switches between branches and runs performance tests
"""

import subprocess
import json
import time
import requests
from datetime import datetime
import os

class AutomatedBranchComparison:
    def __init__(self):
        self.results = {
            "master": None,
            "refactoring": None,
            "comparison": None,
            "timestamp": datetime.now().isoformat()
        }
        
    def check_git_status(self):
        """Verifica se o repositório está limpo"""
        try:
            result = subprocess.run(['git', 'status', '--porcelain'], 
                                  capture_output=True, text=True)
            return len(result.stdout.strip()) == 0
        except:
            return False
    
    def get_current_branch(self):
        """Obtém branch atual"""
        try:
            result = subprocess.run(['git', 'branch', '--show-current'], 
                                  capture_output=True, text=True)
            return result.stdout.strip()
        except:
            return None
    
    def switch_branch(self, branch_name):
        """Troca para uma branch específica"""
        try:
            print(f"🔄 Trocando para branch: {branch_name}")
            result = subprocess.run(['git', 'checkout', branch_name], 
                                  capture_output=True, text=True)
            
            if result.returncode == 0:
                print(f"✅ Trocado para branch: {branch_name}")
                return True
            else:
                print(f"❌ Erro ao trocar para branch {branch_name}: {result.stderr}")
                return False
        except Exception as e:
            print(f"❌ Erro ao executar git checkout: {e}")
            return False
    
    def wait_for_services(self, timeout=300):
        """Aguarda serviços ficarem disponíveis"""
        print("⏳ Aguardando serviços ficarem disponíveis...")
        start_time = time.time()
        
        while time.time() - start_time < timeout:
            try:
                response = requests.get("http://localhost:8080/api/health", timeout=5)
                if response.status_code == 200:
                    print("✅ Serviços disponíveis!")
                    return True
            except:
                pass
            
            print("   Aguardando... (serviços ainda não disponíveis)")
            time.sleep(10)
        
        print(f"❌ Timeout aguardando serviços ({timeout}s)")
        return False
    
    def restart_services(self):
        """Reinicia os serviços Docker"""
        print("🔄 Reiniciando serviços...")
        
        try:
            # Parar serviços
            subprocess.run(['docker-compose', 'down'], cwd='05-microservices')
            time.sleep(5)
            
            # Iniciar serviços
            subprocess.run(['docker-compose', 'up', '-d'], cwd='05-microservices')
            
            return self.wait_for_services()
        except Exception as e:
            print(f"❌ Erro ao reiniciar serviços: {e}")
            return False
    
    def run_performance_test(self, branch_name):
        """Executa teste de performance para uma branch"""
        print(f"\n🎯 INICIANDO TESTE DE PERFORMANCE - {branch_name.upper()}")
        print("=" * 60)
        
        try:
            # Executar script de teste
            result = subprocess.run([
                'python', 
                '07-testing/performance-tests/branch_performance_tester.py', 
                '1000'
            ], capture_output=True, text=True, timeout=600)
            
            if result.returncode == 0:
                print(f"✅ Teste de {branch_name} concluído com sucesso")
                print("STDOUT:", result.stdout[-500:])  # Últimas 500 chars
                
                # Procurar arquivo de resultado mais recente
                test_files = []
                for file in os.listdir('.'):
                    if file.startswith(f'performance_test_{branch_name}_') and file.endswith('.json'):
                        test_files.append(file)
                
                if test_files:
                    latest_file = sorted(test_files)[-1]
                    with open(latest_file, 'r') as f:
                        return json.load(f)
                
            else:
                print(f"❌ Erro no teste de {branch_name}")
                print("STDERR:", result.stderr)
                
        except subprocess.TimeoutExpired:
            print(f"❌ Timeout no teste de {branch_name}")
        except Exception as e:
            print(f"❌ Erro ao executar teste de {branch_name}: {e}")
        
        return None
    
    def compare_results(self):
        """Compara resultados entre branches"""
        if not self.results["master"] or not self.results["refactoring"]:
            print("❌ Resultados insuficientes para comparação")
            return
        
        print(f"\n🔄 COMPARAÇÃO FINAL ENTRE BRANCHES")
        print("=" * 60)
        
        master = self.results["master"]
        refactoring = self.results["refactoring"]
        
        # Extrair métricas
        master_throughput = master["throughput_test"]["throughput"]
        ref_throughput = refactoring["throughput_test"]["throughput"]
        
        master_latency = master["latency_test"]["avg_latency"]
        ref_latency = refactoring["latency_test"]["avg_latency"]
        
        # Calcular melhorias
        throughput_improvement = ((ref_throughput - master_throughput) / master_throughput) * 100
        latency_improvement = ((master_latency - ref_latency) / master_latency) * 100
        
        comparison = {
            "throughput": {
                "master": master_throughput,
                "refactoring": ref_throughput,
                "improvement_percentage": throughput_improvement,
                "winner": "refactoring" if ref_throughput > master_throughput else "master"
            },
            "latency": {
                "master": master_latency,
                "refactoring": ref_latency,
                "improvement_percentage": latency_improvement,
                "winner": "refactoring" if ref_latency < master_latency else "master"
            }
        }
        
        self.results["comparison"] = comparison
        
        # Imprimir resultados
        print(f"📊 RESULTADOS COMPARATIVOS:")
        print(f"\n🚀 THROUGHPUT (Requisições/segundo):")
        print(f"   Master: {master_throughput:.2f}")
        print(f"   Refactoring: {ref_throughput:.2f}")
        print(f"   Melhoria: {throughput_improvement:+.2f}%")
        print(f"   🏆 Vencedor: {comparison['throughput']['winner'].upper()}")
        
        print(f"\n⏱️ LATÊNCIA MÉDIA (millisegundos):")
        print(f"   Master: {master_latency:.2f}")
        print(f"   Refactoring: {ref_latency:.2f}")
        print(f"   Melhoria: {latency_improvement:+.2f}%")
        print(f"   🏆 Vencedor: {comparison['latency']['winner'].upper()}")
        
        # Vencedor geral
        ref_wins = sum(1 for metric in comparison.values() if metric["winner"] == "refactoring")
        overall_winner = "refactoring" if ref_wins >= 1 else "master"
        
        print(f"\n🏆 VENCEDOR GERAL: {overall_winner.upper()}")
        
        if overall_winner == "refactoring":
            print("✅ A branch REFACTORING-CLEAN-ARCHITECTURE-V2.1 tem melhor performance!")
        else:
            print("✅ A branch MASTER tem melhor performance!")
        
        return comparison
    
    def save_final_report(self):
        """Salva relatório final"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"branch_performance_comparison_{timestamp}.json"
        
        with open(filename, 'w') as f:
            json.dump(self.results, f, indent=2)
        
        print(f"\n📋 Relatório final salvo em: {filename}")
        return filename
    
    def run_full_comparison(self):
        """Executa comparação completa entre branches"""
        original_branch = self.get_current_branch()
        print(f"Branch original: {original_branch}")
        
        # Verificar se repositório está limpo
        if not self.check_git_status():
            print("❌ Repositório tem mudanças não commitadas. Faça commit primeiro.")
            return False
        
        try:
            # Testar branch refactoring (atual)
            if original_branch != "refactoring-clean-architecture-v2.1":
                if not self.switch_branch("refactoring-clean-architecture-v2.1"):
                    return False
            
            # Reiniciar serviços para refactoring
            if self.restart_services():
                self.results["refactoring"] = self.run_performance_test("refactoring")
            
            # Testar branch master
            if not self.switch_branch("master"):
                return False
            
            # Reiniciar serviços para master
            if self.restart_services():
                self.results["master"] = self.run_performance_test("master")
            
            # Voltar para branch original
            if original_branch:
                self.switch_branch(original_branch)
            
            # Comparar resultados
            self.compare_results()
            
            # Salvar relatório
            self.save_final_report()
            
            return True
            
        except Exception as e:
            print(f"❌ Erro durante comparação: {e}")
            # Tentar voltar para branch original
            if original_branch:
                self.switch_branch(original_branch)
            return False

def main():
    print("🎯 COMPARAÇÃO AUTOMATIZADA DE PERFORMANCE ENTRE BRANCHES")
    print("=" * 70)
    print("Este script irá:")
    print("1. Testar performance da branch refactoring-clean-architecture-v2.1")
    print("2. Testar performance da branch master")
    print("3. Comparar os resultados")
    print("4. Gerar relatório final")
    
    input("\nPressione Enter para continuar...")
    
    comparator = AutomatedBranchComparison()
    success = comparator.run_full_comparison()
    
    if success:
        print("\n✅ Comparação concluída com sucesso!")
    else:
        print("\n❌ Comparação falhou. Verifique os logs acima.")

if __name__ == "__main__":
    main()
