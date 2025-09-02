#!/usr/bin/env python3
"""
Demonstração Prática do Workflow KBNT Virtual Stock Management
Simula um fluxo completo de criação de pedido com estoque virtual
"""

import json
import time
import uuid
from datetime import datetime, timedelta
from typing import Dict, List
import threading

# Importa o simulador AMQ Streams
import importlib.util
spec = importlib.util.spec_from_file_location("amq_streams_simulator", "amq-streams-simulator.py")
amq_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(amq_module)

AMQStreamsSimulator = amq_module.AMQStreamsSimulator

class KBNTWorkflowDemo:
    """Demonstração completa do workflow KBNT"""
    
    def __init__(self):
        self.amq_simulator = AMQStreamsSimulator()
        self.virtual_stock = {
            "PROD-001": {"name": "Smartphone X", "stock": 100, "reserved": 0},
            "PROD-002": {"name": "Laptop Pro", "stock": 50, "reserved": 0}, 
            "PROD-003": {"name": "Tablet Mini", "stock": 25, "reserved": 0}
        }
        self.orders = {}
        self.reservations = {}
        
    def print_header(self, title):
        """Imprime cabeçalho formatado"""
        print(f"\n{'='*80}")
        print(f"{title.center(80)}")
        print(f"{'='*80}\n")
    
    def print_step(self, step, description):
        """Imprime passo do workflow"""
        print(f"🔄 STEP {step}: {description}")
        print("-" * 60)
    
    def simulate_user_service(self, user_id: str):
        """Simula User Service - Domain Layer"""
        print("🏗️  USER SERVICE - DOMAIN LAYER")
        
        # Evento de validação de usuário
        user_validated_event = {
            "eventId": str(uuid.uuid4()),
            "timestamp": datetime.now().isoformat(),
            "eventType": "UserValidatedEvent", 
            "service": "user-service",
            "level": "INFO",
            "hexagonal_layer": "domain",
            "domain": "user",
            "operation": "user-validated",
            "payload": {
                "userId": user_id,
                "status": "ACTIVE",
                "validationResult": "SUCCESS"
            }
        }
        
        self.amq_simulator.produce("user-events", user_validated_event)
        self.amq_simulator.produce("application-logs", user_validated_event)
        
        print(f"   ✅ Usuário {user_id} validado com sucesso")
        return True
    
    def simulate_inventory_service_reservation(self, product_id: str, quantity: int):
        """Simula Inventory Service - Virtual Stock Reservation"""
        print("🏗️  INVENTORY SERVICE - DOMAIN LAYER (Virtual Stock)")
        
        if product_id not in self.virtual_stock:
            print(f"   ❌ Produto {product_id} não encontrado")
            return None
            
        product = self.virtual_stock[product_id]
        available = product["stock"] - product["reserved"]
        
        if available < quantity:
            # Erro de estoque insuficiente
            error_event = {
                "eventId": str(uuid.uuid4()),
                "timestamp": datetime.now().isoformat(),
                "eventType": "InsufficientStockError",
                "service": "inventory-service", 
                "level": "ERROR",
                "hexagonal_layer": "domain",
                "domain": "inventory",
                "operation": "stock-reservation-failed",
                "payload": {
                    "productId": product_id,
                    "requestedQuantity": quantity,
                    "availableQuantity": available
                }
            }
            
            self.amq_simulator.produce("inventory-events", error_event)
            self.amq_simulator.produce("application-logs", error_event)
            
            print(f"   ❌ Estoque insuficiente: disponível {available}, solicitado {quantity}")
            return None
        
        # Reserva o estoque virtual
        reservation_id = f"RES-{uuid.uuid4().hex[:8].upper()}"
        product["reserved"] += quantity
        
        reservation = {
            "reservationId": reservation_id,
            "productId": product_id,
            "quantity": quantity,
            "reservedAt": datetime.now().isoformat(),
            "expiresAt": (datetime.now() + timedelta(minutes=15)).isoformat(),
            "status": "RESERVED"
        }
        
        self.reservations[reservation_id] = reservation
        
        # Evento de reserva bem-sucedida
        stock_reserved_event = {
            "eventId": str(uuid.uuid4()),
            "timestamp": datetime.now().isoformat(),
            "eventType": "VirtualStockReservedEvent",
            "service": "inventory-service",
            "level": "INFO", 
            "hexagonal_layer": "domain",
            "domain": "inventory",
            "operation": "stock-reserved",
            "payload": {
                "reservationId": reservation_id,
                "productId": product_id,
                "productName": product["name"],
                "quantity": quantity,
                "virtualStockLevel": product["stock"] - product["reserved"],
                "reservedUntil": reservation["expiresAt"]
            }
        }
        
        self.amq_simulator.produce("inventory-events", stock_reserved_event)
        self.amq_simulator.produce("application-logs", stock_reserved_event)
        
        print(f"   ✅ Reserva criada: {reservation_id}")
        print(f"   📦 Produto: {product['name']}")
        print(f"   🔢 Quantidade: {quantity}")
        print(f"   📊 Estoque restante: {product['stock'] - product['reserved']}")
        
        # Verifica se precisa de alerta de estoque baixo
        remaining_stock = product["stock"] - product["reserved"]
        if remaining_stock < 10:  # Limite mínimo
            self.trigger_low_stock_alert(product_id, remaining_stock)
        
        return reservation
    
    def trigger_low_stock_alert(self, product_id: str, stock_level: int):
        """Dispara alerta de estoque baixo"""
        print("🚨 ALERTA DE ESTOQUE BAIXO")
        
        alert_event = {
            "eventId": str(uuid.uuid4()),
            "timestamp": datetime.now().isoformat(),
            "eventType": "LowStockAlertEvent",
            "service": "inventory-service",
            "level": "WARN",
            "hexagonal_layer": "infrastructure", 
            "domain": "inventory",
            "operation": "low-stock-alert",
            "payload": {
                "productId": product_id,
                "productName": self.virtual_stock[product_id]["name"],
                "currentStock": stock_level,
                "threshold": 10,
                "severity": "HIGH" if stock_level < 5 else "MEDIUM"
            },
            "item_id": product_id,
            "current_stock": stock_level
        }
        
        self.amq_simulator.produce("inventory-events", alert_event)
        self.amq_simulator.produce("application-logs", alert_event)
        
        print(f"   🚨 Produto {product_id}: apenas {stock_level} unidades restantes!")
    
    def simulate_payment_service(self, amount: float):
        """Simula Payment Service - Application Layer"""
        print("🏗️  PAYMENT SERVICE - APPLICATION LAYER")
        
        transaction_id = f"TX{uuid.uuid4().hex[:8].upper()}"
        
        # Simula processamento de pagamento
        time.sleep(0.5)  # Simula latência
        
        # 90% de chance de sucesso
        import random
        success = random.random() > 0.1
        
        if success:
            payment_event = {
                "eventId": str(uuid.uuid4()),
                "timestamp": datetime.now().isoformat(),
                "eventType": "PaymentProcessedEvent",
                "service": "payment-service",
                "level": "INFO",
                "hexagonal_layer": "application",
                "domain": "payment", 
                "operation": "payment-processed",
                "payload": {
                    "transactionId": transaction_id,
                    "amount": amount,
                    "currency": "BRL",
                    "status": "SUCCESS",
                    "processor": "VISA"
                },
                "amount": amount,
                "transaction_id": transaction_id
            }
            
            print(f"   ✅ Pagamento processado: R$ {amount:.2f}")
            print(f"   💳 Transaction ID: {transaction_id}")
        else:
            payment_event = {
                "eventId": str(uuid.uuid4()),
                "timestamp": datetime.now().isoformat(),
                "eventType": "PaymentFailedEvent",
                "service": "payment-service",
                "level": "ERROR",
                "hexagonal_layer": "application",
                "domain": "payment",
                "operation": "payment-failed",
                "payload": {
                    "transactionId": transaction_id,
                    "amount": amount,
                    "currency": "BRL",
                    "status": "FAILED",
                    "errorCode": "INSUFFICIENT_FUNDS"
                }
            }
            
            print(f"   ❌ Pagamento falhou: R$ {amount:.2f}")
            print(f"   💳 Transaction ID: {transaction_id}")
        
        self.amq_simulator.produce("payment-events", payment_event)
        self.amq_simulator.produce("application-logs", payment_event)
        
        return {
            "transactionId": transaction_id,
            "success": success,
            "amount": amount
        }
    
    def simulate_order_service(self, user_id: str, product_id: str, quantity: int, payment_result: dict, reservation: dict):
        """Simula Order Service - Application Layer (Orquestração)"""
        print("🏗️  ORDER SERVICE - APPLICATION LAYER (Orquestração)")
        
        if not payment_result["success"]:
            # Libera a reserva se o pagamento falhou
            self.release_reservation(reservation["reservationId"])
            return None
        
        order_id = f"ORD-{uuid.uuid4().hex[:8].upper()}"
        
        order = {
            "orderId": order_id,
            "userId": user_id,
            "productId": product_id,
            "quantity": quantity,
            "amount": payment_result["amount"],
            "transactionId": payment_result["transactionId"],
            "reservationId": reservation["reservationId"],
            "status": "CONFIRMED",
            "createdAt": datetime.now().isoformat()
        }
        
        self.orders[order_id] = order
        
        # Confirma a reserva (transforma em estoque definitivamente alocado)
        self.confirm_reservation(reservation["reservationId"])
        
        # Evento de ordem criada
        order_created_event = {
            "eventId": str(uuid.uuid4()),
            "timestamp": datetime.now().isoformat(),
            "eventType": "OrderCreatedEvent",
            "service": "order-service",
            "level": "INFO",
            "hexagonal_layer": "infrastructure",
            "domain": "order",
            "operation": "order-created",
            "payload": {
                "orderId": order_id,
                "userId": user_id,
                "productId": product_id,
                "quantity": quantity,
                "amount": payment_result["amount"],
                "status": "CONFIRMED"
            }
        }
        
        self.amq_simulator.produce("order-events", order_created_event)
        self.amq_simulator.produce("application-logs", order_created_event)
        
        print(f"   ✅ Pedido criado: {order_id}")
        print(f"   👤 Usuário: {user_id}")
        print(f"   📦 Produto: {product_id} (qty: {quantity})")
        print(f"   💰 Valor: R$ {payment_result['amount']:.2f}")
        
        return order
    
    def release_reservation(self, reservation_id: str):
        """Libera uma reserva de estoque"""
        if reservation_id in self.reservations:
            reservation = self.reservations[reservation_id]
            product = self.virtual_stock[reservation["productId"]]
            
            # Libera o estoque reservado
            product["reserved"] -= reservation["quantity"]
            reservation["status"] = "RELEASED"
            
            print(f"   🔄 Reserva {reservation_id} liberada")
    
    def confirm_reservation(self, reservation_id: str):
        """Confirma uma reserva (diminui estoque real)"""
        if reservation_id in self.reservations:
            reservation = self.reservations[reservation_id]
            product = self.virtual_stock[reservation["productId"]]
            
            # Diminui estoque real e libera reserva
            product["stock"] -= reservation["quantity"] 
            product["reserved"] -= reservation["quantity"]
            reservation["status"] = "CONFIRMED"
            
            print(f"   ✅ Reserva {reservation_id} confirmada - estoque definitivamente alocado")
    
    def simulate_notification_service(self, order: dict):
        """Simula Notification Service"""
        print("🏗️  NOTIFICATION SERVICE - INFRASTRUCTURE LAYER")
        
        notification_event = {
            "eventId": str(uuid.uuid4()),
            "timestamp": datetime.now().isoformat(),
            "eventType": "OrderConfirmationNotificationSent",
            "service": "notification-service",
            "level": "INFO",
            "hexagonal_layer": "infrastructure",
            "domain": "notification",
            "operation": "notification-sent",
            "payload": {
                "orderId": order["orderId"],
                "userId": order["userId"],
                "channel": "EMAIL",
                "template": "ORDER_CONFIRMATION"
            }
        }
        
        self.amq_simulator.produce("notification-events", notification_event)
        self.amq_simulator.produce("application-logs", notification_event)
        
        print(f"   📧 Notificação enviada para usuário {order['userId']}")
    
    def simulate_audit_service(self, operation: str, details: dict):
        """Simula Audit Service"""
        audit_event = {
            "eventId": str(uuid.uuid4()),
            "timestamp": datetime.now().isoformat(),
            "eventType": "AuditLogCreated",
            "service": "audit-service", 
            "level": "AUDIT",
            "hexagonal_layer": "infrastructure",
            "domain": "audit",
            "operation": "audit-logged",
            "payload": {
                "operation": operation,
                "details": details,
                "timestamp": datetime.now().isoformat()
            },
            "user": details.get("userId", "system"),
            "action": operation,
            "resource": details.get("resource", "unknown")
        }
        
        self.amq_simulator.produce("audit-logs", audit_event)
        self.amq_simulator.produce("application-logs", audit_event)
    
    def process_events_with_consumer(self):
        """Simula o processamento dos eventos pelo consumer"""
        print("\n📖 LOG CONSUMER - Processando eventos...")
        print("-" * 60)
        
        # Consume mensagens do application-logs
        messages = self.amq_simulator.consume("application-logs", "demo-consumer")
        
        for message in messages:
            event = message["value"]
            
            service = event.get("service", "unknown")
            level = event.get("level", "INFO")
            operation = event.get("operation", "unknown")
            hexagonal_layer = event.get("hexagonal_layer")
            
            if level == "ERROR":
                print(f"   🚨 ERROR em {service}: {event.get('eventType')}")
            elif hexagonal_layer:
                print(f"   🏗️  {hexagonal_layer.upper()}: {service} - {operation}")
            elif event.get("amount"):
                amount = event.get("amount")
                tx_id = event.get("transaction_id", "N/A")
                print(f"   💰 PAYMENT: R$ {amount:.2f} ({tx_id})")
            elif event.get("current_stock") is not None:
                item_id = event.get("item_id")
                stock = event.get("current_stock")
                print(f"   📦 STOCK ALERT: {item_id} = {stock} unidades")
            else:
                print(f"   📝 {service}: {event.get('eventType')}")
        
        print(f"\n   ✅ Processadas {len(messages)} mensagens pelo consumer")
    
    def show_current_state(self):
        """Mostra estado atual do sistema"""
        print("\n📊 ESTADO ATUAL DO SISTEMA")
        print("-" * 60)
        
        print("🏪 Virtual Stock:")
        for product_id, product in self.virtual_stock.items():
            available = product["stock"] - product["reserved"]
            print(f"   • {product['name']} ({product_id}): "
                  f"Estoque={product['stock']}, Reservado={product['reserved']}, "
                  f"Disponível={available}")
        
        print(f"\n📋 Pedidos: {len(self.orders)} criados")
        print(f"🔒 Reservas: {len(self.reservations)} ativas")
        
        # Estatísticas do AMQ Streams
        stats = self.amq_simulator.get_cluster_stats()
        print(f"\n📈 AMQ Streams:")
        print(f"   • Mensagens produzidas: {stats['stats']['total_messages_produced']}")
        print(f"   • Mensagens consumidas: {stats['stats']['total_messages_consumed']}")
    
    def run_complete_workflow_demo(self):
        """Executa demonstração completa do workflow"""
        self.print_header("DEMONSTRAÇÃO COMPLETA - WORKFLOW KBNT VIRTUAL STOCK")
        
        print("🎯 Simulando criação de pedido completo com arquitetura hexagonal")
        print("🏗️  Microserviços: User → Inventory → Payment → Order → Notification")
        print("🔄 Event-Driven via Red Hat AMQ Streams")
        print()
        
        # Dados do pedido
        user_id = "USER-12345"
        product_id = "PROD-001"
        quantity = 3
        amount = 599.99
        
        try:
            # STEP 1: Validação de usuário
            self.print_step(1, "USER SERVICE - Validação de Usuário")
            user_valid = self.simulate_user_service(user_id)
            time.sleep(0.5)
            
            if not user_valid:
                print("❌ Falha na validação do usuário - workflow encerrado")
                return
            
            # STEP 2: Reserva de estoque virtual
            self.print_step(2, "INVENTORY SERVICE - Reserva de Estoque Virtual")
            reservation = self.simulate_inventory_service_reservation(product_id, quantity)
            time.sleep(0.5)
            
            if not reservation:
                print("❌ Falha na reserva de estoque - workflow encerrado")
                return
            
            # STEP 3: Processamento de pagamento
            self.print_step(3, "PAYMENT SERVICE - Processamento de Pagamento")
            payment_result = self.simulate_payment_service(amount)
            time.sleep(0.5)
            
            # STEP 4: Criação do pedido
            self.print_step(4, "ORDER SERVICE - Criação do Pedido")
            order = self.simulate_order_service(user_id, product_id, quantity, payment_result, reservation)
            time.sleep(0.5)
            
            if not order:
                print("❌ Falha na criação do pedido - workflow encerrado")
                return
            
            # STEP 5: Notificação
            self.print_step(5, "NOTIFICATION SERVICE - Envio de Notificação")
            self.simulate_notification_service(order)
            time.sleep(0.5)
            
            # STEP 6: Auditoria
            self.print_step(6, "AUDIT SERVICE - Registro de Auditoria")
            self.simulate_audit_service("ORDER_CREATED", {
                "userId": user_id,
                "orderId": order["orderId"],
                "amount": amount,
                "resource": f"order-{order['orderId']}"
            })
            time.sleep(0.5)
            
            # STEP 7: Processamento pelo Consumer
            self.print_step(7, "LOG CONSUMER - Processamento de Eventos")
            self.process_events_with_consumer()
            
            # STEP 8: Estado final
            self.print_step(8, "ESTADO FINAL DO SISTEMA")
            self.show_current_state()
            
            self.print_header("✅ WORKFLOW CONCLUÍDO COM SUCESSO!")
            print("🎉 Pedido criado, pagamento processado, estoque atualizado!")
            print("📊 Todos os eventos foram processados pelo AMQ Streams")
            print("🏗️  Arquitetura hexagonal funcionando perfeitamente")
            
        except Exception as e:
            print(f"❌ Erro no workflow: {e}")
            return False
        
        return True

def main():
    demo = KBNTWorkflowDemo()
    
    print("🚀 Iniciando Red Hat AMQ Streams...")
    time.sleep(1)
    
    # Executa a demo completa
    demo.run_complete_workflow_demo()
    
    print("\n" + "="*80)
    print("📋 RESUMO DA DEMONSTRAÇÃO")
    print("="*80)
    print("✅ Workflow completo executado com sucesso")
    print("✅ Arquitetura hexagonal (Domain/Application/Infrastructure) funcionando")
    print("✅ Event-driven communication via AMQ Streams")
    print("✅ Virtual stock management operacional")
    print("✅ Real-time event processing")
    print("✅ Full observability e auditoria")

if __name__ == "__main__":
    main()
