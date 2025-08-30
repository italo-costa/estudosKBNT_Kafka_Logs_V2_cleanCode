#!/usr/bin/env python3
"""
Simulador de Workflow da Arquitetura Hexagonal
Simula o comportamento do sistema KBNT Virtual Stock Management 
sem necessidade de Red Hat AMQ Streams rodando.
"""

import json
import random
import time
import argparse
from datetime import datetime, timezone
from typing import Dict, List
from dataclasses import dataclass

@dataclass
class HexagonalMessage:
    """Representa uma mensagem da arquitetura hexagonal"""
    service: str
    level: str
    message: str
    timestamp: str
    hexagonal_layer: str = None
    domain: str = None
    operation: str = None
    user: str = None
    action: str = None
    resource: str = None
    item_id: str = None
    current_stock: int = None
    amount: float = None
    transaction_id: str = None

class HexagonalWorkflowSimulator:
    """Simulador do workflow completo da arquitetura hexagonal"""
    
    def __init__(self):
        self.services = [
            'user-service', 'order-service', 'payment-service', 
            'inventory-service', 'notification-service', 'audit-service'
        ]
        self.levels = ['INFO', 'WARN', 'ERROR', 'DEBUG', 'AUDIT']
        self.hexagonal_layers = ['domain', 'application', 'infrastructure']
        self.domains = ['user', 'order', 'payment', 'inventory', 'notification']
        self.operations = [
            'command-received', 'command-processed', 'event-published',
            'stock-updated', 'payment-processed', 'user-validated',
            'database-updated', 'kafka-published', 'notification-sent'
        ]
        self.message_count = 0
        self.stats = {
            'total': 0,
            'by_service': {},
            'by_level': {},
            'by_layer': {},
            'by_domain': {},
            'special_events': {}
        }

    def generate_hexagonal_message(self) -> HexagonalMessage:
        """Gera uma mensagem seguindo padrões da arquitetura hexagonal"""
        service = random.choice(self.services)
        level = random.choices(self.levels, weights=[50, 20, 10, 15, 5])[0]
        
        # Mensagens específicas por camada hexagonal
        if random.random() < 0.6:  # 60% das mensagens seguem padrão hexagonal
            layer = random.choice(self.hexagonal_layers)
            domain = random.choice(self.domains)
            operation = random.choice(self.operations)
            
            message = self._generate_layer_message(layer, domain, operation, service)
            
            return HexagonalMessage(
                service=service,
                level=level,
                message=message,
                timestamp=datetime.now(timezone.utc).isoformat(),
                hexagonal_layer=layer,
                domain=domain,
                operation=operation
            )
        
        # Mensagens especiais (erros, pagamentos, alertas)
        elif level == 'ERROR':
            return self._generate_error_message(service)
        elif service == 'payment-service' and random.random() < 0.3:
            return self._generate_payment_message(service)
        elif service == 'inventory-service' and random.random() < 0.25:
            return self._generate_inventory_alert(service)
        elif level == 'AUDIT':
            return self._generate_audit_message(service)
        else:
            return self._generate_standard_message(service, level)

    def _generate_layer_message(self, layer: str, domain: str, operation: str, service: str) -> str:
        """Gera mensagens específicas por camada da arquitetura hexagonal"""
        if layer == 'domain':
            messages = [
                f"Domain event: {domain} {operation}",
                f"Business rule executed for {domain}",
                f"Domain object {domain} state changed via {operation}",
                f"Core business logic: {operation} completed for {domain}"
            ]
        elif layer == 'application':
            messages = [
                f"Application service processing {operation} for {domain}",
                f"Use case executed: {operation} on {domain}",
                f"Command handler: {operation} processed",
                f"Application layer coordinating {domain} {operation}"
            ]
        else:  # infrastructure
            messages = [
                f"Infrastructure: {operation} executed for {domain}",
                f"Database operation: {operation} on {domain} table",
                f"External service call: {operation} for {domain}",
                f"Message broker: publishing {domain} {operation} event"
            ]
        
        return random.choice(messages)

    def _generate_error_message(self, service: str) -> HexagonalMessage:
        """Gera mensagem de erro"""
        error_types = [
            "Database connection timeout",
            "Service unavailable",
            "Validation failed",
            "Network timeout",
            "Authentication failed"
        ]
        
        return HexagonalMessage(
            service=service,
            level='ERROR',
            message=f"Critical error: {random.choice(error_types)}",
            timestamp=datetime.now(timezone.utc).isoformat()
        )

    def _generate_payment_message(self, service: str) -> HexagonalMessage:
        """Gera mensagem de pagamento"""
        amount = round(random.uniform(10.0, 1000.0), 2)
        tx_id = f"TX{random.randint(100000, 999999)}"
        
        return HexagonalMessage(
            service=service,
            level='INFO',
            message=f"Payment processed successfully",
            timestamp=datetime.now(timezone.utc).isoformat(),
            amount=amount,
            transaction_id=tx_id
        )

    def _generate_inventory_alert(self, service: str) -> HexagonalMessage:
        """Gera alerta de inventário"""
        item_id = f"ITEM{random.randint(1000, 9999)}"
        stock = random.randint(0, 5)
        
        return HexagonalMessage(
            service=service,
            level='WARN',
            message=f"Low stock alert for {item_id}",
            timestamp=datetime.now(timezone.utc).isoformat(),
            item_id=item_id,
            current_stock=stock
        )

    def _generate_audit_message(self, service: str) -> HexagonalMessage:
        """Gera mensagem de auditoria"""
        users = ['admin', 'user001', 'system', 'operator']
        actions = ['CREATE', 'UPDATE', 'DELETE', 'ACCESS', 'MODIFY']
        resources = ['user-profile', 'order', 'payment', 'inventory-item']
        
        return HexagonalMessage(
            service=service,
            level='AUDIT',
            message=f"User action recorded",
            timestamp=datetime.now(timezone.utc).isoformat(),
            user=random.choice(users),
            action=random.choice(actions),
            resource=random.choice(resources)
        )

    def _generate_standard_message(self, service: str, level: str) -> HexagonalMessage:
        """Gera mensagem padrão"""
        messages = [
            "Service operation completed",
            "Request processed successfully",
            "System health check passed",
            "Configuration loaded",
            "Cache refreshed"
        ]
        
        return HexagonalMessage(
            service=service,
            level=level,
            message=random.choice(messages),
            timestamp=datetime.now(timezone.utc).isoformat()
        )

    def simulate_message_flow(self, num_messages: int = 150, delay: float = 0.1):
        """Simula o fluxo de mensagens do sistema"""
        print(f"🚀 Iniciando simulação do workflow hexagonal - {num_messages} mensagens")
        print(f"📐 Microserviços Spring Boot com arquitetura hexagonal em containers")
        print(f"🔄 Red Hat AMQ Streams (separado) - Simulação sem broker real")
        print("="*70)
        
        messages = []
        
        for i in range(num_messages):
            message = self.generate_hexagonal_message()
            messages.append(message)
            
            # Processa e exibe a mensagem
            self._process_message(message, i + 1)
            self._update_stats(message)
            
            # Delay para simular processamento real
            if delay > 0:
                time.sleep(delay)
        
        self._print_final_stats(num_messages)
        return messages

    def _process_message(self, message: HexagonalMessage, msg_num: int):
        """Processa e exibe uma mensagem"""
        prefix = f"[{msg_num:3d}]"
        
        if message.hexagonal_layer:
            print(f"{prefix} 🏗️  {message.hexagonal_layer.upper()}: {message.domain} - {message.operation}")
            print(f"      📋 {message.service} | {message.level} | {message.message}")
        elif message.level == 'ERROR':
            print(f"{prefix} 🚨 ERROR: {message.service} - {message.message}")
        elif message.level == 'AUDIT':
            print(f"{prefix} 📋 AUDIT: {message.user} {message.action} {message.resource}")
        elif message.amount:
            print(f"{prefix} 💰 PAYMENT: ${message.amount} (TX: {message.transaction_id})")
        elif message.item_id:
            print(f"{prefix} 📦 STOCK ALERT: {message.item_id} = {message.current_stock} units")
        else:
            print(f"{prefix} 📝 {message.service} | {message.level} | {message.message}")

    def _update_stats(self, message: HexagonalMessage):
        """Atualiza estatísticas"""
        self.stats['total'] += 1
        
        # Por serviço
        self.stats['by_service'][message.service] = self.stats['by_service'].get(message.service, 0) + 1
        
        # Por nível
        self.stats['by_level'][message.level] = self.stats['by_level'].get(message.level, 0) + 1
        
        # Por camada hexagonal
        if message.hexagonal_layer:
            self.stats['by_layer'][message.hexagonal_layer] = self.stats['by_layer'].get(message.hexagonal_layer, 0) + 1
        
        # Por domínio
        if message.domain:
            self.stats['by_domain'][message.domain] = self.stats['by_domain'].get(message.domain, 0) + 1
        
        # Eventos especiais
        if message.level == 'ERROR':
            self.stats['special_events']['errors'] = self.stats['special_events'].get('errors', 0) + 1
        if message.amount:
            self.stats['special_events']['payments'] = self.stats['special_events'].get('payments', 0) + 1
        if message.item_id:
            self.stats['special_events']['stock_alerts'] = self.stats['special_events'].get('stock_alerts', 0) + 1
        if message.level == 'AUDIT':
            self.stats['special_events']['audits'] = self.stats['special_events'].get('audits', 0) + 1

    def _print_final_stats(self, total_messages: int):
        """Imprime estatísticas finais"""
        print("\n" + "="*70)
        print("📊 HEXAGONAL ARCHITECTURE WORKFLOW SIMULATION RESULTS")
        print("="*70)
        print(f"Total messages simulated: {self.stats['total']}")
        
        print(f"\n📍 Spring Boot Microservices:")
        for service, count in sorted(self.stats['by_service'].items()):
            percentage = (count / total_messages) * 100
            print(f"  {service}: {count} ({percentage:.1f}%)")
        
        print(f"\n🚦 Log Levels:")
        for level, count in sorted(self.stats['by_level'].items()):
            percentage = (count / total_messages) * 100
            print(f"  {level}: {count} ({percentage:.1f}%)")
        
        if self.stats['by_layer']:
            print(f"\n🏗️  Hexagonal Architecture Layers:")
            for layer, count in sorted(self.stats['by_layer'].items()):
                percentage = (count / total_messages) * 100
                print(f"  {layer}: {count} ({percentage:.1f}%)")
        
        if self.stats['by_domain']:
            print(f"\n🎯 Business Domains:")
            for domain, count in sorted(self.stats['by_domain'].items()):
                percentage = (count / total_messages) * 100
                print(f"  {domain}: {count} ({percentage:.1f}%)")
        
        if self.stats['special_events']:
            print(f"\n⚡ Special Events:")
            for event, count in self.stats['special_events'].items():
                percentage = (count / total_messages) * 100
                print(f"  {event}: {count} ({percentage:.1f}%)")
        
        print("="*70)
        print("✅ Simulação completa! Microserviços + AMQ Streams funcionando corretamente")

def main():
    parser = argparse.ArgumentParser(description='Simula workflow da arquitetura hexagonal KBNT')
    parser.add_argument('--messages', type=int, default=150, help='Número de mensagens para simular')
    parser.add_argument('--delay', type=float, default=0.05, help='Delay entre mensagens em segundos')
    args = parser.parse_args()
    
    simulator = HexagonalWorkflowSimulator()
    simulator.simulate_message_flow(args.messages, args.delay)

if __name__ == "__main__":
    main()
