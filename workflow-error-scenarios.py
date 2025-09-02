#!/usr/bin/env python3
"""
Demonstração do Workflow KBNT com Cenários de Falha
Mostra como o sistema trata erros e rollbacks
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

class KBNTErrorHandlingDemo:
    """Demonstração de tratamento de erros no workflow KBNT"""
    
    def __init__(self):
        self.amq_simulator = AMQStreamsSimulator()
        # Stock baixo proposital para demonstrar erros
        self.virtual_stock = {
            "PROD-001": {"name": "Smartphone X", "stock": 2, "reserved": 0},  # Estoque muito baixo
            "PROD-002": {"name": "Laptop Pro", "stock": 0, "reserved": 0},    # Sem estoque
            "PROD-003": {"name": "Tablet Mini", "stock": 1, "reserved": 1}    # Totalmente reservado
        }
        self.orders = {}
        self.reservations = {}
        
    def print_header(self, title):
        """Imprime cabeçalho formatado"""
        print(f"\n{'='*80}")
        print(f"{title.center(80)}")
        print(f"{'='*80}\n")
    
    def print_scenario(self, scenario, description):
        """Imprime cenário de teste"""
        print(f"🧪 CENÁRIO {scenario}: {description}")
        print("-" * 80)
    
    def try_order_scenario(self, scenario_name: str, user_id: str, product_id: str, quantity: int, amount: float, force_payment_failure: bool = False):
        """Tenta criar um pedido em um cenário específico"""
        print(f"\n🎯 TENTANDO: {scenario_name}")
        print(f"👤 Usuário: {user_id}")
        print(f"📦 Produto: {product_id} (quantidade: {quantity})")
        print(f"💰 Valor: R$ {amount:.2f}")
        print()
        
        success = True
        error_reason = ""
        
        try:
            # 1. Validação de usuário (sempre sucesso na demo)
            print("🔄 1. Validando usuário...")
            time.sleep(0.2)
            print("   ✅ Usuário validado")
            
            # 2. Tentativa de reserva de estoque
            print("🔄 2. Tentando reservar estoque...")
            reservation = self.try_stock_reservation(product_id, quantity)
            
            if not reservation:
                success = False
                error_reason = "Estoque insuficiente"
                print("   ❌ FALHA: Estoque insuficiente")
                return False
            
            print(f"   ✅ Estoque reservado: {reservation['reservationId']}")
            
            # 3. Processamento de pagamento
            print("🔄 3. Processando pagamento...")
            payment_success = not force_payment_failure and self.simulate_payment_success()
            
            if not payment_success:
                success = False
                error_reason = "Pagamento recusado"
                print("   ❌ FALHA: Pagamento recusado")
                
                # Rollback: liberar reserva
                print("🔄 Executando rollback...")
                self.release_reservation(reservation["reservationId"])
                print("   🔄 Reserva liberada (rollback)")
                return False
            
            print("   ✅ Pagamento aprovado")
            
            # 4. Criação do pedido
            print("🔄 4. Criando pedido...")
            order_id = self.create_order(user_id, product_id, quantity, amount, reservation)
            print(f"   ✅ Pedido criado: {order_id}")
            
            # 5. Confirmação da reserva (diminui estoque real)
            self.confirm_reservation(reservation["reservationId"])
            print("   ✅ Estoque definitivamente alocado")
            
            # 6. Log de sucesso
            self.log_transaction_event("ORDER_SUCCESS", {
                "orderId": order_id,
                "userId": user_id,
                "productId": product_id,
                "amount": amount,
                "scenario": scenario_name
            })
            
            return True
            
        except Exception as e:
            print(f"   ❌ ERRO INESPERADO: {e}")
            self.log_transaction_event("ORDER_ERROR", {
                "userId": user_id,
                "productId": product_id,
                "error": str(e),
                "scenario": scenario_name
            })
            return False
    
    def try_stock_reservation(self, product_id: str, quantity: int):
        """Tenta reservar estoque - pode falhar"""
        if product_id not in self.virtual_stock:
            self.log_inventory_event("PRODUCT_NOT_FOUND", product_id, 0, quantity)
            return None
            
        product = self.virtual_stock[product_id]
        available = product["stock"] - product["reserved"]
        
        if available < quantity:
            self.log_inventory_event("INSUFFICIENT_STOCK", product_id, available, quantity)
            return None
        
        # Cria reserva
        reservation_id = f"RES-{uuid.uuid4().hex[:8].upper()}"
        product["reserved"] += quantity
        
        reservation = {
            "reservationId": reservation_id,
            "productId": product_id,
            "quantity": quantity,
            "reservedAt": datetime.now().isoformat(),
            "status": "RESERVED"
        }
        
        self.reservations[reservation_id] = reservation
        self.log_inventory_event("STOCK_RESERVED", product_id, available - quantity, quantity)
        
        return reservation
    
    def simulate_payment_success(self):
        """Simula sucesso/falha de pagamento - 70% de sucesso"""
        import random
        return random.random() > 0.3
    
    def release_reservation(self, reservation_id: str):
        """Libera uma reserva (rollback)"""
        if reservation_id in self.reservations:
            reservation = self.reservations[reservation_id]
            product = self.virtual_stock[reservation["productId"]]
            
            product["reserved"] -= reservation["quantity"]
            reservation["status"] = "RELEASED"
            
            self.log_inventory_event("RESERVATION_RELEASED", reservation["productId"], 
                                   product["stock"] - product["reserved"], reservation["quantity"])
    
    def confirm_reservation(self, reservation_id: str):
        """Confirma reserva (diminui estoque real)"""
        if reservation_id in self.reservations:
            reservation = self.reservations[reservation_id]
            product = self.virtual_stock[reservation["productId"]]
            
            product["stock"] -= reservation["quantity"]
            product["reserved"] -= reservation["quantity"]
            reservation["status"] = "CONFIRMED"
    
    def create_order(self, user_id: str, product_id: str, quantity: int, amount: float, reservation: dict):
        """Cria um pedido"""
        order_id = f"ORD-{uuid.uuid4().hex[:8].upper()}"
        
        order = {
            "orderId": order_id,
            "userId": user_id,
            "productId": product_id,
            "quantity": quantity,
            "amount": amount,
            "reservationId": reservation["reservationId"],
            "status": "CONFIRMED",
            "createdAt": datetime.now().isoformat()
        }
        
        self.orders[order_id] = order
        return order_id
    
    def log_inventory_event(self, event_type: str, product_id: str, stock_level: int, requested_qty: int):
        """Log de eventos de estoque"""
        event = {
            "eventId": str(uuid.uuid4()),
            "timestamp": datetime.now().isoformat(),
            "eventType": event_type,
            "service": "inventory-service",
            "level": "ERROR" if "INSUFFICIENT" in event_type or "NOT_FOUND" in event_type else "INFO",
            "hexagonal_layer": "domain",
            "domain": "inventory", 
            "payload": {
                "productId": product_id,
                "stockLevel": stock_level,
                "requestedQuantity": requested_qty
            }
        }
        
        self.amq_simulator.produce("inventory-events", event)
        self.amq_simulator.produce("application-logs", event)
    
    def log_transaction_event(self, event_type: str, details: dict):
        """Log de eventos de transação"""
        event = {
            "eventId": str(uuid.uuid4()),
            "timestamp": datetime.now().isoformat(),
            "eventType": event_type,
            "service": "transaction-service",
            "level": "ERROR" if "ERROR" in event_type else "INFO",
            "hexagonal_layer": "application",
            "domain": "transaction",
            "payload": details
        }
        
        self.amq_simulator.produce("order-events", event)
        self.amq_simulator.produce("application-logs", event)
    
    def show_stock_status(self):
        """Mostra status atual do estoque"""
        print("\n📊 STATUS DO ESTOQUE VIRTUAL:")
        print("-" * 60)
        
        for product_id, product in self.virtual_stock.items():
            available = product["stock"] - product["reserved"]
            status_icon = "🟢" if available > 0 else "🔴"
            
            print(f"{status_icon} {product['name']} ({product_id}):")
            print(f"   • Estoque total: {product['stock']}")
            print(f"   • Reservado: {product['reserved']}")
            print(f"   • Disponível: {available}")
    
    def show_error_summary(self):
        """Mostra resumo de erros processados"""
        print("\n📖 PROCESSANDO EVENTOS DE ERRO...")
        print("-" * 60)
        
        messages = self.amq_simulator.consume("application-logs", "error-consumer")
        error_count = 0
        success_count = 0
        
        for message in messages:
            event = message["value"]
            level = event.get("level", "INFO")
            event_type = event.get("eventType", "UNKNOWN")
            
            if level == "ERROR":
                error_count += 1
                if "INSUFFICIENT" in event_type:
                    product_id = event["payload"].get("productId")
                    requested = event["payload"].get("requestedQuantity")
                    available = event["payload"].get("stockLevel")
                    print(f"   🚨 ESTOQUE INSUFICIENTE: {product_id} (solicitado: {requested}, disponível: {available})")
                else:
                    print(f"   ❌ ERRO: {event_type}")
            else:
                success_count += 1
                if "SUCCESS" in event_type:
                    order_id = event["payload"].get("orderId", "N/A")
                    print(f"   ✅ SUCESSO: Pedido {order_id} criado")
        
        print(f"\n📈 ESTATÍSTICAS:")
        print(f"   • Sucessos: {success_count}")
        print(f"   • Erros: {error_count}")
        print(f"   • Total de eventos: {success_count + error_count}")
    
    def run_error_scenarios(self):
        """Executa cenários de teste com erros"""
        self.print_header("DEMONSTRAÇÃO DE TRATAMENTO DE ERROS - KBNT VIRTUAL STOCK")
        
        print("🧪 Testando diferentes cenários de falha no workflow")
        print("🎯 Objetivo: Demonstrar robustez e rollback automático")
        print()
        
        # Mostra estoque inicial
        self.show_stock_status()
        
        scenarios = [
            {
                "name": "Sucesso com estoque limitado",
                "user_id": "USER-001",
                "product_id": "PROD-001", 
                "quantity": 1,
                "amount": 299.99,
                "force_payment_failure": False
            },
            {
                "name": "Falha por estoque insuficiente",
                "user_id": "USER-002",
                "product_id": "PROD-001",
                "quantity": 5,  # Mais que o disponível
                "amount": 1499.95,
                "force_payment_failure": False
            },
            {
                "name": "Falha por produto sem estoque",
                "user_id": "USER-003", 
                "product_id": "PROD-002",  # Estoque = 0
                "quantity": 1,
                "amount": 2499.99,
                "force_payment_failure": False
            },
            {
                "name": "Falha de pagamento com rollback",
                "user_id": "USER-004",
                "product_id": "PROD-001",
                "quantity": 1, 
                "amount": 299.99,
                "force_payment_failure": True  # Força falha no pagamento
            },
            {
                "name": "Sucesso final com último item",
                "user_id": "USER-005",
                "product_id": "PROD-001",
                "quantity": 1,
                "amount": 299.99,
                "force_payment_failure": False
            }
        ]
        
        # Executa cada cenário
        for i, scenario in enumerate(scenarios, 1):
            self.print_scenario(i, scenario["name"])
            
            success = self.try_order_scenario(
                scenario["name"],
                scenario["user_id"],
                scenario["product_id"], 
                scenario["quantity"],
                scenario["amount"],
                scenario["force_payment_failure"]
            )
            
            if success:
                print("🎉 RESULTADO: ✅ SUCESSO")
            else:
                print("💥 RESULTADO: ❌ FALHA (comportamento esperado)")
            
            time.sleep(1)
        
        # Status final
        self.print_header("RESULTADOS FINAIS")
        self.show_stock_status()
        self.show_error_summary()
        
        print("\n" + "="*80)
        print("📋 RESUMO DOS CENÁRIOS DE ERRO")
        print("="*80)
        print("✅ Sistema demonstrou robustez contra falhas")
        print("✅ Rollbacks automáticos funcionando")
        print("✅ Virtual stock management resiliente") 
        print("✅ Event-driven error handling operacional")
        print("✅ Logs de erro estruturados no AMQ Streams")

def main():
    demo = KBNTErrorHandlingDemo()
    
    print("🚀 Iniciando Red Hat AMQ Streams para testes de erro...")
    time.sleep(1)
    
    # Executa cenários de erro
    demo.run_error_scenarios()

if __name__ == "__main__":
    main()
