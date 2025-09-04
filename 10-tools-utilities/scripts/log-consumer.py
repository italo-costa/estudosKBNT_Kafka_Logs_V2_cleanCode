#!/usr/bin/env python3
"""
Consumidor de Logs do Kafka
Este script consome logs de um tópico Kafka e os processa
"""

import json
import logging
from datetime import datetime
from kafka import KafkaConsumer
from kafka.errors import KafkaError

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class LogConsumer:
    def __init__(self, bootstrap_servers=['localhost:9092'], topic='application-logs', 
                 group_id='log-consumer-group'):
        self.topic = topic
        self.group_id = group_id
        
        self.consumer = KafkaConsumer(
            topic,
            bootstrap_servers=bootstrap_servers,
            group_id=group_id,
            auto_offset_reset='earliest',  # Começa do início se não houver offset
            enable_auto_commit=True,
            auto_commit_interval_ms=1000,
            value_deserializer=lambda x: json.loads(x.decode('utf-8')),
            key_deserializer=lambda x: x.decode('utf-8') if x else None,
            consumer_timeout_ms=1000
        )
        
        # Contadores para estatísticas
        self.stats = {
            'total_messages': 0,
            'by_service': {},
            'by_level': {},
            'errors': 0
        }

    def process_log(self, log_entry):
        """Processa uma entrada de log"""
        try:
            # Atualiza estatísticas
            self.stats['total_messages'] += 1
            
            service = log_entry.get('service', 'unknown')
            level = log_entry.get('level', 'UNKNOWN')
            
            self.stats['by_service'][service] = self.stats['by_service'].get(service, 0) + 1
            self.stats['by_level'][level] = self.stats['by_level'].get(level, 0) + 1
            
            # Processa diferentes tipos de logs
            if level == 'ERROR':
                self.handle_error_log(log_entry)
            elif level == 'WARN':
                self.handle_warning_log(log_entry)
            elif level == 'AUDIT':
                self.handle_audit_log(log_entry)
            elif service == 'payment-service' and 'Payment processed' in log_entry.get('message', ''):
                self.handle_payment_log(log_entry)
            elif 'stock alert' in log_entry.get('message', '').lower():
                self.handle_inventory_alert(log_entry)
            elif log_entry.get('hexagonal_layer'):
                self.handle_hexagonal_layer_log(log_entry)
            
            # Log básico do processamento
            timestamp = log_entry.get('timestamp', 'unknown')
            message = log_entry.get('message', 'no message')
            
            logger.info(f"[{service}] [{level}] {timestamp}: {message}")
            
        except Exception as e:
            self.stats['errors'] += 1
            logger.error(f"Error processing log: {e}")

    def handle_error_log(self, log_entry):
        """Trata logs de erro especificamente"""
        service = log_entry.get('service', 'unknown')
        message = log_entry.get('message', '')
        
        # Alerta para erros críticos
        logger.error(f"🚨 CRITICAL ERROR in {service}: {message}")
        
        # Aqui você poderia enviar alertas, salvar em BD, etc.
        if 'timeout' in message.lower():
            logger.warning("⚠️  Database connection issue detected")
        elif 'failed' in message.lower():
            logger.warning("⚠️  Service failure detected")

    def handle_warning_log(self, log_entry):
        """Trata logs de warning"""
        service = log_entry.get('service', 'unknown')
        message = log_entry.get('message', '')
        
        if 'login attempt' in message.lower():
            logger.warning(f"🔒 Security alert: {message}")
        elif 'stock alert' in message.lower():
            item_id = log_entry.get('item_id', 'unknown')
            current_stock = log_entry.get('current_stock', 'unknown')
            logger.warning(f"📦 Inventory alert: {item_id} has {current_stock} units left")

    def handle_payment_log(self, log_entry):
        """Trata logs de pagamento"""
        amount = log_entry.get('amount', 0)
        transaction_id = log_entry.get('transaction_id', 'unknown')
        
        logger.info(f"💰 Payment processed: ${amount} (TX: {transaction_id})")
        
        # Alerta para pagamentos grandes
        if amount > 500:
            logger.warning(f"💳 Large payment alert: ${amount}")

    def handle_inventory_alert(self, log_entry):
        """Trata alertas de estoque"""
        item_id = log_entry.get('item_id', 'unknown')
        current_stock = log_entry.get('current_stock', 0)
        
        logger.warning(f"📦 Low stock: {item_id} = {current_stock} units")
        
        # Aqui você poderia disparar reposição automática
    
    def handle_hexagonal_layer_log(self, log_entry):
        """Processa logs da arquitetura hexagonal"""
        layer = log_entry.get('hexagonal_layer')
        domain = log_entry.get('domain', 'unknown')
        operation = log_entry.get('operation', 'unknown')
        
        logger.info(f"🏗️  {layer.upper()}: {domain} - {operation}")
        
        # Rastrea operações por camada
        if layer not in self.stats:
            self.stats[layer] = 0
        self.stats[layer] += 1
        
        # Operações específicas
        if layer == 'domain' and operation in ['stock-updated', 'payment-processed']:
            logger.info(f"   ⭐ Evento de domínio crítico: {operation}")
        elif layer == 'application' and operation == 'command-processed':
            logger.info(f"   📝 Comando de aplicação executado")
        elif layer == 'infrastructure' and operation in ['database-updated', 'kafka-published']:
            logger.info(f"   🔧 Operação de infraestrutura: {operation}")
    
    def handle_audit_log(self, log_entry):
        """Processa logs de auditoria"""
        user = log_entry.get('user', 'system')
        action = log_entry.get('action', 'unknown')
        resource = log_entry.get('resource', 'unknown')
        
        logger.info(f"📋 AUDITORIA: {user} executou {action} em {resource}")
        
        if 'audit' not in self.stats:
            self.stats['audit'] = 0
        self.stats['audit'] += 1

    def print_stats(self):
        """Imprime estatísticas de processamento"""
        print("\n" + "="*60)
        print("📊 PROCESSING STATISTICS - HEXAGONAL ARCHITECTURE")
        print("="*60)
        print(f"Total messages processed: {self.stats['total_messages']}")
        print(f"Processing errors: {self.stats['errors']}")
        
        print("\n📍 By Service:")
        for service, count in sorted(self.stats['by_service'].items()):
            print(f"  {service}: {count}")
            
        print("\n🚦 By Level:")
        for level, count in sorted(self.stats['by_level'].items()):
            print(f"  {level}: {count}")
        
        # Estatísticas de arquitetura hexagonal
        hexagonal_layers = ['domain', 'application', 'infrastructure']
        hexagonal_stats = {layer: self.stats.get(layer, 0) for layer in hexagonal_layers if self.stats.get(layer, 0) > 0}
        
        if hexagonal_stats:
            print("\n🏗️  By Hexagonal Layer:")
            for layer, count in hexagonal_stats.items():
                print(f"  {layer}: {count}")
        
        # Estatísticas especiais
        special_stats = ['audit', 'inventory_alerts']
        special_counts = {stat: self.stats.get(stat, 0) for stat in special_stats if self.stats.get(stat, 0) > 0}
        
        if special_counts:
            print("\n🎯 Special Events:")
            for stat, count in special_counts.items():
                print(f"  {stat}: {count}")
                
        print("="*60)

    def start_consuming(self):
        """Inicia o consumo de mensagens"""
        logger.info(f"Starting log consumer for topic '{self.topic}'")
        logger.info(f"Consumer group: {self.group_id}")
        
        try:
            # Subscreve no tópico
            self.consumer.subscribe([self.topic])
            
            logger.info("Waiting for messages... (Ctrl+C to stop)")
            
            for message in self.consumer:
                try:
                    log_entry = message.value
                    self.process_log(log_entry)
                    
                    # Imprime estatísticas a cada 10 mensagens
                    if self.stats['total_messages'] % 10 == 0:
                        self.print_stats()
                        
                except json.JSONDecodeError as e:
                    logger.error(f"Invalid JSON message: {e}")
                    self.stats['errors'] += 1
                except Exception as e:
                    logger.error(f"Error processing message: {e}")
                    self.stats['errors'] += 1
                    
        except KeyboardInterrupt:
            logger.info("Consumer stopped by user")
        except KafkaError as e:
            logger.error(f"Kafka error: {e}")
        finally:
            self.consumer.close()
            self.print_stats()
            logger.info("Consumer closed")

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Kafka Log Consumer')
    parser.add_argument('--bootstrap-servers', default='localhost:9092',
                       help='Kafka bootstrap servers (default: localhost:9092)')
    parser.add_argument('--topic', default='application-logs',
                       help='Kafka topic (default: application-logs)')
    parser.add_argument('--group-id', default='log-consumer-group',
                       help='Consumer group ID (default: log-consumer-group)')
    
    args = parser.parse_args()
    
    consumer = LogConsumer(
        bootstrap_servers=args.bootstrap_servers.split(','),
        topic=args.topic,
        group_id=args.group_id
    )
    
    consumer.start_consuming()
