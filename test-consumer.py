#!/usr/bin/env python3
"""
Teste simples do consumer de logs
"""
import sys
import os
sys.path.append(os.path.join(os.getcwd(), 'consumers', 'python'))

# Importa diretamente o arquivo
import importlib.util
spec = importlib.util.spec_from_file_location("log_consumer", "consumers/python/log-consumer.py")
log_consumer_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(log_consumer_module)

import json
from datetime import datetime

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

print("🧪 Testando LogConsumer...")
processor = log_consumer_module.LogConsumer()
processor.process_log(test_data)
print("✅ Teste do consumer realizado com sucesso!")
