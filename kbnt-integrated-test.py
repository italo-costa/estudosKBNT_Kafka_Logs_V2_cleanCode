#!/usr/bin/env python3
"""
Teste Completo Integrado KBNT Virtual Stock Management
Sistema completo com AMQ Streams simulado + Consumer + Microserviços Spring Boot
"""

import json
import threading
import time
import subprocess
import sys
import os
from datetime import datetime
from typing import List, Dict
import logging

# Importa o simulador AMQ Streams
import importlib.util
spec = importlib.util.spec_from_file_location("amq_streams_simulator", "amq-streams-simulator.py")
amq_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(amq_module)

AMQStreamsSimulator = amq_module.AMQStreamsSimulator
start_amq_streams_environment = amq_module.start_amq_streams_environment

# Configuração de logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("KBNT-Integration")

class KBNTIntegratedSystem:
    """Sistema integrado completo KBNT"""
    
    def __init__(self):
        self.amq_simulator = None
        self.consumer_thread = None
        self.producer_thread = None
        self.running = False
        
    def print_banner(self, text):
        """Imprime banner formatado"""
        print("\n" + "="*80)
        print(text.center(80))
        print("="*80 + "\n")
    
    def start_amq_streams(self):
        """Inicia o simulador AMQ Streams"""
        print("🚀 Iniciando Red Hat AMQ Streams simulado...")
        
        self.amq_simulator = AMQStreamsSimulator()
        self.amq_simulator.stats['start_time'] = datetime.now()
        
        # Inicia API REST em thread separada
        AMQStreamsRESTAPI = amq_module.AMQStreamsRESTAPI
        rest_api = AMQStreamsRESTAPI(self.amq_simulator, 8082)
        rest_thread = threading.Thread(target=rest_api.start_server, daemon=True)
        rest_thread.start()
        
        print("✅ AMQ Streams iniciado com sucesso!")
        print(f"   📝 Tópicos: {', '.join(self.amq_simulator.list_topics())}")
        print(f"   🌐 API REST: http://localhost:8082")
        
        return True
    
    def simulate_microservices_traffic(self, duration_seconds=30):
        """Simula tráfego dos microserviços Spring Boot"""
        print(f"🏗️  Simulando tráfego de microserviços por {duration_seconds} segundos...")
        
        microservices = [
            {'name': 'user-service', 'topic': 'user-events'},
            {'name': 'order-service', 'topic': 'order-events'},
            {'name': 'payment-service', 'topic': 'payment-events'},
            {'name': 'inventory-service', 'topic': 'inventory-events'},
            {'name': 'notification-service', 'topic': 'notification-events'}
        ]
        
        def produce_messages():
            start_time = time.time()
            message_count = 0
            
            while time.time() - start_time < duration_seconds and self.running:
                # Seleciona um microserviço aleatório
                import random
                service = random.choice(microservices)
                
                # Gera mensagem hexagonal realística
                hexagonal_layers = ['domain', 'application', 'infrastructure']
                operations = ['command-processed', 'event-published', 'stock-updated', 'payment-processed']
                levels = ['INFO', 'WARN', 'ERROR', 'DEBUG']
                
                message = {
                    'timestamp': datetime.now().isoformat(),
                    'service': service['name'],
                    'level': random.choice(levels),
                    'message': f"Operation executed in {service['name']}",
                    'hexagonal_layer': random.choice(hexagonal_layers),
                    'domain': service['name'].split('-')[0],
                    'operation': random.choice(operations),
                    'correlation_id': f"corr-{message_count:06d}",
                    'session_id': f"sess-{random.randint(1000, 9999)}"
                }
                
                # Adiciona campos específicos baseado no serviço
                if service['name'] == 'payment-service' and random.random() < 0.3:
                    message.update({
                        'amount': round(random.uniform(10.0, 500.0), 2),
                        'transaction_id': f"TX{random.randint(100000, 999999)}"
                    })
                elif service['name'] == 'inventory-service' and random.random() < 0.2:
                    message.update({
                        'item_id': f"ITEM{random.randint(1000, 9999)}",
                        'current_stock': random.randint(0, 10)
                    })
                
                # Produz mensagem no tópico apropriado
                self.amq_simulator.produce(service['topic'], message)
                
                # Também envia para application-logs para o consumer
                log_message = {
                    'timestamp': message['timestamp'],
                    'service': message['service'],
                    'level': message['level'],
                    'message': message['message'],
                    'hexagonal_layer': message.get('hexagonal_layer'),
                    'domain': message.get('domain'),
                    'operation': message.get('operation')
                }
                
                if 'amount' in message:
                    log_message.update({
                        'amount': message['amount'],
                        'transaction_id': message['transaction_id']
                    })
                elif 'item_id' in message:
                    log_message.update({
                        'item_id': message['item_id'],
                        'current_stock': message['current_stock']
                    })
                
                self.amq_simulator.produce('application-logs', log_message)
                message_count += 1
                
                # Pausa entre mensagens
                time.sleep(random.uniform(0.1, 0.5))
            
            print(f"   ✅ Produzidas {message_count} mensagens de microserviços")
        
        self.producer_thread = threading.Thread(target=produce_messages, daemon=True)
        self.producer_thread.start()
    
    def start_log_consumer(self):
        """Inicia consumer de logs que processa mensagens do AMQ Streams"""
        print("📖 Iniciando consumer de logs...")
        
        def consume_logs():
            consumer_group = "kbnt-log-consumer"
            processed_count = 0
            
            while self.running:
                try:
                    # Consume mensagens do tópico application-logs
                    messages = self.amq_simulator.consume('application-logs', consumer_group)
                    
                    for message in messages:
                        log_entry = message['value']
                        self.process_log_entry(log_entry)
                        processed_count += 1
                    
                    if messages:
                        print(f"   📥 Processadas {len(messages)} mensagens (total: {processed_count})")
                    
                    time.sleep(1)  # Poll interval
                    
                except Exception as e:
                    logger.error(f"Erro no consumer: {e}")
                    time.sleep(5)
            
            print(f"   ✅ Consumer processou {processed_count} mensagens no total")
        
        self.consumer_thread = threading.Thread(target=consume_logs, daemon=True)
        self.consumer_thread.start()
    
    def process_log_entry(self, log_entry):
        """Processa uma entrada de log (simulação do LogConsumer)"""
        service = log_entry.get('service', 'unknown')
        level = log_entry.get('level', 'INFO')
        message = log_entry.get('message', '')
        
        # Processa logs especiais
        if level == 'ERROR':
            print(f"   🚨 ERROR in {service}: {message}")
        elif log_entry.get('hexagonal_layer'):
            layer = log_entry.get('hexagonal_layer')
            operation = log_entry.get('operation', '')
            print(f"   🏗️  {layer.upper()}: {service} - {operation}")
        elif log_entry.get('amount'):
            amount = log_entry.get('amount')
            tx_id = log_entry.get('transaction_id', '')
            print(f"   💰 PAYMENT: ${amount} ({tx_id})")
        elif log_entry.get('current_stock') is not None and log_entry.get('current_stock') < 5:
            item_id = log_entry.get('item_id')
            stock = log_entry.get('current_stock')
            print(f"   📦 LOW STOCK: {item_id} = {stock} units")
    
    def show_real_time_stats(self):
        """Mostra estatísticas em tempo real"""
        print("\n📊 Estatísticas em Tempo Real:")
        
        while self.running:
            try:
                stats = self.amq_simulator.get_cluster_stats()
                
                print(f"\\r   📈 Mensagens produzidas: {stats['stats']['total_messages_produced']:<6} | "
                      f"Consumidas: {stats['stats']['total_messages_consumed']:<6} | "
                      f"Uptime: {self._get_uptime(stats)}", end='', flush=True)
                
                time.sleep(2)
            except:
                break
    
    def _get_uptime(self, stats):
        """Calcula uptime do sistema"""
        start_time = stats['stats']['start_time']
        if isinstance(start_time, str):
            start_time = datetime.fromisoformat(start_time)
        
        uptime = datetime.now() - start_time
        return f"{int(uptime.total_seconds())}s"
    
    def run_integration_test(self, duration_seconds=60):
        """Executa teste de integração completo"""
        self.print_banner("TESTE DE INTEGRAÇÃO KBNT - SISTEMA COMPLETO")
        
        print("🎯 Componentes do sistema:")
        print("   • Red Hat AMQ Streams (simulado)")
        print("   • Microserviços Spring Boot (simulados)")
        print("   • Consumer de Logs Python")
        print("   • Arquitetura Hexagonal")
        print()
        
        try:
            self.running = True
            
            # 1. Inicia AMQ Streams
            if not self.start_amq_streams():
                return False
            
            time.sleep(2)
            
            # 2. Inicia consumer de logs
            self.start_log_consumer()
            
            time.sleep(2)
            
            # 3. Inicia simulação de microserviços
            self.simulate_microservices_traffic(duration_seconds)
            
            print(f"🔄 Sistema rodando por {duration_seconds} segundos...")
            print("   (pressione Ctrl+C para parar antecipadamente)")
            
            # 4. Mostra estatísticas em tempo real
            stats_thread = threading.Thread(target=self.show_real_time_stats, daemon=True)
            stats_thread.start()
            
            # 5. Aguarda duração do teste
            start_time = time.time()
            while time.time() - start_time < duration_seconds and self.running:
                time.sleep(1)
            
            print("\n\n🏁 Finalizando teste...")
            self.running = False
            
            # 6. Mostra estatísticas finais
            self.show_final_stats()
            
            return True
            
        except KeyboardInterrupt:
            print("\n\n⚠️  Teste interrompido pelo usuário")
            self.running = False
            return False
        except Exception as e:
            print(f"\n❌ Erro no teste: {e}")
            self.running = False
            return False
    
    def show_final_stats(self):
        """Mostra estatísticas finais do teste"""
        self.print_banner("RELATÓRIO FINAL DO TESTE INTEGRADO")
        
        stats = self.amq_simulator.get_cluster_stats()
        
        print("📊 Estatísticas do Cluster:")
        print(f"   • Tópicos criados: {stats['cluster_info']['topic_count']}")
        print(f"   • Partições totais: {stats['cluster_info']['total_partitions']}")
        print(f"   • Mensagens produzidas: {stats['stats']['total_messages_produced']}")
        print(f"   • Mensagens consumidas: {stats['stats']['total_messages_consumed']}")
        
        print("\n📈 Por Tópico:")
        for topic_name, topic_stats in stats['topics'].items():
            if topic_stats['total_messages'] > 0:
                print(f"   • {topic_name}: {topic_stats['total_messages']} mensagens")
        
        efficiency = 0
        if stats['stats']['total_messages_produced'] > 0:
            efficiency = (stats['stats']['total_messages_consumed'] / stats['stats']['total_messages_produced']) * 100
        
        print(f"\n🎯 Eficiência do sistema: {efficiency:.1f}%")
        
        if efficiency > 90:
            print("✅ SISTEMA FUNCIONANDO PERFEITAMENTE!")
        elif efficiency > 70:
            print("⚠️  Sistema funcionando bem, mas pode ser otimizado")
        else:
            print("❌ Sistema precisa de ajustes")

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Teste Integrado KBNT Virtual Stock Management')
    parser.add_argument('--duration', type=int, default=60, help='Duração do teste em segundos')
    parser.add_argument('--verbose', action='store_true', help='Logging verboso')
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    system = KBNTIntegratedSystem()
    success = system.run_integration_test(args.duration)
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
