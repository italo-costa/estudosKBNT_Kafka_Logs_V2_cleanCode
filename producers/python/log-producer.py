#!/usr/bin/env python3
"""
Produtor de Logs para Kafka
Este script simula a geração de logs de aplicação e os envia para um tópico Kafka
"""

import json
import logging
import random
import time
from datetime import datetime
from kafka import KafkaProducer
from kafka.errors import KafkaError

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class LogProducer:
    def __init__(self, bootstrap_servers=['localhost:9092'], topic='application-logs'):
        self.topic = topic
        self.producer = KafkaProducer(
            bootstrap_servers=bootstrap_servers,
            value_serializer=lambda x: json.dumps(x).encode('utf-8'),
            key_serializer=lambda x: str(x).encode('utf-8'),
            acks='all',  # Aguarda confirmação de todas as réplicas
            retries=3,
            batch_size=16384,
            linger_ms=10,
            compression_type='snappy'
        )
        
        # Templates de logs para simulação
        self.log_templates = [
            {"service": "user-service", "level": "INFO", "message": "User {} logged in successfully"},
            {"service": "user-service", "level": "WARN", "message": "Failed login attempt for user {}"},
            {"service": "payment-service", "level": "INFO", "message": "Payment processed: ${:.2f}"},
            {"service": "payment-service", "level": "ERROR", "message": "Payment failed: insufficient funds"},
            {"service": "inventory-service", "level": "INFO", "message": "Item {} added to inventory"},
            {"service": "inventory-service", "level": "WARN", "message": "Low stock alert for item {}"},
            {"service": "api-gateway", "level": "INFO", "message": "Request processed: {} {} - {}ms"},
            {"service": "database", "level": "ERROR", "message": "Connection timeout after 30s"},
        ]
        
        self.user_ids = [f"user_{i}" for i in range(1, 101)]
        self.item_ids = [f"item_{i}" for i in range(1, 51)]
        self.http_methods = ["GET", "POST", "PUT", "DELETE"]
        self.endpoints = ["/api/users", "/api/products", "/api/orders", "/api/payments"]

    def generate_log_entry(self):
        """Gera uma entrada de log sintética"""
        template = random.choice(self.log_templates)
        
        log_entry = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "service": template["service"],
            "level": template["level"],
            "host": f"pod-{random.randint(1, 10)}",
            "environment": "development",
            "request_id": f"req-{random.randint(1000000, 9999999)}",
        }
        
        # Personaliza a mensagem baseada no template
        if "User {} logged" in template["message"]:
            log_entry["message"] = template["message"].format(random.choice(self.user_ids))
            log_entry["user_id"] = random.choice(self.user_ids)
            
        elif "Payment processed" in template["message"]:
            amount = random.uniform(10.0, 999.99)
            log_entry["message"] = template["message"].format(amount)
            log_entry["amount"] = round(amount, 2)
            log_entry["transaction_id"] = f"tx-{random.randint(100000, 999999)}"
            
        elif "Item {} added" in template["message"] or "stock alert for item {}" in template["message"]:
            item_id = random.choice(self.item_ids)
            log_entry["message"] = template["message"].format(item_id)
            log_entry["item_id"] = item_id
            if "stock alert" in template["message"]:
                log_entry["current_stock"] = random.randint(1, 5)
                
        elif "Request processed" in template["message"]:
            method = random.choice(self.http_methods)
            endpoint = random.choice(self.endpoints)
            response_time = random.randint(10, 2000)
            log_entry["message"] = template["message"].format(method, endpoint, response_time)
            log_entry["http_method"] = method
            log_entry["endpoint"] = endpoint
            log_entry["response_time_ms"] = response_time
            log_entry["status_code"] = random.choice([200, 201, 400, 404, 500])
            
        else:
            log_entry["message"] = template["message"]
            
        return log_entry

    def send_log(self, log_entry):
        """Envia um log para o tópico Kafka"""
        try:
            # Usa o service como chave para particionamento
            key = log_entry["service"]
            
            future = self.producer.send(self.topic, key=key, value=log_entry)
            record_metadata = future.get(timeout=10)
            
            logger.info(f"Log sent to topic '{record_metadata.topic}' "
                       f"partition {record_metadata.partition} "
                       f"offset {record_metadata.offset}")
            return True
            
        except KafkaError as e:
            logger.error(f"Failed to send log: {e}")
            return False

    def start_producing(self, interval=1, total_logs=None):
        """Inicia a produção contínua de logs"""
        logger.info(f"Starting log production to topic '{self.topic}'")
        logger.info(f"Interval: {interval}s, Total logs: {total_logs or 'unlimited'}")
        
        count = 0
        try:
            while total_logs is None or count < total_logs:
                log_entry = self.generate_log_entry()
                
                if self.send_log(log_entry):
                    count += 1
                    logger.info(f"Produced log #{count}: {log_entry['service']} - {log_entry['level']}")
                
                time.sleep(interval)
                
        except KeyboardInterrupt:
            logger.info("Production stopped by user")
        except Exception as e:
            logger.error(f"Production error: {e}")
        finally:
            self.producer.close()
            logger.info(f"Total logs produced: {count}")

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Kafka Log Producer')
    parser.add_argument('--bootstrap-servers', default='localhost:9092',
                       help='Kafka bootstrap servers (default: localhost:9092)')
    parser.add_argument('--topic', default='application-logs',
                       help='Kafka topic (default: application-logs)')
    parser.add_argument('--interval', type=float, default=1.0,
                       help='Interval between logs in seconds (default: 1.0)')
    parser.add_argument('--count', type=int, default=None,
                       help='Total number of logs to produce (default: unlimited)')
    
    args = parser.parse_args()
    
    producer = LogProducer(
        bootstrap_servers=args.bootstrap_servers.split(','),
        topic=args.topic
    )
    
    producer.start_producing(interval=args.interval, total_logs=args.count)
