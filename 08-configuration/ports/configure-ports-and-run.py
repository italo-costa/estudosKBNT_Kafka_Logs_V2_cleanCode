#!/usr/bin/env python3
"""
Configuração de Portas e Execução das Aplicações
Configura portas apropriadas e inicia todos os microserviços sequencialmente
"""

import os
import sys
import time
import json
import subprocess
import requests
import threading
from datetime import datetime
from pathlib import Path

# Configuração de portas para cada serviço
PORT_CONFIG = {
    'api-gateway': 8080,
    'virtual-stock-service': 8081,
    'log-producer-service': 8082,
    'kbnt-log-service': 8083,
    'log-consumer-service': 8084,
    'log-analytics-service': 8085,
    'kbnt-stock-consumer-service': 8086
}

# Paths dos serviços
SERVICE_PATHS = {
    'api-gateway': '05-microservices/api-gateway',
    'virtual-stock-service': '05-microservices/virtual-stock-service',
    'log-producer-service': '05-microservices/log-producer-service',
    'kbnt-log-service': '05-microservices/kbnt-log-service',
    'log-consumer-service': '05-microservices/log-consumer-service',
    'log-analytics-service': '05-microservices/log-analytics-service',
    'kbnt-stock-consumer-service': '05-microservices/kbnt-stock-consumer-service'
}

class PortConfigurationManager:
    def __init__(self, workspace_root):
        self.workspace_root = Path(workspace_root)
        self.running_services = {}
        self.health_check_results = {}
        
    def configure_service_port(self, service_name, port):
        """Configura a porta de um serviço no application.yml"""
        service_path = self.workspace_root / SERVICE_PATHS[service_name]
        config_file = service_path / 'src' / 'main' / 'resources' / 'application.yml'
        
        print(f"📝 Configurando porta {port} para {service_name}...")
        
        if not config_file.exists():
            print(f"⚠️  Arquivo de configuração não encontrado: {config_file}")
            return False
            
        try:
            # Lê o conteúdo atual
            with open(config_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Atualiza a porta
            lines = content.split('\n')
            updated_lines = []
            
            for line in lines:
                if line.strip().startswith('port:'):
                    updated_lines.append(f'  port: {port}')
                else:
                    updated_lines.append(line)
            
            # Salva o arquivo atualizado
            with open(config_file, 'w', encoding='utf-8') as f:
                f.write('\n'.join(updated_lines))
                
            print(f"✅ Porta {port} configurada para {service_name}")
            return True
            
        except Exception as e:
            print(f"❌ Erro ao configurar porta para {service_name}: {e}")
            return False
    
    def update_gateway_routes(self):
        """Atualiza as rotas do API Gateway com as novas portas"""
        gateway_config = self.workspace_root / SERVICE_PATHS['api-gateway'] / 'src' / 'main' / 'resources' / 'application.yml'
        
        print("🔄 Atualizando rotas do API Gateway...")
        
        try:
            with open(gateway_config, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Atualiza as URIs dos serviços
            content = content.replace('virtual-stock-service:8080', f'localhost:{PORT_CONFIG["virtual-stock-service"]}')
            content = content.replace('log-producer-service:8080', f'localhost:{PORT_CONFIG["log-producer-service"]}')
            content = content.replace('kbnt-log-service:8081', f'localhost:{PORT_CONFIG["kbnt-log-service"]}')
            
            with open(gateway_config, 'w', encoding='utf-8') as f:
                f.write(content)
                
            print("✅ Rotas do API Gateway atualizadas")
            return True
            
        except Exception as e:
            print(f"❌ Erro ao atualizar rotas do Gateway: {e}")
            return False
    
    def build_service(self, service_name):
        """Faz o build de um serviço específico"""
        service_path = self.workspace_root / SERVICE_PATHS[service_name]
        
        print(f"🔨 Building {service_name}...")
        
        try:
            os.chdir(service_path)
            
            # Executa o build Maven
            result = subprocess.run(
                ['mvn', 'clean', 'package', '-DskipTests'],
                capture_output=True,
                text=True,
                timeout=180
            )
            
            if result.returncode == 0:
                print(f"✅ Build {service_name} concluído com sucesso")
                return True
            else:
                print(f"❌ Erro no build {service_name}: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ Erro no build {service_name}: {e}")
            return False
        finally:
            os.chdir(self.workspace_root)
    
    def start_service(self, service_name, port):
        """Inicia um serviço em uma porta específica"""
        service_path = self.workspace_root / SERVICE_PATHS[service_name]
        
        print(f"🚀 Iniciando {service_name} na porta {port}...")
        
        try:
            os.chdir(service_path)
            
            # Inicia o serviço com a porta especificada
            process = subprocess.Popen(
                ['mvn', 'spring-boot:run', f'-Dspring-boot.run.arguments=--server.port={port}'],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            self.running_services[service_name] = {
                'process': process,
                'port': port,
                'status': 'starting'
            }
            
            print(f"✅ {service_name} iniciado (PID: {process.pid})")
            return True
            
        except Exception as e:
            print(f"❌ Erro ao iniciar {service_name}: {e}")
            return False
        finally:
            os.chdir(self.workspace_root)
    
    def check_service_health(self, service_name, port, timeout=60):
        """Verifica se um serviço está saudável"""
        print(f"🔍 Verificando saúde do {service_name} na porta {port}...")
        
        health_url = f"http://localhost:{port}/actuator/health"
        start_time = time.time()
        
        while time.time() - start_time < timeout:
            try:
                response = requests.get(health_url, timeout=5)
                if response.status_code == 200:
                    self.health_check_results[service_name] = {
                        'status': 'healthy',
                        'port': port,
                        'response_time': time.time() - start_time
                    }
                    print(f"✅ {service_name} está saudável na porta {port}")
                    return True
            except:
                pass
            
            time.sleep(2)
        
        # Fallback: verifica apenas se a porta está respondendo
        try:
            import socket
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            result = sock.connect_ex(('localhost', port))
            sock.close()
            
            if result == 0:
                self.health_check_results[service_name] = {
                    'status': 'responding',
                    'port': port,
                    'response_time': time.time() - start_time
                }
                print(f"⚠️  {service_name} está respondendo na porta {port} (sem health check)")
                return True
        except:
            pass
        
        self.health_check_results[service_name] = {
            'status': 'unhealthy',
            'port': port,
            'response_time': timeout
        }
        print(f"❌ {service_name} não está respondendo na porta {port}")
        return False
    
    def stop_all_services(self):
        """Para todos os serviços em execução"""
        print("\n🛑 Parando todos os serviços...")
        
        for service_name, service_info in self.running_services.items():
            try:
                process = service_info['process']
                process.terminate()
                process.wait(timeout=10)
                print(f"✅ {service_name} parado")
            except:
                try:
                    process.kill()
                    print(f"🔫 {service_name} forçadamente parado")
                except:
                    print(f"❌ Erro ao parar {service_name}")

def perform_load_test(base_url, num_requests=10000):
    """Executa teste de carga com 10.000 requisições"""
    print(f"\n🎯 Iniciando teste de carga com {num_requests} requisições...")
    
    results = {
        'total_requests': num_requests,
        'successful_requests': 0,
        'failed_requests': 0,
        'response_times': [],
        'errors': []
    }
    
    def make_request(request_id):
        try:
            start_time = time.time()
            response = requests.get(f"{base_url}/api/v1/virtual-stock/health", timeout=10)
            end_time = time.time()
            
            response_time = (end_time - start_time) * 1000  # em ms
            
            if response.status_code == 200:
                results['successful_requests'] += 1
                results['response_times'].append(response_time)
            else:
                results['failed_requests'] += 1
                results['errors'].append(f"Request {request_id}: HTTP {response.status_code}")
        except Exception as e:
            results['failed_requests'] += 1
            results['errors'].append(f"Request {request_id}: {str(e)}")
    
    # Executa requisições em threads
    threads = []
    batch_size = 100
    
    for i in range(0, num_requests, batch_size):
        batch_threads = []
        for j in range(i, min(i + batch_size, num_requests)):
            thread = threading.Thread(target=make_request, args=(j,))
            batch_threads.append(thread)
            thread.start()
        
        # Espera o batch completar
        for thread in batch_threads:
            thread.join()
        
        # Progress
        completed = min(i + batch_size, num_requests)
        progress = (completed / num_requests) * 100
        print(f"Progress: {completed}/{num_requests} ({progress:.1f}%)")
    
    # Calcula estatísticas
    if results['response_times']:
        avg_time = sum(results['response_times']) / len(results['response_times'])
        min_time = min(results['response_times'])
        max_time = max(results['response_times'])
        
        results['avg_response_time'] = avg_time
        results['min_response_time'] = min_time
        results['max_response_time'] = max_time
    
    return results

def main():
    workspace_root = Path.cwd()
    config_manager = PortConfigurationManager(workspace_root)
    
    print("🚀 Configurando portas e iniciando aplicações")
    print("=" * 60)
    
    try:
        # 1. Configurar portas para todos os serviços
        print("\n📝 Configurando portas...")
        for service_name, port in PORT_CONFIG.items():
            config_manager.configure_service_port(service_name, port)
        
        # 2. Atualizar rotas do Gateway
        config_manager.update_gateway_routes()
        
        # 3. Build dos serviços principais
        build_services = ['virtual-stock-service', 'log-producer-service', 'api-gateway']
        print(f"\n🔨 Building serviços: {build_services}")
        
        for service in build_services:
            if not config_manager.build_service(service):
                print(f"❌ Falha no build de {service}")
                return
        
        # 4. Iniciar serviços sequencialmente
        startup_order = ['virtual-stock-service', 'log-producer-service', 'api-gateway']
        print(f"\n🚀 Iniciando serviços na ordem: {startup_order}")
        
        for service in startup_order:
            port = PORT_CONFIG[service]
            if config_manager.start_service(service, port):
                # Aguarda um pouco antes de verificar saúde
                time.sleep(10)
                config_manager.check_service_health(service, port)
                time.sleep(5)  # Pausa entre serviços
        
        # 5. Aguardar todos os serviços ficarem online
        print("\n⏰ Aguardando estabilização dos serviços...")
        time.sleep(30)
        
        # 6. Executar teste de carga
        if config_manager.health_check_results.get('api-gateway', {}).get('status') in ['healthy', 'responding']:
            print("\n🎯 API Gateway está respondendo, iniciando teste de carga...")
            
            test_results = perform_load_test("http://localhost:8080", 10000)
            
            # Salvar resultados
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            results_file = f"performance_test_10k_results_{timestamp}.json"
            
            with open(results_file, 'w') as f:
                json.dump(test_results, f, indent=2)
            
            # Exibir resultados
            print("\n📊 RESULTADOS DO TESTE DE CARGA")
            print("=" * 50)
            print(f"Total de requisições: {test_results['total_requests']}")
            print(f"Requisições bem-sucedidas: {test_results['successful_requests']}")
            print(f"Requisições falhadas: {test_results['failed_requests']}")
            
            if 'avg_response_time' in test_results:
                print(f"Tempo médio de resposta: {test_results['avg_response_time']:.2f}ms")
                print(f"Tempo mínimo: {test_results['min_response_time']:.2f}ms")
                print(f"Tempo máximo: {test_results['max_response_time']:.2f}ms")
            
            success_rate = (test_results['successful_requests'] / test_results['total_requests']) * 100
            print(f"Taxa de sucesso: {success_rate:.2f}%")
            
            print(f"\n📄 Resultados salvos em: {results_file}")
        else:
            print("❌ API Gateway não está respondendo, não é possível executar teste de carga")
    
    except KeyboardInterrupt:
        print("\n\n⚠️  Interrompido pelo usuário")
    except Exception as e:
        print(f"\n❌ Erro durante execução: {e}")
    finally:
        # Para todos os serviços
        config_manager.stop_all_services()
        
        # Salva relatório final
        final_report = {
            'timestamp': datetime.now().isoformat(),
            'port_configuration': PORT_CONFIG,
            'health_checks': config_manager.health_check_results,
            'running_services': {k: {
                'port': v['port'],
                'status': v['status']
            } for k, v in config_manager.running_services.items()}
        }
        
        with open('port_configuration_report.json', 'w') as f:
            json.dump(final_report, f, indent=2)
        
        print("\n📄 Relatório final salvo em: port_configuration_report.json")

if __name__ == "__main__":
    main()
