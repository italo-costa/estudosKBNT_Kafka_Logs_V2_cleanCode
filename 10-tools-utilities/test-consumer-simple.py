#!/usr/bin/env python3
"""
Teste simplificado que testa apenas o processamento de log sem Kafka
"""
import sys
import os
import importlib.util

# Importa o módulo do consumer
spec = importlib.util.spec_from_file_location("log_consumer", "consumers/python/log-consumer.py")
log_consumer_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(log_consumer_module)

from datetime import datetime

def test_log_processing():
    """Testa apenas o processamento de logs"""
    
    # Cria uma instância sem inicializar o Kafka
    consumer_class = log_consumer_module.LogConsumer
    
    # Cria uma instância do consumer sem conectar ao Kafka
    class TestConsumer:
        def __init__(self):
            self.stats = {
                'total_messages': 0,
                'errors': 0,
                'by_service': {},
                'by_level': {}
            }
        
        # Copia os métodos de processamento do consumer original
        def __getattr__(self, name):
            return getattr(consumer_class, name)

    test_consumer = TestConsumer()
    
    # Dados de teste
    test_data = {
        "timestamp": datetime.now().isoformat(),
        "service": "test-service",
        "level": "INFO",
        "message": "Teste de funcionalidade do consumer",
        "hexagonal_layer": "domain",
        "domain": "test",
        "operation": "test-operation"
    }
    
    print("🧪 Testando processamento de logs sem Kafka...")
    
    try:
        # Testa o processamento básico - chama como método de instância
        consumer_class.process_log(test_consumer, test_data)
        print("✅ Processamento básico OK!")
        
        # Testa log hexagonal
        consumer_class.handle_hexagonal_layer_log(test_consumer, test_data)
        print("✅ Processamento hexagonal OK!")
        
        # Teste de erro
        error_data = {**test_data, "level": "ERROR"}
        consumer_class.handle_error_log(test_consumer, error_data)
        print("✅ Processamento de erro OK!")
        
        print("✅ Todos os testes do consumer passaram!")
        return True
        
    except Exception as e:
        print(f"❌ Erro no teste: {e}")
        return False

if __name__ == "__main__":
    success = test_log_processing()
    sys.exit(0 if success else 1)
