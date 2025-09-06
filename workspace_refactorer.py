#!/usr/bin/env python3
"""
Refatoração do Workspace - Clean Architecture
Organiza todos os arquivos nas pastas corretas seguindo a arquitetura definida
"""

import os
import shutil
import json
from pathlib import Path
from datetime import datetime

class WorkspaceRefactorer:
    def __init__(self, workspace_root):
        self.workspace_root = Path(workspace_root)
        self.refactoring_plan = {}
        self.moved_files = {}
        self.errors = []
        
        # Definição da estrutura Clean Architecture
        self.architecture_structure = {
            "01-presentation-layer": {
                "description": "Interfaces de apresentação, documentação e relatórios",
                "subdirs": ["docs", "reports", "dashboards"],
                "file_patterns": ["*.md", "*report*", "*relatorio*", "*README*", "*dashboard*"]
            },
            "02-application-layer": {
                "description": "Casos de uso, serviços de aplicação e orquestração",
                "subdirs": ["services", "use-cases", "orchestration"],
                "file_patterns": ["*application*", "*service*", "*orchestration*", "*use-case*"]
            },
            "03-domain-layer": {
                "description": "Entidades, regras de negócio e modelos de domínio",
                "subdirs": ["entities", "value-objects", "domain-services"],
                "file_patterns": ["*domain*", "*entity*", "*model*", "*business*"]
            },
            "04-infrastructure-layer": {
                "description": "Infraestrutura, configurações e integrações externas",
                "subdirs": ["docker", "kubernetes", "config", "databases"],
                "file_patterns": ["docker*", "kubernetes*", "*.yml", "*.yaml", "*config*", "*infrastructure*"]
            },
            "05-microservices": {
                "description": "Implementação dos microserviços",
                "subdirs": ["api-gateway", "log-services", "stock-services", "shared"],
                "file_patterns": ["*microservice*", "*gateway*", "*producer*", "*consumer*"]
            },
            "06-deployment": {
                "description": "Scripts de deployment e DevOps",
                "subdirs": ["scripts", "automation", "ci-cd"],
                "file_patterns": ["*deploy*", "*startup*", "*build*", "*automation*"]
            },
            "07-testing": {
                "description": "Testes, performance e qualidade",
                "subdirs": ["unit-tests", "integration-tests", "performance-tests", "stress-tests"],
                "file_patterns": ["*test*", "*performance*", "*stress*", "*mock*"]
            },
            "08-configuration": {
                "description": "Configurações globais e ambiente",
                "subdirs": ["properties", "ports", "environment"],
                "file_patterns": ["*.properties", "*config*", "*port*", "*environment*"]
            },
            "09-monitoring": {
                "description": "Monitoramento, métricas e observabilidade",
                "subdirs": ["metrics", "logs", "prometheus", "grafana"],
                "file_patterns": ["*metric*", "*prometheus*", "*monitoring*", "*observability*"]
            },
            "10-tools-utilities": {
                "description": "Ferramentas, utilitários e scripts auxiliares",
                "subdirs": ["scripts", "generators", "analyzers", "cleaners"],
                "file_patterns": ["*.py", "*.ps1", "*tool*", "*utility*", "*helper*", "*generator*"]
            }
        }
        
    def analyze_current_structure(self):
        """Analisa a estrutura atual do workspace"""
        print("🔍 Analisando estrutura atual do workspace...")
        
        current_files = []
        for item in self.workspace_root.iterdir():
            if item.is_file() and not item.name.startswith('.'):
                current_files.append(item)
        
        print(f"📁 Encontrados {len(current_files)} arquivos na raiz para reorganizar")
        return current_files
    
    def categorize_file(self, file_path):
        """Categoriza um arquivo baseado no nome e conteúdo"""
        file_name = file_path.name.lower()
        
        # Prioridades de categorização
        categorization_rules = {
            # Documentação e Relatórios
            "01-presentation-layer": [
                "readme", "relatorio", "report", "analise", "comparativo", 
                "correcoes", "escalabilidade", "workflow", ".md"
            ],
            
            # Scripts de Aplicação
            "02-application-layer": [
                "docker-compose-application", "layered-build-startup", 
                "start-real-application", "setup-development-environment"
            ],
            
            # Domain (menos arquivos aqui)
            "03-domain-layer": [
                "temp_stock.json"  # arquivo de domínio de estoque
            ],
            
            # Infraestrutura
            "04-infrastructure-layer": [
                "docker-compose", ".yml", ".yaml", "kubernetes", "prometheus-metrics"
            ],
            
            # Testing
            "07-testing": [
                "test", "performance", "stress", "mock", "simplified"
            ],
            
            # Configuration
            "08-configuration": [
                "port", "config", ".properties", "final_port", "configure"
            ],
            
            # Monitoring
            "09-monitoring": [
                "execution_report", "docker_execution", "metrics", "prometheus"
            ],
            
            # Tools and Utilities (tudo que sobrar)
            "10-tools-utilities": [
                ".py", ".ps1", "final_cleanup", "import_checker", 
                "create_resources", "view-stress", "workspace_organizer"
            ]
        }
        
        # Verificar por prioridade
        for layer, patterns in categorization_rules.items():
            for pattern in patterns:
                if pattern in file_name:
                    return layer
        
        # Default para tools se não encontrou categoria
        return "10-tools-utilities"
    
    def create_directory_structure(self):
        """Cria a estrutura de diretórios da Clean Architecture"""
        print("\n🏗️ Criando estrutura de diretórios Clean Architecture...")
        
        for layer_name, layer_config in self.architecture_structure.items():
            layer_path = self.workspace_root / layer_name
            layer_path.mkdir(exist_ok=True)
            
            # Criar subdiretórios
            for subdir in layer_config["subdirs"]:
                subdir_path = layer_path / subdir
                subdir_path.mkdir(exist_ok=True)
            
            print(f"✅ {layer_name}: {layer_config['description']}")
    
    def move_file_to_layer(self, file_path, target_layer):
        """Move um arquivo para a camada apropriada"""
        try:
            layer_path = self.workspace_root / target_layer
            
            # Determinar subdiretório baseado no tipo de arquivo
            subdir = self.determine_subdirectory(file_path, target_layer)
            target_dir = layer_path / subdir
            target_dir.mkdir(exist_ok=True)
            
            target_path = target_dir / file_path.name
            
            # Verificar se arquivo já existe
            if target_path.exists():
                print(f"⚠️ Arquivo já existe: {target_path}")
                return False
            
            # Mover arquivo
            shutil.move(str(file_path), str(target_path))
            
            # Registrar movimento
            self.moved_files[str(file_path)] = str(target_path)
            print(f"📦 {file_path.name} → {target_layer}/{subdir}/")
            
            return True
            
        except Exception as e:
            error_msg = f"Erro ao mover {file_path.name}: {e}"
            self.errors.append(error_msg)
            print(f"❌ {error_msg}")
            return False
    
    def determine_subdirectory(self, file_path, layer):
        """Determina o subdiretório apropriado dentro da camada"""
        file_name = file_path.name.lower()
        
        subdirectory_mapping = {
            "01-presentation-layer": {
                "docs": ["readme", ".md", "documentation"],
                "reports": ["report", "relatorio", "analise", "comparativo"],
                "dashboards": ["dashboard", "visual", "chart"]
            },
            "02-application-layer": {
                "services": ["service", "application"],
                "orchestration": ["orchestration", "startup", "layered"],
                "use-cases": ["use-case", "business-logic"]
            },
            "04-infrastructure-layer": {
                "docker": ["docker", "compose"],
                "kubernetes": ["kubernetes", "k8s"],
                "config": ["config", "properties", "yml", "yaml"]
            },
            "07-testing": {
                "performance-tests": ["performance", "stress"],
                "unit-tests": ["unit", "test"],
                "integration-tests": ["integration", "mock"],
                "stress-tests": ["stress", "load"]
            },
            "08-configuration": {
                "ports": ["port"],
                "properties": ["properties", "config"],
                "environment": ["environment", "env"]
            },
            "09-monitoring": {
                "metrics": ["metric", "prometheus"],
                "logs": ["execution_report", "log"]
            },
            "10-tools-utilities": {
                "scripts": [".py", ".ps1"],
                "generators": ["generator", "create"],
                "analyzers": ["analyzer", "checker"],
                "cleaners": ["cleanup", "cleaner"]
            }
        }
        
        layer_mapping = subdirectory_mapping.get(layer, {})
        
        for subdir, patterns in layer_mapping.items():
            for pattern in patterns:
                if pattern in file_name:
                    return subdir
        
        # Default para primeiro subdiretório da camada
        return self.architecture_structure[layer]["subdirs"][0]
    
    def create_layer_documentation(self):
        """Cria documentação para cada camada"""
        print("\n📚 Criando documentação das camadas...")
        
        for layer_name, layer_config in self.architecture_structure.items():
            layer_path = self.workspace_root / layer_name
            readme_path = layer_path / "README.md"
            
            readme_content = f"""# {layer_name.replace('-', ' ').title()}

## Descrição
{layer_config['description']}

## Estrutura
```
{layer_name}/
"""
            
            for subdir in layer_config["subdirs"]:
                readme_content += f"├── {subdir}/\n"
            
            readme_content += f"""```

## Responsabilidades
Esta camada é responsável por:
- {layer_config['description']}

## Padrões de Arquivo
- {', '.join(layer_config['file_patterns'])}

## Última Atualização
{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
"""
            
            with open(readme_path, 'w', encoding='utf-8') as f:
                f.write(readme_content)
            
            print(f"📄 {layer_name}/README.md criado")
    
    def generate_refactoring_report(self):
        """Gera relatório da refatoração"""
        report = {
            "refactoring_metadata": {
                "timestamp": datetime.now().isoformat(),
                "workspace_path": str(self.workspace_root),
                "refactoring_type": "clean_architecture_organization"
            },
            "architecture_layers": self.architecture_structure,
            "moved_files": self.moved_files,
            "errors": self.errors,
            "statistics": {
                "total_files_moved": len(self.moved_files),
                "errors_count": len(self.errors),
                "layers_created": len(self.architecture_structure)
            }
        }
        
        report_path = self.workspace_root / "10-tools-utilities" / "scripts" / "workspace_refactoring_report.json"
        report_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(report_path, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        print(f"📊 Relatório salvo: {report_path}")
        return report
    
    def run_refactoring(self):
        """Executa a refatoração completa"""
        print("🔄 REFATORAÇÃO WORKSPACE - CLEAN ARCHITECTURE")
        print("=" * 55)
        
        # 1. Analisar estrutura atual
        files_to_move = self.analyze_current_structure()
        
        # 2. Criar estrutura de diretórios
        self.create_directory_structure()
        
        # 3. Mover arquivos
        print(f"\n📦 Movendo {len(files_to_move)} arquivos...")
        moved_count = 0
        
        for file_path in files_to_move:
            target_layer = self.categorize_file(file_path)
            if self.move_file_to_layer(file_path, target_layer):
                moved_count += 1
        
        # 4. Criar documentação das camadas
        self.create_layer_documentation()
        
        # 5. Gerar relatório
        report = self.generate_refactoring_report()
        
        # 6. Mostrar resumo
        print(f"\n{'='*55}")
        print("📊 RESUMO DA REFATORAÇÃO")
        print(f"{'='*55}")
        print(f"✅ Arquivos movidos: {moved_count}/{len(files_to_move)}")
        print(f"🏗️ Camadas criadas: {len(self.architecture_structure)}")
        print(f"📄 Documentação gerada: {len(self.architecture_structure)} READMEs")
        print(f"❌ Erros: {len(self.errors)}")
        
        if self.errors:
            print(f"\n⚠️ Erros encontrados:")
            for error in self.errors:
                print(f"   - {error}")
        
        print(f"\n🎉 Refatoração concluída!")
        print(f"📁 Workspace organizado seguindo Clean Architecture")
        
        return report

def main():
    """Função principal"""
    workspace_root = Path(__file__).parent
    refactorer = WorkspaceRefactorer(workspace_root)
    
    try:
        report = refactorer.run_refactoring()
        
        print(f"\n💡 Próximos passos:")
        print(f"   1. Revisar arquivos movidos")
        print(f"   2. Atualizar referências nos scripts")
        print(f"   3. Verificar imports e paths")
        print(f"   4. Testar funcionalidades")
        
        return 0
        
    except Exception as e:
        print(f"\n❌ Erro durante refatoração: {e}")
        return 1

if __name__ == "__main__":
    exit(main())
