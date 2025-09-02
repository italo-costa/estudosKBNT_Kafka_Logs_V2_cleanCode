#!/usr/bin/env python3
"""
KBNT Virtualização Workflow Demo
Demonstra o fluxo completo: Microserviço A → AMQ Streams Topic → Microserviço B
Com monitoramento Prometheus integrado
"""

import json
import time
import uuid
import threading
from datetime import datetime
from typing import Dict, List, Optional
import queue
import logging
from collections import defaultdict

# Configurar logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class PrometheusMetrics:
    """Simula métricas do Prometheus para monitoramento"""
    
    def __init__(self):
        self.metrics = {
            # Métricas de mensagens
            'kbnt_messages_sent_total': defaultdict(int),
            'kbnt_messages_received_total': defaultdict(int),
            'kbnt_messages_processed_total': defaultdict(int),
            'kbnt_messages_failed_total': defaultdict(int),
            
            # Métricas de virtualização
            'kbnt_virtualization_requests_total': defaultdict(int),
            'kbnt_virtual_resources_created_total': defaultdict(int),
            'kbnt_virtual_resources_active': defaultdict(int),
            
            # Métricas de performance
            'kbnt_processing_duration_seconds': [],
            'kbnt_queue_size': defaultdict(int),
            
            # Métricas de tópicos
            'kbnt_topic_messages_total': defaultdict(int),
            'kbnt_consumer_lag': defaultdict(int)
        }
    
    def increment_counter(self, metric_name: str, labels: Dict[str, str] = None):
        """Incrementa um contador com labels"""
        key = self._build_key(metric_name, labels)
        self.metrics[metric_name][key] += 1
        
    def set_gauge(self, metric_name: str, value: float, labels: Dict[str, str] = None):
        """Define um valor de gauge"""
        key = self._build_key(metric_name, labels)
        self.metrics[metric_name][key] = value
    
    def observe_histogram(self, metric_name: str, value: float, labels: Dict[str, str] = None):
        """Adiciona observação ao histograma"""
        self.metrics[metric_name].append({
            'value': value,
            'labels': labels or {},
            'timestamp': time.time()
        })
    
    def _build_key(self, metric_name: str, labels: Dict[str, str] = None):
        """Constrói chave única para métrica com labels"""
        if not labels:
            return 'default'
        return '|'.join([f"{k}={v}" for k, v in sorted(labels.items())])
    
    def get_metrics_summary(self):
        """Retorna resumo das métricas coletadas"""
        summary = {}
        for metric_name, values in self.metrics.items():
            if isinstance(values, list):  # Histograma
                summary[metric_name] = {
                    'count': len(values),
                    'avg': sum(v['value'] for v in values) / len(values) if values else 0
                }
            else:  # Counter ou Gauge
                summary[metric_name] = dict(values)
        return summary

class VirtualizationMessage:
    """Representa uma mensagem de virtualização"""
    
    def __init__(self, message_type: str, payload: dict):
        self.message_id = str(uuid.uuid4())
        self.message_type = message_type
        self.payload = payload
        self.timestamp = datetime.now().isoformat()
        self.processing_history = []
    
    def add_processing_step(self, service: str, operation: str, status: str = "SUCCESS"):
        """Adiciona passo de processamento"""
        self.processing_history.append({
            'service': service,
            'operation': operation,
            'status': status,
            'timestamp': datetime.now().isoformat()
        })
    
    def to_kafka_message(self):
        """Converte para formato de mensagem Kafka"""
        return {
            'key': self.message_id,
            'value': {
                'messageId': self.message_id,
                'messageType': self.message_type,
                'timestamp': self.timestamp,
                'payload': self.payload,
                'processingHistory': self.processing_history,
                'hexagonal_layer': 'application',
                'domain': 'virtualization'
            }
        }

class AMQStreamsSimulator:
    """Simulador simplificado do AMQ Streams para este demo"""
    
    def __init__(self):
        self.topics = {
            'virtualization-requests': queue.Queue(),
            'virtualization-events': queue.Queue(), 
            'resource-allocation': queue.Queue(),
            'monitoring-metrics': queue.Queue()
        }
        self.consumers = {}
        
    def produce(self, topic: str, message: dict):
        """Produz mensagem para um tópico"""
        if topic in self.topics:
            self.topics[topic].put({
                'offset': int(time.time() * 1000),
                'partition': 0,
                'timestamp': time.time(),
                'key': message.get('key'),
                'value': message.get('value', message)
            })
            logger.info(f"Message produced to topic '{topic}': {message.get('key', 'no-key')}")
    
    def consume(self, topic: str, consumer_group: str, timeout: float = 1.0) -> List[dict]:
        """Consome mensagens de um tópico"""
        messages = []
        if topic in self.topics:
            start_time = time.time()
            while time.time() - start_time < timeout:
                try:
                    message = self.topics[topic].get_nowait()
                    messages.append(message)
                except queue.Empty:
                    break
        return messages

class VirtualizationProducerService:
    """Microserviço Produtor - Recebe requests e produz mensagens para AMQ Streams"""
    
    def __init__(self, service_name: str, amq_streams: AMQStreamsSimulator, metrics: PrometheusMetrics):
        self.service_name = service_name
        self.amq_streams = amq_streams
        self.metrics = metrics
        self.request_queue = queue.Queue()
        self.running = False
        
    def receive_virtualization_request(self, request_type: str, resource_spec: dict):
        """Recebe uma solicitação de virtualização (ex: via REST API)"""
        logger.info(f"🔄 {self.service_name} received virtualization request: {request_type}")
        
        # Métrica: Request recebido
        self.metrics.increment_counter('kbnt_virtualization_requests_total', 
                                     {'service': self.service_name, 'type': request_type})
        
        # Processar na camada de domínio (hexagonal architecture)
        processed_request = self._process_domain_logic(request_type, resource_spec)
        
        if processed_request:
            # Criar mensagem de virtualização
            message = VirtualizationMessage(request_type, processed_request)
            message.add_processing_step(self.service_name, "domain-validation", "SUCCESS")
            
            # Publicar no tópico AMQ Streams (Infrastructure Layer)
            self._publish_to_topic(message)
            
            logger.info(f"✅ {self.service_name} successfully processed and published message {message.message_id}")
            return message.message_id
        else:
            logger.error(f"❌ {self.service_name} failed to process request")
            self.metrics.increment_counter('kbnt_messages_failed_total', 
                                         {'service': self.service_name, 'reason': 'domain-validation-failed'})
            return None
    
    def _process_domain_logic(self, request_type: str, resource_spec: dict) -> Optional[dict]:
        """Processa lógica de domínio (Domain Layer)"""
        logger.info(f"🏗️  {self.service_name} - DOMAIN LAYER: Processing {request_type}")
        
        # Simular validações de domínio
        time.sleep(0.1)  # Simula processamento
        
        if request_type == "CREATE_VIRTUAL_MACHINE":
            return self._validate_vm_creation(resource_spec)
        elif request_type == "ALLOCATE_STORAGE":
            return self._validate_storage_allocation(resource_spec)
        elif request_type == "CREATE_NETWORK":
            return self._validate_network_creation(resource_spec)
        else:
            return None
    
    def _validate_vm_creation(self, spec: dict) -> dict:
        """Valida criação de VM"""
        required_fields = ['cpu', 'memory', 'disk', 'network']
        
        if all(field in spec for field in required_fields):
            return {
                'virtualResourceId': f"VM-{uuid.uuid4().hex[:8].upper()}",
                'resourceType': 'virtual-machine',
                'specification': spec,
                'status': 'VALIDATED',
                'estimatedProvisionTime': '5-10 minutes'
            }
        return None
    
    def _validate_storage_allocation(self, spec: dict) -> dict:
        """Valida alocação de storage"""
        if 'size' in spec and spec['size'] > 0:
            return {
                'virtualResourceId': f"STOR-{uuid.uuid4().hex[:8].upper()}",
                'resourceType': 'virtual-storage',
                'specification': spec,
                'status': 'VALIDATED',
                'estimatedProvisionTime': '2-5 minutes'
            }
        return None
    
    def _validate_network_creation(self, spec: dict) -> dict:
        """Valida criação de rede"""
        if 'subnet' in spec:
            return {
                'virtualResourceId': f"NET-{uuid.uuid4().hex[:8].upper()}",
                'resourceType': 'virtual-network',
                'specification': spec,
                'status': 'VALIDATED',
                'estimatedProvisionTime': '1-3 minutes'
            }
        return None
    
    def _publish_to_topic(self, message: VirtualizationMessage):
        """Publica mensagem no tópico AMQ Streams (Infrastructure Layer)"""
        start_time = time.time()
        
        logger.info(f"🏗️  {self.service_name} - INFRASTRUCTURE LAYER: Publishing to AMQ Streams")
        
        # Adicionar step de publicação
        message.add_processing_step(self.service_name, "amq-streams-publish", "SUCCESS")
        
        # Publicar no tópico
        kafka_message = message.to_kafka_message()
        self.amq_streams.produce('virtualization-requests', kafka_message)
        
        # Métricas
        duration = time.time() - start_time
        self.metrics.increment_counter('kbnt_messages_sent_total', 
                                     {'service': self.service_name, 'topic': 'virtualization-requests'})
        self.metrics.observe_histogram('kbnt_processing_duration_seconds', duration, 
                                     {'service': self.service_name, 'operation': 'publish'})
        self.metrics.increment_counter('kbnt_topic_messages_total', {'topic': 'virtualization-requests'})

class VirtualizationConsumerService:
    """Microserviço Consumidor - Consome mensagens do AMQ Streams e processa virtualização"""
    
    def __init__(self, service_name: str, amq_streams: AMQStreamsSimulator, metrics: PrometheusMetrics):
        self.service_name = service_name
        self.amq_streams = amq_streams
        self.metrics = metrics
        self.running = False
        self.virtual_resources = {}
        
    def start_consuming(self):
        """Inicia consumo de mensagens"""
        logger.info(f"🔄 {self.service_name} started consuming from virtualization-requests topic")
        self.running = True
        
        while self.running:
            messages = self.amq_streams.consume('virtualization-requests', f'{self.service_name}-group')
            
            for message in messages:
                self._process_virtualization_message(message)
            
            time.sleep(0.1)  # Polling interval
    
    def stop_consuming(self):
        """Para o consumo"""
        self.running = False
        logger.info(f"🛑 {self.service_name} stopped consuming")
    
    def _process_virtualization_message(self, kafka_message: dict):
        """Processa mensagem de virtualização recebida"""
        start_time = time.time()
        
        try:
            message_value = kafka_message['value']
            message_id = message_value['messageId']
            message_type = message_value['messageType']
            payload = message_value['payload']
            
            logger.info(f"📥 {self.service_name} processing message {message_id} ({message_type})")
            
            # Métrica: Message received
            self.metrics.increment_counter('kbnt_messages_received_total', 
                                         {'service': self.service_name, 'type': message_type})
            
            # Processar na camada de aplicação (Application Layer)
            success = self._process_application_logic(message_type, payload, message_id)
            
            if success:
                # Publicar evento de sucesso
                self._publish_virtualization_event(message_id, "VIRTUALIZATION_COMPLETED", payload)
                
                # Métricas de sucesso
                self.metrics.increment_counter('kbnt_messages_processed_total', 
                                             {'service': self.service_name, 'status': 'success'})
                self.metrics.increment_counter('kbnt_virtual_resources_created_total', 
                                             {'resource_type': payload.get('resourceType', 'unknown')})
                
                logger.info(f"✅ {self.service_name} successfully processed message {message_id}")
            else:
                self.metrics.increment_counter('kbnt_messages_failed_total', 
                                             {'service': self.service_name, 'reason': 'processing-failed'})
                logger.error(f"❌ {self.service_name} failed to process message {message_id}")
            
            # Métrica de duração
            duration = time.time() - start_time
            self.metrics.observe_histogram('kbnt_processing_duration_seconds', duration, 
                                         {'service': self.service_name, 'operation': 'process'})
            
        except Exception as e:
            logger.error(f"💥 {self.service_name} error processing message: {e}")
            self.metrics.increment_counter('kbnt_messages_failed_total', 
                                         {'service': self.service_name, 'reason': 'exception'})
    
    def _process_application_logic(self, message_type: str, payload: dict, message_id: str) -> bool:
        """Processa lógica de aplicação (Application Layer)"""
        logger.info(f"🏗️  {self.service_name} - APPLICATION LAYER: Processing {message_type}")
        
        # Simular tempo de processamento baseado no tipo de recurso
        if message_type == "CREATE_VIRTUAL_MACHINE":
            time.sleep(0.5)  # VM creation takes longer
            return self._create_virtual_machine(payload, message_id)
        elif message_type == "ALLOCATE_STORAGE":
            time.sleep(0.2)  # Storage is faster
            return self._allocate_storage(payload, message_id)
        elif message_type == "CREATE_NETWORK":
            time.sleep(0.1)  # Network is fastest
            return self._create_network(payload, message_id)
        
        return False
    
    def _create_virtual_machine(self, payload: dict, message_id: str) -> bool:
        """Cria máquina virtual"""
        resource_id = payload.get('virtualResourceId')
        spec = payload.get('specification', {})
        
        logger.info(f"🖥️  Creating Virtual Machine {resource_id}")
        logger.info(f"   • CPU: {spec.get('cpu', 'unknown')} cores")
        logger.info(f"   • Memory: {spec.get('memory', 'unknown')} GB")
        logger.info(f"   • Disk: {spec.get('disk', 'unknown')} GB")
        
        # Simular criação da VM
        virtual_resource = {
            'resourceId': resource_id,
            'type': 'virtual-machine',
            'status': 'RUNNING',
            'specification': spec,
            'createdAt': datetime.now().isoformat(),
            'messageId': message_id
        }
        
        self.virtual_resources[resource_id] = virtual_resource
        self.metrics.set_gauge('kbnt_virtual_resources_active', len(self.virtual_resources), 
                              {'resource_type': 'virtual-machine'})
        
        return True
    
    def _allocate_storage(self, payload: dict, message_id: str) -> bool:
        """Aloca storage virtual"""
        resource_id = payload.get('virtualResourceId')
        spec = payload.get('specification', {})
        
        logger.info(f"💾 Allocating Virtual Storage {resource_id}")
        logger.info(f"   • Size: {spec.get('size', 'unknown')} GB")
        logger.info(f"   • Type: {spec.get('type', 'standard')}")
        
        virtual_resource = {
            'resourceId': resource_id,
            'type': 'virtual-storage',
            'status': 'ALLOCATED',
            'specification': spec,
            'createdAt': datetime.now().isoformat(),
            'messageId': message_id
        }
        
        self.virtual_resources[resource_id] = virtual_resource
        self.metrics.set_gauge('kbnt_virtual_resources_active', len(self.virtual_resources),
                              {'resource_type': 'virtual-storage'})
        
        return True
    
    def _create_network(self, payload: dict, message_id: str) -> bool:
        """Cria rede virtual"""
        resource_id = payload.get('virtualResourceId')
        spec = payload.get('specification', {})
        
        logger.info(f"🌐 Creating Virtual Network {resource_id}")
        logger.info(f"   • Subnet: {spec.get('subnet', 'unknown')}")
        logger.info(f"   • VLAN: {spec.get('vlan', 'default')}")
        
        virtual_resource = {
            'resourceId': resource_id,
            'type': 'virtual-network',
            'status': 'ACTIVE',
            'specification': spec,
            'createdAt': datetime.now().isoformat(),
            'messageId': message_id
        }
        
        self.virtual_resources[resource_id] = virtual_resource
        self.metrics.set_gauge('kbnt_virtual_resources_active', len(self.virtual_resources),
                              {'resource_type': 'virtual-network'})
        
        return True
    
    def _publish_virtualization_event(self, original_message_id: str, event_type: str, payload: dict):
        """Publica evento de virtualização (Infrastructure Layer)"""
        logger.info(f"🏗️  {self.service_name} - INFRASTRUCTURE LAYER: Publishing event {event_type}")
        
        event = {
            'eventId': str(uuid.uuid4()),
            'originalMessageId': original_message_id,
            'eventType': event_type,
            'service': self.service_name,
            'timestamp': datetime.now().isoformat(),
            'payload': payload,
            'hexagonal_layer': 'infrastructure',
            'domain': 'virtualization'
        }
        
        self.amq_streams.produce('virtualization-events', event)
        self.metrics.increment_counter('kbnt_messages_sent_total', 
                                     {'service': self.service_name, 'topic': 'virtualization-events'})

class MonitoringService:
    """Serviço de monitoramento que simula Prometheus"""
    
    def __init__(self, metrics: PrometheusMetrics):
        self.metrics = metrics
        
    def print_metrics_dashboard(self):
        """Imprime dashboard de métricas estilo Prometheus"""
        print("\n" + "="*80)
        print("📊 PROMETHEUS METRICS DASHBOARD - KBNT VIRTUALIZATION")
        print("="*80)
        
        summary = self.metrics.get_metrics_summary()
        
        # Métricas de mensagens
        print("\n🔄 MESSAGE METRICS:")
        print("-" * 50)
        for metric in ['kbnt_messages_sent_total', 'kbnt_messages_received_total', 'kbnt_messages_processed_total']:
            if metric in summary:
                print(f"{metric}:")
                for key, value in summary[metric].items():
                    if key != 'default':
                        print(f"  {key}: {value}")
        
        # Métricas de virtualização
        print("\n🖥️  VIRTUALIZATION METRICS:")
        print("-" * 50)
        for metric in ['kbnt_virtualization_requests_total', 'kbnt_virtual_resources_created_total', 'kbnt_virtual_resources_active']:
            if metric in summary:
                print(f"{metric}:")
                for key, value in summary[metric].items():
                    if key != 'default':
                        print(f"  {key}: {value}")
        
        # Métricas de performance
        print("\n⚡ PERFORMANCE METRICS:")
        print("-" * 50)
        if 'kbnt_processing_duration_seconds' in summary:
            duration_data = summary['kbnt_processing_duration_seconds']
            print(f"kbnt_processing_duration_seconds:")
            print(f"  count: {duration_data['count']}")
            print(f"  avg: {duration_data['avg']:.3f}s")
        
        # Métricas de tópicos
        print("\n📨 TOPIC METRICS:")
        print("-" * 50)
        if 'kbnt_topic_messages_total' in summary:
            for key, value in summary['kbnt_topic_messages_total'].items():
                if key != 'default':
                    print(f"kbnt_topic_messages_total: {key} = {value}")
        
        print("\n" + "="*80)

class VirtualizationWorkflowDemo:
    """Demo completo do workflow de virtualização"""
    
    def __init__(self):
        self.amq_streams = AMQStreamsSimulator()
        self.metrics = PrometheusMetrics()
        
        # Microserviços
        self.producer_service = VirtualizationProducerService("virtualization-producer-service", 
                                                             self.amq_streams, self.metrics)
        self.consumer_service = VirtualizationConsumerService("virtualization-consumer-service",
                                                             self.amq_streams, self.metrics)
        
        # Monitoramento
        self.monitoring = MonitoringService(self.metrics)
        
    def run_complete_demo(self):
        """Executa demo completo do workflow"""
        print("🚀 KBNT VIRTUALIZATION WORKFLOW DEMO")
        print("="*80)
        print("🏗️  Architecture: Producer Microservice → AMQ Streams → Consumer Microservice")
        print("📊 Monitoring: Prometheus metrics integrated")
        print("🔄 Flow: REST API → Domain → Application → Infrastructure → Event-Driven")
        print()
        
        # Iniciar consumer em thread separada
        consumer_thread = threading.Thread(target=self.consumer_service.start_consuming)
        consumer_thread.daemon = True
        consumer_thread.start()
        
        time.sleep(0.5)  # Aguardar consumer inicializar
        
        # Cenários de virtualização
        scenarios = [
            {
                'name': 'Create Virtual Machine',
                'type': 'CREATE_VIRTUAL_MACHINE',
                'spec': {
                    'cpu': 4,
                    'memory': 8,
                    'disk': 100,
                    'network': 'vlan-100'
                }
            },
            {
                'name': 'Allocate Storage',
                'type': 'ALLOCATE_STORAGE', 
                'spec': {
                    'size': 500,
                    'type': 'SSD',
                    'iops': 3000
                }
            },
            {
                'name': 'Create Network',
                'type': 'CREATE_NETWORK',
                'spec': {
                    'subnet': '10.0.1.0/24',
                    'vlan': 200,
                    'gateway': '10.0.1.1'
                }
            },
            {
                'name': 'Create Another VM',
                'type': 'CREATE_VIRTUAL_MACHINE',
                'spec': {
                    'cpu': 2,
                    'memory': 4,
                    'disk': 50,
                    'network': 'vlan-200'
                }
            }
        ]
        
        print("🎯 EXECUTING VIRTUALIZATION SCENARIOS:")
        print("-" * 80)
        
        # Executar cenários
        message_ids = []
        for i, scenario in enumerate(scenarios, 1):
            print(f"\n📋 Scenario {i}: {scenario['name']}")
            print(f"   Type: {scenario['type']}")
            print(f"   Spec: {scenario['spec']}")
            
            # Enviar request para producer service (simula REST API call)
            message_id = self.producer_service.receive_virtualization_request(
                scenario['type'], scenario['spec']
            )
            
            if message_id:
                message_ids.append(message_id)
                print(f"   ✅ Request accepted, message ID: {message_id}")
            else:
                print(f"   ❌ Request rejected")
            
            time.sleep(0.5)  # Intervalo entre requests
        
        # Aguardar processamento
        print(f"\n⏳ Waiting for message processing...")
        time.sleep(3)
        
        # Parar consumer
        self.consumer_service.stop_consuming()
        
        # Mostrar recursos criados
        self.show_virtual_resources()
        
        # Dashboard de métricas Prometheus
        self.monitoring.print_metrics_dashboard()
        
        # Resumo final
        print(f"\n✅ DEMO COMPLETED SUCCESSFULLY!")
        print(f"📊 {len(message_ids)} virtualization requests processed")
        print(f"🖥️  {len(self.consumer_service.virtual_resources)} virtual resources created")
        print(f"📈 All metrics collected by Prometheus simulation")
    
    def show_virtual_resources(self):
        """Mostra recursos virtuais criados"""
        print("\n🖥️  VIRTUAL RESOURCES CREATED:")
        print("-" * 60)
        
        if not self.consumer_service.virtual_resources:
            print("   No virtual resources created yet")
            return
        
        for resource_id, resource in self.consumer_service.virtual_resources.items():
            print(f"🔹 {resource['type'].upper()}: {resource_id}")
            print(f"   • Status: {resource['status']}")
            print(f"   • Created: {resource['createdAt']}")
            print(f"   • Spec: {resource['specification']}")
            print()

def main():
    demo = VirtualizationWorkflowDemo()
    demo.run_complete_demo()

if __name__ == "__main__":
    main()
