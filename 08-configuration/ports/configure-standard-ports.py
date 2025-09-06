#!/usr/bin/env python3
"""
Script para configurar portas padrão em todos os microserviços
Atualiza arquivos application.yml para usar o mapeamento padronizado
"""

import os
import re
from pathlib import Path

class PortConfigurationUpdater:
    def __init__(self, workspace_root):
        self.workspace_root = Path(workspace_root)
        self.microservices_path = self.workspace_root / '05-microservices'
        
        # Mapeamento de portas padrão
        self.port_mapping = {
            'api-gateway': {
                'server_port': 8080,
                'management_port': 9090
            },
            'log-producer-service': {
                'server_port': 8080,
                'management_port': 9090
            },
            'log-consumer-service': {
                'server_port': 8080,
                'management_port': 9090
            },
            'log-analytics-service': {
                'server_port': 8080,
                'management_port': 9090
            },
            'virtual-stock-service': {
                'server_port': 8080,
                'management_port': 9090
            },
            'kbnt-stock-consumer-service': {
                'server_port': 8080,
                'management_port': 9090
            }
        }
        
    def find_application_files(self):
        """Encontra todos os arquivos application.yml"""
        application_files = []
        
        for service_name in self.port_mapping.keys():
            service_path = self.microservices_path / service_name
            if service_path.exists():
                # Buscar application.yml principal
                main_config = service_path / 'src' / 'main' / 'resources' / 'application.yml'
                if main_config.exists():
                    application_files.append((service_name, main_config))
        
        return application_files
        
    def update_application_yml(self, service_name, file_path):
        """Atualiza um arquivo application.yml com as portas corretas"""
        print(f"📝 Atualizando: {service_name} - {file_path.name}")
        
        try:
            # Ler arquivo atual
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Configuração do serviço
            config = self.port_mapping[service_name]
            
            # Atualizar porta do servidor
            content = re.sub(r'(server:\s*\n\s*port:\s*)\d+', 
                           f'\\g<1>{config["server_port"]}', content)
            
            # Adicionar configuração de management se não existir
            if 'management:' not in content:
                management_config = f"""
management:
  server:
    port: {config["management_port"]}
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  endpoint:
    health:
      show-details: always
"""
                content += management_config
            
            # Para API Gateway, atualizar rotas para usar nomes de serviços
            if service_name == 'api-gateway':
                # Atualizar URIs das rotas para usar nomes de containers
                content = re.sub(r'uri:\s*http://localhost:\d+', 
                               'uri: http://virtual-stock-service:8080', content)
                content = re.sub(r'uri:\s*http://localhost:8082', 
                               'uri: http://log-producer-service:8080', content)
                content = re.sub(r'uri:\s*http://localhost:8083', 
                               'uri: http://kbnt-log-service:8080', content)
            
            # Salvar arquivo atualizado
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
                
            print(f"✅ Atualizado: {service_name}")
            return True
            
        except Exception as e:
            print(f"❌ Erro ao atualizar {service_name}: {e}")
            return False
    
    def create_port_reference(self):
        """Cria arquivo de referência de portas"""
        port_reference = """# REFERÊNCIA DE PORTAS PADRÃO

## Infraestrutura
- PostgreSQL: 5432
- Redis: 6379 
- Zookeeper: 2181
- Kafka: 9092, 29092

## Microserviços (Externa:Interna)
- API Gateway: 8080:8080, 9080:9090
- Log Producer: 8081:8080, 9081:9090
- Log Consumer: 8082:8080, 9082:9090
- Log Analytics: 8083:8080, 9083:9090
- Virtual Stock: 8084:8080, 9084:9090
- KBNT Consumer: 8085:8080, 9085:9090

## URLs de Acesso
- API Gateway: http://localhost:8080
- Log Producer: http://localhost:8081
- Log Consumer: http://localhost:8082  
- Log Analytics: http://localhost:8083
- Virtual Stock: http://localhost:8084
- KBNT Consumer: http://localhost:8085

## Health Checks
- API Gateway: http://localhost:8080/actuator/health
- Log Producer: http://localhost:8081/actuator/health
- Log Consumer: http://localhost:8082/actuator/health
- Log Analytics: http://localhost:8083/actuator/health
- Virtual Stock: http://localhost:8084/actuator/health
- KBNT Consumer: http://localhost:8085/actuator/health
"""
        
        reference_file = self.workspace_root / 'PORT_REFERENCE.md'
        with open(reference_file, 'w', encoding='utf-8') as f:
            f.write(port_reference)
        
        print(f"✅ Criado: {reference_file.name}")
    
    def run(self):
        """Executa a atualização completa"""
        print("🔧 CONFIGURADOR DE PORTAS PADRÃO - MICROSERVIÇOS")
        print("=" * 55)
        
        # Encontrar arquivos de configuração
        application_files = self.find_application_files()
        print(f"📁 Encontrados {len(application_files)} arquivos de configuração")
        
        # Atualizar arquivos existentes
        success_count = 0
        for service_name, file_path in application_files:
            if self.update_application_yml(service_name, file_path):
                success_count += 1
        
        # Criar arquivo de referência
        self.create_port_reference()
        
        print(f"\n✅ Concluído! {success_count}/{len(application_files)} arquivos atualizados")
        print("📋 Arquivo de referência criado: PORT_REFERENCE.md")
        
        return success_count

def main():
    """Função principal"""
    workspace_root = Path(__file__).parent
    updater = PortConfigurationUpdater(workspace_root)
    
    try:
        success = updater.run()
        if success > 0:
            print("\n🎉 Configuração de portas concluída com sucesso!")
            print("💡 Próximos passos:")
            print("   1. Rebuild dos containers: docker-compose build")
            print("   2. Restart dos serviços: docker-compose up -d")
            print("   3. Verificar health checks")
        else:
            print("\n⚠️ Nenhuma configuração foi atualizada")
            
    except Exception as e:
        print(f"\n❌ Erro durante configuração: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())
