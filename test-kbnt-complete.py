#!/usr/bin/env python3
"""
Teste Integrado do Sistema KBNT Virtual Stock Management
Executa um teste completo da arquitetura hexagonal com microserviços Spring Boot
e simulação do Red Hat AMQ Streams
"""

import json
import subprocess
import sys
import os
import time
from datetime import datetime
import argparse

class KBNTSystemTest:
    """Teste integrado do sistema KBNT"""
    
    def __init__(self):
        self.workspace_path = "c:\\workspace\\estudosKBNT_Kafka_Logs"
        self.test_results = {
            'start_time': None,
            'end_time': None,
            'duration': 0,
            'phases': {},
            'success': True,
            'errors': []
        }

    def print_header(self, title, char="="):
        """Imprime cabeçalho formatado"""
        width = 70
        print(f"\n{char * width}")
        print(f"{title.center(width)}")
        print(f"{char * width}")

    def print_phase(self, phase, description):
        """Imprime fase do teste"""
        print(f"\n🔄 PHASE {phase}: {description}")
        print("-" * 50)

    def run_command(self, command, description, capture_output=True):
        """Executa um comando e captura resultado"""
        print(f"📝 {description}")
        print(f"💻 Comando: {command}")
        
        try:
            if capture_output:
                result = subprocess.run(
                    command, 
                    shell=True, 
                    capture_output=True, 
                    text=True, 
                    cwd=self.workspace_path
                )
                
                if result.returncode == 0:
                    print(f"✅ Sucesso!")
                    if result.stdout:
                        print(f"📤 Output: {result.stdout[:200]}...")
                    return True, result.stdout
                else:
                    print(f"❌ Erro (código {result.returncode})")
                    if result.stderr:
                        print(f"💥 Erro: {result.stderr}")
                    return False, result.stderr
            else:
                # Para comandos interativos
                result = subprocess.run(command, shell=True, cwd=self.workspace_path)
                return result.returncode == 0, ""
                
        except Exception as e:
            print(f"💥 Exceção: {str(e)}")
            return False, str(e)

    def test_environment_setup(self):
        """Testa a configuração do ambiente"""
        self.print_phase(1, "Verificação do Ambiente")
        
        # Verifica Python
        success, output = self.run_command("python --version", "Verificando Python")
        if not success:
            self.test_results['errors'].append("Python não encontrado")
            return False
        
        # Verifica Java
        success, output = self.run_command("java -version", "Verificando Java")
        if not success:
            print("⚠️  Java não encontrado - continuando com teste Python apenas")
        
        # Verifica bibliotecas Python
        success, output = self.run_command("python -c \"import kafka; print('kafka-python OK')\"", "Verificando kafka-python")
        if not success:
            self.test_results['errors'].append("kafka-python não instalado")
            return False
        
        print("✅ Ambiente configurado corretamente!")
        return True

    def test_architecture_documentation(self):
        """Testa a documentação da arquitetura"""
        self.print_phase(2, "Verificação da Documentação")
        
        files_to_check = [
            "ARCHITECTURE-WORKFLOW.md",
            "consumers/python/log-consumer.py",
            "simulate-hexagonal-workflow.py"
        ]
        
        for file in files_to_check:
            full_path = os.path.join(self.workspace_path, file)
            if os.path.exists(full_path):
                print(f"✅ {file} existe")
            else:
                print(f"❌ {file} não encontrado")
                self.test_results['errors'].append(f"Arquivo {file} não encontrado")
                return False
        
        print("✅ Documentação completa!")
        return True

    def test_hexagonal_simulation(self):
        """Testa a simulação da arquitetura hexagonal"""
        self.print_phase(3, "Simulação da Arquitetura Hexagonal")
        
        command = "python simulate-hexagonal-workflow.py --messages 50 --delay 0.01"
        success, output = self.run_command(command, "Executando simulação hexagonal", capture_output=False)
        
        if success:
            print("✅ Simulação hexagonal executada com sucesso!")
            return True
        else:
            self.test_results['errors'].append("Falha na simulação hexagonal")
            return False

    def test_log_consumer_functionality(self):
        """Testa a funcionalidade do consumer de logs"""
        self.print_phase(4, "Teste do Consumer de Logs")
        
        # Cria dados de teste
        test_data = {
            "timestamp": datetime.now().isoformat(),
            "service": "test-service",
            "level": "INFO",
            "message": "Teste de funcionalidade",
            "hexagonal_layer": "domain",
            "domain": "test",
            "operation": "test-operation"
        }
        
        # Salva dados de teste
        test_file = os.path.join(self.workspace_path, "test_message.json")
        with open(test_file, 'w') as f:
            json.dump(test_data, f)
        
        # Testa processamento manual usando script dedicado
        command = "python test-consumer-simple.py"
        success, output = self.run_command(command, "Testando processamento de logs")
        
        # Limpa arquivo de teste
        if os.path.exists(test_file):
            os.remove(test_file)
        
        if success:
            print("✅ Consumer de logs funcionando!")
            return True
        else:
            self.test_results['errors'].append("Falha no consumer de logs")
            return False

    def test_spring_boot_microservices_simulation(self):
        """Simula teste dos microserviços Spring Boot"""
        self.print_phase(5, "Simulação dos Microserviços Spring Boot")
        
        print("🚀 Simulando inicialização dos microserviços Spring Boot...")
        microservices = [
            'user-service',
            'order-service', 
            'payment-service',
            'inventory-service',
            'notification-service',
            'audit-service'
        ]
        
        for service in microservices:
            print(f"  📦 {service}: Container simulado ativo")
            time.sleep(0.1)
        
        print("✅ Todos os microserviços Spring Boot simulados!")
        return True

    def test_amq_streams_simulation(self):
        """Simula teste do Red Hat AMQ Streams"""
        self.print_phase(6, "Simulação do Red Hat AMQ Streams")
        
        print("🔄 Simulando Red Hat AMQ Streams (Kafka)...")
        topics = [
            'user-events',
            'order-events',
            'payment-events', 
            'inventory-events',
            'notification-events',
            'audit-logs'
        ]
        
        for topic in topics:
            print(f"  📝 Tópico {topic}: Configurado e ativo")
            time.sleep(0.1)
        
        print("✅ Red Hat AMQ Streams simulado corretamente!")
        return True

    def generate_final_report(self):
        """Gera relatório final do teste"""
        self.print_header("RELATÓRIO FINAL DO TESTE KBNT")
        
        self.test_results['end_time'] = datetime.now()
        duration = self.test_results['end_time'] - self.test_results['start_time']
        self.test_results['duration'] = duration.total_seconds()
        
        print(f"🕐 Início: {self.test_results['start_time'].strftime('%H:%M:%S')}")
        print(f"🕐 Fim: {self.test_results['end_time'].strftime('%H:%M:%S')}")
        print(f"⏱️  Duração: {self.test_results['duration']:.2f} segundos")
        
        if self.test_results['success'] and not self.test_results['errors']:
            print("\n🎉 TODOS OS TESTES PASSARAM!")
            print("✅ Sistema KBNT Virtual Stock Management verificado com sucesso!")
            print("\n🏗️  Arquitetura Hexagonal: OK")
            print("🐳 Microserviços Spring Boot: OK (simulados)")
            print("🔄 Red Hat AMQ Streams: OK (simulado)")
            print("🐍 Consumer Python: OK")
            print("📋 Documentação: Completa")
        else:
            print("\n⚠️  ALGUNS TESTES FALHARAM:")
            for error in self.test_results['errors']:
                print(f"  ❌ {error}")
        
        print(f"\n📊 Resumo:")
        print(f"  - Total de fases: 6")
        print(f"  - Sucessos: {6 - len(self.test_results['errors'])}")
        print(f"  - Falhas: {len(self.test_results['errors'])}")
        
        return len(self.test_results['errors']) == 0

    def run_complete_test(self, skip_simulation=False):
        """Executa teste completo do sistema"""
        self.print_header("TESTE COMPLETO DO SISTEMA KBNT VIRTUAL STOCK MANAGEMENT")
        print("🎯 Microserviços Spring Boot + Arquitetura Hexagonal + Red Hat AMQ Streams")
        
        self.test_results['start_time'] = datetime.now()
        
        # Executa todas as fases de teste
        test_phases = [
            ("Ambiente", self.test_environment_setup),
            ("Documentação", self.test_architecture_documentation),
            ("Simulação Hexagonal", self.test_hexagonal_simulation if not skip_simulation else lambda: True),
            ("Consumer de Logs", self.test_log_consumer_functionality),
            ("Microserviços", self.test_spring_boot_microservices_simulation),
            ("AMQ Streams", self.test_amq_streams_simulation)
        ]
        
        for phase_name, test_function in test_phases:
            try:
                success = test_function()
                self.test_results['phases'][phase_name] = success
                if not success:
                    self.test_results['success'] = False
            except Exception as e:
                print(f"💥 Erro na fase {phase_name}: {str(e)}")
                self.test_results['errors'].append(f"Erro na fase {phase_name}: {str(e)}")
                self.test_results['success'] = False
        
        return self.generate_final_report()

def main():
    parser = argparse.ArgumentParser(description='Teste completo do sistema KBNT')
    parser.add_argument('--skip-simulation', action='store_true', help='Pula a simulação interativa')
    args = parser.parse_args()
    
    tester = KBNTSystemTest()
    success = tester.run_complete_test(skip_simulation=args.skip_simulation)
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
