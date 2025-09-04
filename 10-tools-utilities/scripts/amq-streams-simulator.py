#!/usr/bin/env python3
"""
Simulador Completo Red Hat AMQ Streams
Simula um ambiente completo de Kafka/AMQ Streams sem necessidade de Docker
para desenvolvimento e testes do sistema KBNT Virtual Stock Management
"""

import json
import threading
import time
import queue
import logging
import uuid
from datetime import datetime
from typing import Dict, List, Optional, Any
import argparse
from collections import defaultdict
import socketserver
import http.server
from urllib.parse import urlparse, parse_qs

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

class KafkaTopic:
    """Simula um tópico Kafka"""
    
    def __init__(self, name: str, partitions: int = 3, replication_factor: int = 1):
        self.name = name
        self.partitions = partitions
        self.replication_factor = replication_factor
        self.messages = defaultdict(list)  # partition -> list of messages
        self.consumers = defaultdict(list)  # consumer_group -> list of consumers
        self.offset_tracker = defaultdict(dict)  # consumer_group -> partition -> offset
        self.lock = threading.Lock()
        
    def produce(self, message: dict, partition: int = None, key: str = None):
        """Produz uma mensagem no tópico"""
        with self.lock:
            if partition is None:
                # Simple partitioning based on key hash or round-robin
                if key:
                    partition = hash(key) % self.partitions
                else:
                    partition = len(self.messages) % self.partitions
            
            message_envelope = {
                'offset': len(self.messages[partition]),
                'timestamp': datetime.now().isoformat(),
                'key': key,
                'value': message,
                'partition': partition,
                'topic': self.name
            }
            
            self.messages[partition].append(message_envelope)
            return message_envelope
    
    def consume(self, consumer_group: str, partition: int = None):
        """Consome mensagens do tópico"""
        with self.lock:
            if consumer_group not in self.offset_tracker:
                self.offset_tracker[consumer_group] = {p: 0 for p in range(self.partitions)}
            
            messages = []
            partitions_to_read = [partition] if partition is not None else range(self.partitions)
            
            for p in partitions_to_read:
                current_offset = self.offset_tracker[consumer_group].get(p, 0)
                partition_messages = self.messages[p][current_offset:]
                
                for msg in partition_messages:
                    messages.append(msg)
                    self.offset_tracker[consumer_group][p] = msg['offset'] + 1
            
            return messages
    
    def get_stats(self):
        """Retorna estatísticas do tópico"""
        with self.lock:
            total_messages = sum(len(msgs) for msgs in self.messages.values())
            return {
                'name': self.name,
                'partitions': self.partitions,
                'total_messages': total_messages,
                'messages_per_partition': {p: len(msgs) for p, msgs in self.messages.items()},
                'consumer_groups': list(self.offset_tracker.keys())
            }

class AMQStreamsSimulator:
    """Simulador principal do Red Hat AMQ Streams"""
    
    def __init__(self, port: int = 9092):
        self.port = port
        self.topics = {}
        self.running = False
        self.logger = logging.getLogger("AMQStreams")
        self.stats = {
            'start_time': None,
            'total_messages_produced': 0,
            'total_messages_consumed': 0,
            'active_producers': 0,
            'active_consumers': 0
        }
        
        # Cria tópicos padrão do KBNT
        self.create_default_topics()
        
    def create_default_topics(self):
        """Cria tópicos padrão do sistema KBNT"""
        default_topics = [
            {'name': 'user-events', 'partitions': 3},
            {'name': 'order-events', 'partitions': 3},
            {'name': 'payment-events', 'partitions': 3},
            {'name': 'inventory-events', 'partitions': 3},
            {'name': 'notification-events', 'partitions': 3},
            {'name': 'audit-logs', 'partitions': 1},
            {'name': 'application-logs', 'partitions': 2}
        ]
        
        for topic_config in default_topics:
            self.create_topic(topic_config['name'], topic_config['partitions'])
            
        self.logger.info(f"Created {len(default_topics)} default topics")
    
    def create_topic(self, name: str, partitions: int = 3, replication_factor: int = 1):
        """Cria um novo tópico"""
        if name not in self.topics:
            self.topics[name] = KafkaTopic(name, partitions, replication_factor)
            self.logger.info(f"Created topic '{name}' with {partitions} partitions")
            return True
        return False
    
    def produce(self, topic_name: str, message: dict, key: str = None):
        """Produz uma mensagem em um tópico"""
        if topic_name not in self.topics:
            self.logger.error(f"Topic '{topic_name}' does not exist")
            return None
            
        result = self.topics[topic_name].produce(message, key=key)
        self.stats['total_messages_produced'] += 1
        
        self.logger.debug(f"Produced message to {topic_name}[{result['partition']}] at offset {result['offset']}")
        return result
    
    def consume(self, topic_name: str, consumer_group: str):
        """Consome mensagens de um tópico"""
        if topic_name not in self.topics:
            self.logger.error(f"Topic '{topic_name}' does not exist")
            return []
            
        messages = self.topics[topic_name].consume(consumer_group)
        self.stats['total_messages_consumed'] += len(messages)
        
        if messages:
            self.logger.debug(f"Consumed {len(messages)} messages from {topic_name}")
        
        return messages
    
    def list_topics(self):
        """Lista todos os tópicos"""
        return list(self.topics.keys())
    
    def get_topic_info(self, topic_name: str):
        """Retorna informações de um tópico"""
        if topic_name in self.topics:
            return self.topics[topic_name].get_stats()
        return None
    
    def get_cluster_stats(self):
        """Retorna estatísticas do cluster"""
        topic_stats = {}
        total_partitions = 0
        
        for name, topic in self.topics.items():
            stats = topic.get_stats()
            topic_stats[name] = stats
            total_partitions += stats['partitions']
        
        return {
            'cluster_info': {
                'broker_count': 1,
                'topic_count': len(self.topics),
                'total_partitions': total_partitions,
                'port': self.port
            },
            'stats': self.stats,
            'topics': topic_stats
        }

class AMQStreamsRESTAPI:
    """API REST para simular Kafka REST Proxy"""
    
    def __init__(self, amq_simulator: AMQStreamsSimulator, port: int = 8082):
        self.amq_simulator = amq_simulator
        self.port = port
        self.logger = logging.getLogger("REST-API")
    
    def start_server(self):
        """Inicia o servidor REST"""
        
        class KafkaRESTHandler(http.server.BaseHTTPRequestHandler):
            def __init__(self, *args, amq_sim=None, **kwargs):
                self.amq_simulator = amq_sim
                super().__init__(*args, **kwargs)
            
            def do_GET(self):
                parsed = urlparse(self.path)
                path = parsed.path
                
                if path == '/topics':
                    # Lista tópicos
                    topics = self.amq_simulator.list_topics()
                    self.send_json_response(topics)
                    
                elif path.startswith('/topics/') and path.count('/') == 2:
                    # Informações de um tópico específico
                    topic_name = path.split('/')[2]
                    info = self.amq_simulator.get_topic_info(topic_name)
                    if info:
                        self.send_json_response(info)
                    else:
                        self.send_error(404, f"Topic {topic_name} not found")
                        
                elif path == '/cluster':
                    # Estatísticas do cluster
                    stats = self.amq_simulator.get_cluster_stats()
                    self.send_json_response(stats)
                    
                else:
                    self.send_error(404, "Not found")
            
            def do_POST(self):
                parsed = urlparse(self.path)
                path = parsed.path
                
                if path.startswith('/topics/') and path.endswith('/messages'):
                    # Produz mensagem
                    topic_name = path.split('/')[2]
                    
                    content_length = int(self.headers['Content-Length'])
                    post_data = self.rfile.read(content_length)
                    
                    try:
                        message = json.loads(post_data.decode('utf-8'))
                        result = self.amq_simulator.produce(topic_name, message)
                        
                        if result:
                            self.send_json_response(result, status=201)
                        else:
                            self.send_error(400, "Failed to produce message")
                    except json.JSONDecodeError:
                        self.send_error(400, "Invalid JSON")
                else:
                    self.send_error(404, "Not found")
            
            def send_json_response(self, data, status=200):
                self.send_response(status)
                self.send_header('Content-type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                response = json.dumps(data, indent=2)
                self.wfile.write(response.encode('utf-8'))
                
            def log_message(self, format, *args):
                # Silencia logs do servidor HTTP
                pass
        
        handler = lambda *args, **kwargs: KafkaRESTHandler(*args, amq_sim=self.amq_simulator, **kwargs)
        
        with socketserver.TCPServer(("", self.port), handler) as httpd:
            self.logger.info(f"REST API server started on port {self.port}")
            httpd.serve_forever()

class KafkaProducerSimulator:
    """Simulador do KafkaProducer"""
    
    def __init__(self, bootstrap_servers: str, amq_simulator: AMQStreamsSimulator):
        self.bootstrap_servers = bootstrap_servers
        self.amq_simulator = amq_simulator
        self.logger = logging.getLogger("Producer")
    
    def send(self, topic: str, value: dict, key: str = None):
        """Simula envio de mensagem"""
        return self.amq_simulator.produce(topic, value, key)
    
    def flush(self):
        """Simula flush (não faz nada na simulação)"""
        pass
        
    def close(self):
        """Simula fechamento do producer"""
        pass

class KafkaConsumerSimulator:
    """Simulador do KafkaConsumer"""
    
    def __init__(self, topic: str, bootstrap_servers: str, group_id: str, 
                 amq_simulator: AMQStreamsSimulator, consumer_timeout_ms: int = 1000):
        self.topic = topic
        self.bootstrap_servers = bootstrap_servers
        self.group_id = group_id
        self.amq_simulator = amq_simulator
        self.consumer_timeout_ms = consumer_timeout_ms
        self.logger = logging.getLogger("Consumer")
        self.running = False
    
    def subscribe(self, topics: List[str]):
        """Simula subscrição em tópicos"""
        self.topics = topics
        
    def poll(self, timeout_ms: int = 1000):
        """Simula polling de mensagens"""
        messages = {}
        for topic in [self.topic] if hasattr(self, 'topic') else self.topics:
            topic_messages = self.amq_simulator.consume(topic, self.group_id)
            if topic_messages:
                messages[topic] = topic_messages
        return messages
    
    def close(self):
        """Simula fechamento do consumer"""
        self.running = False

def start_amq_streams_environment(port: int = 9092, rest_port: int = 8082):
    """Inicia o ambiente AMQ Streams simulado"""
    
    print("="*70)
    print("RED HAT AMQ STREAMS SIMULATOR".center(70))
    print("="*70)
    print()
    
    # Inicia o simulador principal
    amq_simulator = AMQStreamsSimulator(port)
    amq_simulator.stats['start_time'] = datetime.now()
    
    print(f"🚀 AMQ Streams Broker started on port {port}")
    print(f"📝 Created topics: {', '.join(amq_simulator.list_topics())}")
    
    # Inicia API REST em thread separada
    rest_api = AMQStreamsRESTAPI(amq_simulator, rest_port)
    rest_thread = threading.Thread(target=rest_api.start_server, daemon=True)
    rest_thread.start()
    
    print(f"🌐 REST API started on http://localhost:{rest_port}")
    print()
    print("📋 Available endpoints:")
    print(f"   • Topics list:      GET  http://localhost:{rest_port}/topics")
    print(f"   • Topic info:       GET  http://localhost:{rest_port}/topics/<topic>")  
    print(f"   • Cluster stats:    GET  http://localhost:{rest_port}/cluster")
    print(f"   • Produce message:  POST http://localhost:{rest_port}/topics/<topic>/messages")
    print()
    
    return amq_simulator

def run_interactive_demo(amq_simulator: AMQStreamsSimulator):
    """Executa demo interativo"""
    
    print("🎮 DEMO INTERATIVO")
    print("-" * 50)
    
    # Produz algumas mensagens de exemplo
    sample_messages = [
        {'topic': 'user-events', 'message': {'user_id': '123', 'action': 'login', 'timestamp': datetime.now().isoformat()}},
        {'topic': 'order-events', 'message': {'order_id': '456', 'status': 'created', 'amount': 99.99}},
        {'topic': 'payment-events', 'message': {'payment_id': '789', 'amount': 99.99, 'status': 'processed'}},
        {'topic': 'inventory-events', 'message': {'item_id': 'ITEM001', 'stock_level': 5, 'alert': 'low_stock'}},
        {'topic': 'application-logs', 'message': {'level': 'INFO', 'service': 'order-service', 'message': 'Order processed successfully'}}
    ]
    
    print("📝 Producing sample messages...")
    for msg_config in sample_messages:
        result = amq_simulator.produce(msg_config['topic'], msg_config['message'])
        print(f"   ✅ {msg_config['topic']}: offset {result['offset']}")
    
    print()
    print("📖 Consuming messages...")
    
    consumer_group = "demo-consumer-group"
    for topic in ['user-events', 'order-events', 'payment-events']:
        messages = amq_simulator.consume(topic, consumer_group)
        print(f"   📥 {topic}: {len(messages)} messages")
        
        for msg in messages[:2]:  # Show first 2 messages
            print(f"      • {msg['value']}")
    
    print()
    print("📊 Cluster Statistics:")
    stats = amq_simulator.get_cluster_stats()
    print(f"   • Topics: {stats['cluster_info']['topic_count']}")
    print(f"   • Partitions: {stats['cluster_info']['total_partitions']}")
    print(f"   • Messages produced: {stats['stats']['total_messages_produced']}")
    print(f"   • Messages consumed: {stats['stats']['total_messages_consumed']}")

def main():
    parser = argparse.ArgumentParser(description='Red Hat AMQ Streams Simulator')
    parser.add_argument('--port', type=int, default=9092, help='Kafka broker port')
    parser.add_argument('--rest-port', type=int, default=8082, help='REST API port')  
    parser.add_argument('--demo', action='store_true', help='Run interactive demo')
    parser.add_argument('--verbose', action='store_true', help='Verbose logging')
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    # Inicia o ambiente
    amq_simulator = start_amq_streams_environment(args.port, args.rest_port)
    
    if args.demo:
        run_interactive_demo(amq_simulator)
    
    try:
        print("✅ AMQ Streams environment is ready!")
        print("   Press Ctrl+C to stop...")
        print()
        
        # Mantém o servidor rodando
        while True:
            time.sleep(1)
            
    except KeyboardInterrupt:
        print("\n🛑 Stopping AMQ Streams environment...")
        print("👋 Goodbye!")

if __name__ == "__main__":
    main()
