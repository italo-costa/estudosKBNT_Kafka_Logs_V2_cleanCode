#!/usr/bin/env python3
"""
KBNT Virtual Stock Test - Hexagonal Architecture Workflow
Simulates the complete flow from microservices to your log consumer

This script tests:
1. Stock events generation (simulating Spring Boot microservices)
2. Message publishing to AMQ Streams topics
3. Your log-consumer.py processing the messages
4. End-to-end hexagonal architecture workflow
"""

import json
import random
import time
from datetime import datetime, timezone
from kafka import KafkaProducer
from kafka.errors import KafkaError

class VirtualStockWorkflowTest:
    def __init__(self, bootstrap_servers='localhost:9092'):
        self.bootstrap_servers = bootstrap_servers
        self.producer = KafkaProducer(
            bootstrap_servers=[bootstrap_servers],
            value_serializer=lambda v: json.dumps(v).encode('utf-8'),
            key_serializer=lambda k: k.encode('utf-8') if k else None,
            acks='all',  # Ensure message durability
            retries=3,
            compression_type='snappy'
        )
        
        # Simulate different microservices from your hexagonal architecture
        self.services = [
            'stock-producer-service',
            'stock-consumer-service', 
            'kbnt-log-service',
            'payment-service',
            'inventory-service',
            'notification-service'
        ]
        
        # Stock symbols for testing
        self.stock_symbols = ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'TSLA', 'META']
        
        # Topics matching your AmqStreamsTopicConfiguration.java
        self.topics = {
            'application': 'kbnt-application-logs',
            'error': 'kbnt-error-logs', 
            'audit': 'kbnt-audit-logs',
            'financial': 'kbnt-financial-logs'
        }

    def generate_application_log(self, service):
        """Generate application log message (matches your consumer expectations)"""
        symbol = random.choice(self.stock_symbols)
        quantity = random.randint(10, 1000)
        price = round(random.uniform(50, 500), 2)
        
        return {
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'service': service,
            'level': 'INFO',
            'message': f'Stock update processed: {symbol} quantity={quantity} price=${price}',
            'stock_symbol': symbol,
            'quantity': quantity,
            'price': price,
            'transaction_id': f'TXN-{random.randint(10000, 99999)}',
            'trace_id': f'trace-{random.randint(1000, 9999)}',
            'hexagonal_layer': 'application-service'  # Indicates hexagonal architecture layer
        }

    def generate_error_log(self, service):
        """Generate error log message"""
        errors = [
            'Database connection timeout',
            'Kafka message delivery failed',
            'Stock validation error: insufficient inventory',
            'Payment processing failed: card declined',
            'External API timeout: pricing service unreachable'
        ]
        
        return {
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'service': service,
            'level': 'ERROR',
            'message': random.choice(errors),
            'error_code': f'ERR-{random.randint(1000, 9999)}',
            'stack_trace': 'java.lang.RuntimeException: Simulated error for testing',
            'hexagonal_layer': 'infrastructure-adapter'
        }

    def generate_audit_log(self, service):
        """Generate audit log message"""
        actions = [
            'User login attempt',
            'Stock price updated by admin',
            'Payment authorization requested',
            'Inventory threshold modified',
            'System configuration changed'
        ]
        
        return {
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'service': service,
            'level': 'AUDIT',
            'message': random.choice(actions),
            'user_id': f'user-{random.randint(100, 999)}',
            'action': random.choice(actions),
            'ip_address': f'192.168.1.{random.randint(1, 254)}',
            'hexagonal_layer': 'domain-service'
        }

    def generate_financial_log(self, service):
        """Generate financial log message"""
        symbol = random.choice(self.stock_symbols)
        amount = round(random.uniform(100, 10000), 2)
        
        return {
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'service': service,
            'level': 'INFO',
            'message': f'Payment processed: ${amount} for {symbol}',
            'amount': amount,
            'stock_symbol': symbol,
            'transaction_id': f'TXN-{random.randint(100000, 999999)}',
            'payment_method': random.choice(['credit_card', 'bank_transfer', 'digital_wallet']),
            'hexagonal_layer': 'domain-service'
        }

    def generate_stock_alert(self, service):
        """Generate stock alert message (triggers special handling in your consumer)"""
        symbol = random.choice(self.stock_symbols)
        current_stock = random.randint(1, 50)
        
        return {
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'service': service,
            'level': 'WARN',
            'message': f'Stock alert: Low inventory for {symbol}',
            'item_id': symbol,
            'current_stock': current_stock,
            'threshold': 25,
            'alert_type': 'low_inventory',
            'hexagonal_layer': 'domain-service'
        }

    def send_message(self, topic, message, key=None):
        """Send message to Kafka topic"""
        try:
            future = self.producer.send(topic, value=message, key=key)
            record_metadata = future.get(timeout=10)
            return True
        except KafkaError as e:
            print(f"❌ Failed to send message: {e}")
            return False

    def run_hexagonal_workflow_test(self, total_messages=150):
        """
        Run complete hexagonal architecture workflow test
        Simulates the real application flow
        """
        print("🏗️ KBNT Hexagonal Architecture Workflow Test")
        print("=" * 50)
        print(f"📊 Generating {total_messages} messages across microservices")
        print(f"🎯 Target: AMQ Streams topics")
        print(f"🐍 Consumer: Your log-consumer.py will process these")
        print()
        
        stats = {
            'total_sent': 0,
            'by_topic': {},
            'by_service': {},
            'errors': 0
        }
        
        for i in range(1, total_messages + 1):
            service = random.choice(self.services)
            
            # Weighted distribution of message types (realistic production scenario)
            rand = random.randint(1, 100)
            
            if rand <= 50:  # 50% application logs
                message = self.generate_application_log(service)
                topic = self.topics['application']
            elif rand <= 65:  # 15% financial logs  
                message = self.generate_financial_log(service)
                topic = self.topics['financial']
            elif rand <= 80:  # 15% audit logs
                message = self.generate_audit_log(service)
                topic = self.topics['audit']
            elif rand <= 90:  # 10% stock alerts (special handling in your consumer)
                message = self.generate_stock_alert(service)
                topic = self.topics['application']
            else:  # 10% error logs
                message = self.generate_error_log(service)
                topic = self.topics['error']
            
            # Send message
            key = f"{service}-{message.get('transaction_id', i)}"
            success = self.send_message(topic, message, key)
            
            if success:
                stats['total_sent'] += 1
                stats['by_topic'][topic] = stats['by_topic'].get(topic, 0) + 1
                stats['by_service'][service] = stats['by_service'].get(service, 0) + 1
                
                print(f"[{i:3d}/{total_messages}] ✅ {service} → {topic} ({message['level']})")
            else:
                stats['errors'] += 1
                print(f"[{i:3d}/{total_messages}] ❌ Failed to send message")
            
            # Small delay to simulate realistic message flow
            time.sleep(0.05)
            
            # Progress update every 25 messages
            if i % 25 == 0:
                print(f"\n📊 Progress: {i}/{total_messages} messages sent")
                print(f"   Success rate: {(stats['total_sent']/i)*100:.1f}%")
                print()
        
        # Final statistics
        print("\n" + "=" * 50)
        print("📊 WORKFLOW TEST COMPLETED")
        print("=" * 50)
        print(f"Total messages sent: {stats['total_sent']}")
        print(f"Failed messages: {stats['errors']}")
        print(f"Success rate: {(stats['total_sent']/total_messages)*100:.1f}%")
        
        print(f"\n📋 Messages by Topic:")
        for topic, count in stats['by_topic'].items():
            print(f"  {topic}: {count}")
            
        print(f"\n🏗️ Messages by Microservice:")
        for service, count in stats['by_service'].items():
            print(f"  {service}: {count}")
        
        print("\n🎯 Next Steps:")
        print("1. Run your log consumer to process these messages:")
        print("   python consumers/python/log-consumer.py --topic kbnt-application-logs")
        print("2. Monitor different log levels and special handling")
        print("3. Check hexagonal architecture layer information in messages")
        
        self.producer.close()

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='KBNT Hexagonal Architecture Workflow Test')
    parser.add_argument('--messages', type=int, default=150,
                       help='Number of messages to generate (default: 150)')
    parser.add_argument('--kafka-server', default='localhost:9092',
                       help='Kafka bootstrap server (default: localhost:9092)')
    
    args = parser.parse_args()
    
    test = VirtualStockWorkflowTest(args.kafka_server)
    test.run_hexagonal_workflow_test(args.messages)
