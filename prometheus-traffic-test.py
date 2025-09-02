#!/usr/bin/env python3
"""
KBNT Virtual Stock - Prometheus Metrics Traffic Test
Teste focado na coleta de métricas Prometheus durante tráfego intenso
"""

import json
import time
import uuid
import threading
import random
from datetime import datetime
from typing import Dict, List
import queue
import logging
from collections import defaultdict
import concurrent.futures

logging.basicConfig(level=logging.WARNING)  # Reduz verbosidade
logger = logging.getLogger(__name__)

class PrometheusMetricsCollector:
    """Coletor de métricas Prometheus em tempo real"""
    
    def __init__(self):
        self.metrics = defaultdict(lambda: defaultdict(float))
        self.histograms = defaultdict(list)
        self.start_time = time.time()
        self.lock = threading.Lock()
        
    def increment_counter(self, metric_name: str, labels: Dict[str, str] = None, value: float = 1.0):
        """Incrementa contador Prometheus"""
        with self.lock:
            key = self._build_key(labels)
            self.metrics[metric_name][key] += value
    
    def set_gauge(self, metric_name: str, value: float, labels: Dict[str, str] = None):
        """Define valor de gauge"""
        with self.lock:
            key = self._build_key(labels)
            self.metrics[metric_name][key] = value
    
    def observe_histogram(self, metric_name: str, value: float, labels: Dict[str, str] = None):
        """Adiciona observação ao histograma"""
        with self.lock:
            entry = {
                'value': value,
                'labels': labels or {},
                'timestamp': time.time()
            }
            self.histograms[metric_name].append(entry)
    
    def _build_key(self, labels: Dict[str, str] = None):
        """Constrói chave para labels"""
        if not labels:
            return 'default'
        return '|'.join([f"{k}={v}" for k, v in sorted(labels.items())])
    
    def export_prometheus_format(self) -> str:
        """Exporta métricas no formato Prometheus"""
        output = []
        timestamp = int(time.time() * 1000)
        
        # Counters e Gauges
        for metric_name, values in self.metrics.items():
            output.append(f"# TYPE {metric_name} gauge")
            for key, value in values.items():
                if key == 'default':
                    output.append(f"{metric_name} {value} {timestamp}")
                else:
                    labels = '{' + key.replace('|', ',').replace('=', '="') + '"}'
                    output.append(f"{metric_name}{labels} {value} {timestamp}")
        
        # Histogramas
        for metric_name, observations in self.histograms.items():
            if observations:
                values = [obs['value'] for obs in observations]
                output.append(f"# TYPE {metric_name} histogram")
                output.append(f"{metric_name}_count {len(values)} {timestamp}")
                output.append(f"{metric_name}_sum {sum(values)} {timestamp}")
                
                # Buckets
                buckets = [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1.0, 5.0, 10.0]
                for bucket in buckets:
                    count = sum(1 for v in values if v <= bucket)
                    output.append(f"{metric_name}_bucket{{le=\"{bucket}\"}} {count} {timestamp}")
        
        return '\n'.join(output)

class VirtualStockService:
    """Microserviço de Virtual Stock com métricas Prometheus"""
    
    def __init__(self, service_name: str, metrics_collector: PrometheusMetricsCollector):
        self.service_name = service_name
        self.metrics = metrics_collector
        self.amq_streams = AMQStreamsHighPerformance()
        
        # Virtual Stock Database
        self.virtual_stock = {
            "PROD-001": {"name": "Smartphone X Pro", "stock": 2000, "reserved": 0},
            "PROD-002": {"name": "Laptop Gaming", "stock": 1500, "reserved": 0},
            "PROD-003": {"name": "Tablet Professional", "stock": 1000, "reserved": 0},
            "PROD-004": {"name": "Smartwatch Elite", "stock": 2500, "reserved": 0},
            "PROD-005": {"name": "Headphones Premium", "stock": 3000, "reserved": 0},
        }
        
        self.reservations = {}
        self.lock = threading.RLock()
        
        # Metrics iniciais
        self._update_stock_gauges()
    
    def process_stock_request(self, operation_type: str, product_id: str, quantity: int, user_id: str) -> Dict:
        """Processa request de estoque com métricas Prometheus"""
        start_time = time.time()
        
        # Métrica: Request recebido
        self.metrics.increment_counter('kbnt_virtual_stock_requests_total', {
            'service': self.service_name,
            'operation': operation_type,
            'product': product_id
        })
        
        try:
            # DOMAIN LAYER: Processar lógica de negócio
            if operation_type == "RESERVE":
                result = self._reserve_virtual_stock(product_id, quantity, user_id)
            elif operation_type == "CONFIRM":
                result = self._confirm_virtual_stock(product_id, quantity, user_id)
            elif operation_type == "RELEASE":
                result = self._release_virtual_stock(product_id, quantity, user_id)
            else:
                result = {"success": False, "reason": "INVALID_OPERATION"}
            
            # APPLICATION LAYER: Preparar mensagem para AMQ Streams
            if result["success"]:
                message = self._prepare_amq_message(operation_type, product_id, quantity, user_id, result)
                
                # INFRASTRUCTURE LAYER: Publicar no AMQ Streams
                self._publish_to_amq_streams(message)
                
                # Métricas de sucesso
                self.metrics.increment_counter('kbnt_virtual_stock_operations_successful_total', {
                    'service': self.service_name,
                    'operation': operation_type
                })
            else:
                # Métricas de falha
                self.metrics.increment_counter('kbnt_virtual_stock_operations_failed_total', {
                    'service': self.service_name,
                    'operation': operation_type,
                    'reason': result.get('reason', 'unknown')
                })
            
            # Atualizar gauges de estoque
            self._update_stock_gauges()
            
            # Métrica de duração
            duration = time.time() - start_time
            self.metrics.observe_histogram('kbnt_virtual_stock_operation_duration_seconds', duration, {
                'service': self.service_name,
                'operation': operation_type
            })
            
            return result
            
        except Exception as e:
            self.metrics.increment_counter('kbnt_virtual_stock_operations_failed_total', {
                'service': self.service_name,
                'operation': operation_type,
                'reason': 'exception'
            })
            return {"success": False, "reason": f"EXCEPTION: {str(e)}"}
    
    def _reserve_virtual_stock(self, product_id: str, quantity: int, user_id: str) -> Dict:
        """Reserva estoque virtual"""
        with self.lock:
            if product_id not in self.virtual_stock:
                return {"success": False, "reason": "PRODUCT_NOT_FOUND"}
            
            product = self.virtual_stock[product_id]
            available = product["stock"] - product["reserved"]
            
            if available < quantity:
                return {
                    "success": False,
                    "reason": "INSUFFICIENT_STOCK", 
                    "available": available,
                    "requested": quantity
                }
            
            # Criar reserva
            reservation_id = f"RES-{uuid.uuid4().hex[:8]}"
            product["reserved"] += quantity
            
            self.reservations[reservation_id] = {
                "productId": product_id,
                "quantity": quantity,
                "userId": user_id,
                "status": "ACTIVE",
                "createdAt": datetime.now().isoformat()
            }
            
            return {
                "success": True,
                "reservationId": reservation_id,
                "remainingStock": available - quantity
            }
    
    def _confirm_virtual_stock(self, product_id: str, quantity: int, user_id: str) -> Dict:
        """Confirma estoque virtual (diminui estoque real)"""
        with self.lock:
            # Encontrar reserva ativa do usuário
            user_reservations = [r for r in self.reservations.values()
                               if r["userId"] == user_id and r["productId"] == product_id 
                               and r["status"] == "ACTIVE" and r["quantity"] == quantity]
            
            if not user_reservations:
                return {"success": False, "reason": "NO_MATCHING_RESERVATION"}
            
            reservation = user_reservations[0]
            product = self.virtual_stock[product_id]
            
            # Confirmar (diminuir estoque real)
            product["stock"] -= quantity
            product["reserved"] -= quantity
            
            # Atualizar reserva
            for res_id, res in self.reservations.items():
                if res == reservation:
                    res["status"] = "CONFIRMED"
                    break
            
            return {
                "success": True,
                "finalStock": product["stock"],
                "operation": "STOCK_CONFIRMED"
            }
    
    def _release_virtual_stock(self, product_id: str, quantity: int, user_id: str) -> Dict:
        """Libera reserva de estoque virtual"""
        with self.lock:
            # Encontrar reserva ativa do usuário
            user_reservations = [r for r in self.reservations.values()
                               if r["userId"] == user_id and r["productId"] == product_id 
                               and r["status"] == "ACTIVE" and r["quantity"] == quantity]
            
            if not user_reservations:
                return {"success": False, "reason": "NO_MATCHING_RESERVATION"}
            
            reservation = user_reservations[0]
            product = self.virtual_stock[product_id]
            
            # Liberar reserva
            product["reserved"] -= quantity
            
            # Atualizar reserva
            for res_id, res in self.reservations.items():
                if res == reservation:
                    res["status"] = "RELEASED"
                    break
            
            return {
                "success": True,
                "availableStock": product["stock"] - product["reserved"],
                "operation": "RESERVATION_RELEASED"
            }
    
    def _prepare_amq_message(self, operation_type: str, product_id: str, quantity: int, user_id: str, result: Dict) -> Dict:
        """Prepara mensagem para AMQ Streams"""
        return {
            "messageId": str(uuid.uuid4()),
            "timestamp": datetime.now().isoformat(),
            "service": self.service_name,
            "eventType": f"VirtualStock{operation_type.title()}Event",
            "domain": "virtual_stock",
            "hexagonal_layer": "application",
            "payload": {
                "productId": product_id,
                "quantity": quantity,
                "userId": user_id,
                "operation": operation_type,
                "result": result
            }
        }
    
    def _publish_to_amq_streams(self, message: Dict):
        """Publica no AMQ Streams"""
        self.amq_streams.produce('virtual-stock-events', {
            'key': message['messageId'],
            'value': message
        })
        
        # Métrica de mensagem enviada
        self.metrics.increment_counter('kbnt_amq_messages_sent_total', {
            'service': self.service_name,
            'topic': 'virtual-stock-events'
        })
    
    def _update_stock_gauges(self):
        """Atualiza gauges de estoque no Prometheus"""
        for product_id, product in self.virtual_stock.items():
            # Stock levels
            self.metrics.set_gauge('kbnt_virtual_stock_total', product["stock"], 
                                 {'product': product_id})
            self.metrics.set_gauge('kbnt_virtual_stock_reserved', product["reserved"],
                                 {'product': product_id})
            self.metrics.set_gauge('kbnt_virtual_stock_available', product["stock"] - product["reserved"],
                                 {'product': product_id})
            
            # Utilization percentage
            utilization = (product["reserved"] / product["stock"]) * 100 if product["stock"] > 0 else 0
            self.metrics.set_gauge('kbnt_virtual_stock_utilization_percent', utilization,
                                 {'product': product_id})
        
        # Total de reservas ativas
        active_reservations = sum(1 for r in self.reservations.values() if r["status"] == "ACTIVE")
        self.metrics.set_gauge('kbnt_virtual_reservations_active_total', active_reservations)

class AMQStreamsHighPerformance:
    """AMQ Streams simulador de alta performance"""
    
    def __init__(self):
        self.topics = {
            'virtual-stock-events': queue.Queue(maxsize=10000)
        }
        self.message_count = 0
        self.lock = threading.Lock()
    
    def produce(self, topic: str, message: dict):
        """Produção de alta performance"""
        with self.lock:
            if topic in self.topics and not self.topics[topic].full():
                self.topics[topic].put(message)
                self.message_count += 1
                return True
        return False

class VirtualStockTrafficGenerator:
    """Gerador de tráfego para virtual stock"""
    
    def __init__(self):
        self.metrics = PrometheusMetricsCollector()
        self.stock_service = VirtualStockService("virtual-stock-service", self.metrics)
        
    def generate_realistic_traffic(self, duration_seconds: int, operations_per_second: int):
        """Gera tráfego realístico por um período"""
        print(f"🚀 PROMETHEUS METRICS TRAFFIC TEST")
        print(f"="*80)
        print(f"⏰ Duration: {duration_seconds} seconds")
        print(f"📊 Target Rate: {operations_per_second} operations/second")
        print(f"🎯 Total Operations: {duration_seconds * operations_per_second}")
        print()
        
        start_time = time.time()
        total_operations = 0
        
        print("⚡ Starting high-frequency virtual stock operations...")
        print("📊 Collecting Prometheus metrics in real-time...")
        print()
        
        # Loop principal de geração de tráfego
        while time.time() - start_time < duration_seconds:
            second_start = time.time()
            operations_this_second = 0
            
            # Executar operações para este segundo
            while operations_this_second < operations_per_second and (time.time() - second_start) < 1.0:
                # Gerar operação aleatória
                operation_type = random.choices(
                    ["RESERVE", "CONFIRM", "RELEASE"],
                    weights=[70, 20, 10]  # Mais reservas que confirmações
                )[0]
                
                product_id = random.choice(["PROD-001", "PROD-002", "PROD-003", "PROD-004", "PROD-005"])
                quantity = random.randint(1, 5)
                user_id = f"USER-{random.randint(1000, 9999)}"
                
                # Processar operação
                result = self.stock_service.process_stock_request(operation_type, product_id, quantity, user_id)
                
                operations_this_second += 1
                total_operations += 1
                
                # Pequeno delay para controlar rate
                time.sleep(0.001)
            
            # Mostrar progresso a cada 5 segundos
            elapsed = time.time() - start_time
            if int(elapsed) % 5 == 0 and int(elapsed) > 0:
                current_rate = total_operations / elapsed
                print(f"   ⏱️  {elapsed:.0f}s elapsed | {total_operations} ops | {current_rate:.1f} ops/s")
        
        print(f"\n✅ Traffic generation completed!")
        print(f"📊 Total operations executed: {total_operations}")
        
        # Aguardar processamento final
        time.sleep(2)
        
        # Exportar métricas Prometheus
        self._export_prometheus_metrics()
        
        # Mostrar resumo final
        self._show_final_summary(total_operations, time.time() - start_time)
    
    def _export_prometheus_metrics(self):
        """Exporta métricas no formato Prometheus"""
        print(f"\n📊 PROMETHEUS METRICS EXPORT (/actuator/prometheus):")
        print("="*80)
        
        prometheus_output = self.metrics.export_prometheus_format()
        
        # Mostrar algumas métricas principais
        lines = prometheus_output.split('\n')
        key_metrics = [
            'kbnt_virtual_stock_requests_total',
            'kbnt_virtual_stock_operations_successful_total', 
            'kbnt_virtual_stock_available',
            'kbnt_virtual_stock_utilization_percent',
            'kbnt_virtual_reservations_active_total'
        ]
        
        for metric in key_metrics:
            matching_lines = [line for line in lines if line.startswith(metric)]
            if matching_lines:
                print(f"\n# {metric}")
                for line in matching_lines[:5]:  # Mostrar até 5 entries
                    print(f"  {line}")
        
        # Salvar arquivo completo
        with open('prometheus-metrics-export.txt', 'w') as f:
            f.write(prometheus_output)
        print(f"\n💾 Full metrics exported to: prometheus-metrics-export.txt")
    
    def _show_final_summary(self, total_operations: int, duration: float):
        """Mostra resumo final do teste"""
        print(f"\n" + "🎉 " + "="*70)
        print("🏆 VIRTUAL STOCK TRAFFIC TEST COMPLETED")
        print("🎉 " + "="*70)
        
        # Performance summary
        print(f"\n⚡ PERFORMANCE ACHIEVED:")
        print(f"   • Operations Executed: {total_operations}")
        print(f"   • Duration: {duration:.2f} seconds")
        print(f"   • Average Rate: {total_operations/duration:.2f} ops/second")
        
        # Stock summary
        print(f"\n📦 VIRTUAL STOCK FINAL STATE:")
        for product_id, product in self.stock_service.virtual_stock.items():
            available = product["stock"] - product["reserved"]
            utilization = (product["reserved"] / (product["stock"] + product["reserved"])) * 100
            status_icon = "🔴" if utilization > 70 else "🟡" if utilization > 40 else "🟢"
            
            print(f"   {status_icon} {product['name']}: {available} available ({utilization:.1f}% utilized)")
        
        # AMQ Streams summary
        print(f"\n🔄 AMQ STREAMS PERFORMANCE:")
        print(f"   • Messages Sent: {self.stock_service.amq_streams.message_count}")
        print(f"   • Message Rate: {self.stock_service.amq_streams.message_count/duration:.2f} msg/s")
        
        # Prometheus metrics summary
        total_metrics = sum(len(values) for values in self.metrics.metrics.values())
        total_observations = sum(len(obs) for obs in self.metrics.histograms.values())
        
        print(f"\n📊 PROMETHEUS METRICS COLLECTED:")
        print(f"   • Total Metric Points: {total_metrics}")
        print(f"   • Histogram Observations: {total_observations}")
        print(f"   • Metrics Collection Rate: {(total_metrics + total_observations)/duration:.2f} metrics/s")

def main():
    generator = VirtualStockTrafficGenerator()
    
    print("🎯 KBNT Virtual Stock - Prometheus Metrics Traffic Test")
    print("🔄 Testing message virtualization workflow under load")
    print("📊 Focus: Real-time Prometheus metrics collection")
    print()
    
    # Teste de 30 segundos com 50 operações por segundo
    generator.generate_realistic_traffic(duration_seconds=30, operations_per_second=50)

if __name__ == "__main__":
    main()
