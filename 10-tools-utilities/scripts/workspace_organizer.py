#!/usr/bin/env python3
"""
KBNT Kafka Logs - Final Workspace Organization
Move todos os arquivos restantes para suas respectivas camadas
"""

import os
import shutil
import json
from pathlib import Path
from typing import Dict, List, Tuple

class WorkspaceOrganizer:
    def __init__(self, workspace_path: str):
        self.workspace_path = Path(workspace_path)
        self.moved_files = []
        self.organized_files = {}
        
        # Mapeamento de arquivos para camadas
        self.layer_mappings = {
            # Documentação e arquivos markdown
            '09-documentation/': [
                '*.md', 'README.md', 'LICENSE', '*.txt'
            ],
            
            # Scripts e ferramentas
            '10-tools-utilities/': [
                '*.py', '*.ps1', '*.sh', '*.bat'
            ],
            
            # Configurações Docker e Kubernetes
            '06-deployment/': [
                'docker-compose*.yml', 'Dockerfile*', 'kubernetes/', '*.yaml', '*.yml'
            ],
            
            # Arquivos de teste e relatórios
            '07-testing/': [
                '*test*.py', '*Test*.java', 'performance*.py', 'performance-test*.py',
                '*.json', 'prometheus-*.txt', '*report*.json', '*chart*.png'
            ],
            
            # Configurações e requirements
            '08-configuration/': [
                'requirements.txt', '*.properties', '*.config', '*.conf'
            ]
        }
    
    def organize_workspace(self):
        """Organiza todo o workspace movendo arquivos para suas camadas"""
        print("🔄 Starting final workspace organization...")
        
        # Criar estrutura de camadas se não existir
        self.create_layer_structure()
        
        # Mover arquivos para suas respectivas camadas
        self.move_files_to_layers()
        
        # Criar índice de arquivos organizados
        self.create_organization_index()
        
        print("✅ Workspace organization completed!")
        return self.generate_summary()
    
    def create_layer_structure(self):
        """Cria a estrutura completa de camadas"""
        layers = [
            "01-presentation-layer",
            "02-application-layer", 
            "03-domain-layer",
            "04-infrastructure-layer",
            "05-microservices",
            "06-deployment",
            "07-testing", 
            "08-configuration",
            "09-documentation",
            "10-tools-utilities"
        ]
        
        for layer in layers:
            layer_path = self.workspace_path / layer
            layer_path.mkdir(exist_ok=True)
            
            # Criar subdiretórios específicos
            if layer == "07-testing":
                (layer_path / "unit").mkdir(exist_ok=True)
                (layer_path / "integration").mkdir(exist_ok=True)
                (layer_path / "performance").mkdir(exist_ok=True)
                (layer_path / "reports").mkdir(exist_ok=True)
                
            elif layer == "09-documentation":
                (layer_path / "architecture").mkdir(exist_ok=True)
                (layer_path / "api").mkdir(exist_ok=True)
                (layer_path / "deployment").mkdir(exist_ok=True)
                (layer_path / "performance").mkdir(exist_ok=True)
                
            elif layer == "10-tools-utilities":
                (layer_path / "scripts").mkdir(exist_ok=True)
                (layer_path / "automation").mkdir(exist_ok=True)
                (layer_path / "monitoring").mkdir(exist_ok=True)
    
    def move_files_to_layers(self):
        """Move arquivos para suas respectivas camadas"""
        
        # Listar todos os arquivos no diretório raiz
        root_files = [f for f in self.workspace_path.iterdir() 
                     if f.is_file() and not f.name.startswith('.')]
        
        for file_path in root_files:
            target_layer = self.determine_target_layer(file_path)
            if target_layer:
                self.move_file_to_layer(file_path, target_layer)
        
        # Organizar arquivos específicos
        self.organize_specific_files()
    
    def determine_target_layer(self, file_path: Path) -> str:
        """Determina a camada de destino para um arquivo"""
        file_name = file_path.name.lower()
        
        # Documentação
        if any(pattern in file_name for pattern in ['.md', 'readme', 'license']):
            if any(word in file_name for word in ['architecture', 'workflow', 'deployment']):
                return '09-documentation/architecture'
            elif any(word in file_name for word in ['test', 'performance', 'relatorio']):
                return '09-documentation/performance'
            else:
                return '09-documentation'
        
        # Scripts e ferramentas
        if file_path.suffix in ['.py', '.ps1', '.sh', '.bat']:
            if any(word in file_name for word in ['test', 'performance']):
                return '07-testing/performance'
            elif any(word in file_name for word in ['setup', 'build', 'deploy']):
                return '10-tools-utilities/automation'
            else:
                return '10-tools-utilities/scripts'
        
        # Docker e deployment
        if any(pattern in file_name for pattern in ['docker-compose', 'dockerfile']):
            return '06-deployment'
        
        # Testes e relatórios
        if any(pattern in file_name for pattern in ['test', 'performance', 'report']):
            if file_path.suffix in ['.json', '.png', '.txt']:
                return '07-testing/reports'
            else:
                return '07-testing'
        
        # Configurações
        if file_path.suffix in ['.properties', '.config', '.conf', '.txt']:
            if file_name == 'requirements.txt':
                return '08-configuration'
        
        return None
    
    def move_file_to_layer(self, source: Path, target_layer: str):
        """Move um arquivo para a camada especificada"""
        try:
            target_dir = self.workspace_path / target_layer
            target_dir.mkdir(parents=True, exist_ok=True)
            
            target_file = target_dir / source.name
            
            # Evitar sobrescrever arquivos existentes
            if target_file.exists():
                counter = 1
                name_stem = source.stem
                suffix = source.suffix
                while target_file.exists():
                    new_name = f"{name_stem}_{counter}{suffix}"
                    target_file = target_dir / new_name
                    counter += 1
            
            shutil.move(str(source), str(target_file))
            self.moved_files.append((str(source), str(target_file)))
            
            print(f"✅ Moved: {source.name} → {target_layer}")
            
        except Exception as e:
            print(f"❌ Error moving {source.name}: {e}")
    
    def organize_specific_files(self):
        """Organiza arquivos específicos conhecidos"""
        
        # Mover microserviços se ainda estão no root
        microservices_dir = self.workspace_path / "microservices"
        if microservices_dir.exists():
            target_dir = self.workspace_path / "05-microservices"
            if not (target_dir / "microservices").exists():
                shutil.move(str(microservices_dir), str(target_dir / "microservices"))
                print("✅ Moved: microservices/ → 05-microservices/")
        
        # Mover docker directory se existir
        docker_dir = self.workspace_path / "docker"
        if docker_dir.exists():
            target_dir = self.workspace_path / "06-deployment" / "docker"
            if not target_dir.exists():
                shutil.move(str(docker_dir), str(target_dir))
                print("✅ Moved: docker/ → 06-deployment/")
        
        # Mover kubernetes directory se existir
        k8s_dir = self.workspace_path / "kubernetes"
        if k8s_dir.exists():
            target_dir = self.workspace_path / "06-deployment" / "kubernetes"
            if not target_dir.exists():
                shutil.move(str(k8s_dir), str(target_dir))
                print("✅ Moved: kubernetes/ → 06-deployment/")
        
        # Mover scripts directory se existir
        scripts_dir = self.workspace_path / "scripts"
        if scripts_dir.exists():
            target_dir = self.workspace_path / "10-tools-utilities" / "scripts"
            if not target_dir.exists():
                shutil.move(str(scripts_dir), str(target_dir))
                print("✅ Moved: scripts/ → 10-tools-utilities/")
    
    def create_organization_index(self):
        """Cria um índice de arquivos organizados"""
        index = {
            'organized_at': str(Path.cwd()),
            'total_moved_files': len(self.moved_files),
            'layers': {},
            'moved_files': self.moved_files
        }
        
        # Contar arquivos por camada
        for layer in range(1, 11):
            layer_name = f"{layer:02d}-*"
            layer_dirs = list(self.workspace_path.glob(layer_name))
            
            for layer_dir in layer_dirs:
                if layer_dir.is_dir():
                    files = list(layer_dir.rglob("*"))
                    files = [f for f in files if f.is_file()]
                    
                    index['layers'][layer_dir.name] = {
                        'file_count': len(files),
                        'subdirectories': [d.name for d in layer_dir.iterdir() if d.is_dir()],
                        'main_files': [f.name for f in files[:10]]  # Primeiros 10 arquivos
                    }
        
        # Salvar índice
        index_file = self.workspace_path / "workspace_organization_index.json"
        with open(index_file, 'w', encoding='utf-8') as f:
            json.dump(index, f, indent=2, ensure_ascii=False)
        
        print(f"📋 Organization index saved: {index_file}")
    
    def generate_summary(self) -> Dict:
        """Gera resumo da organização"""
        summary = {
            'status': 'completed',
            'moved_files_count': len(self.moved_files),
            'created_layers': 10,
            'workspace_structure': {}
        }
        
        # Verificar estrutura criada
        for layer in range(1, 11):
            layer_pattern = f"{layer:02d}-*"
            layer_dirs = list(self.workspace_path.glob(layer_pattern))
            
            if layer_dirs:
                layer_dir = layer_dirs[0]
                files = list(layer_dir.rglob("*"))
                files = [f for f in files if f.is_file()]
                
                summary['workspace_structure'][layer_dir.name] = {
                    'exists': True,
                    'file_count': len(files),
                    'has_readme': (layer_dir / 'README.md').exists()
                }
        
        return summary

def main():
    """Função principal"""
    workspace_path = "C:/workspace/estudosKBNT_Kafka_Logs"
    
    print("🏗️ KBNT Kafka Logs - Final Workspace Organization")
    print("=" * 60)
    
    organizer = WorkspaceOrganizer(workspace_path)
    summary = organizer.organize_workspace()
    
    # Exibir resumo
    print("\n" + "=" * 60)
    print("📊 ORGANIZATION SUMMARY")
    print("=" * 60)
    print(f"Files moved: {summary['moved_files_count']}")
    print(f"Layers created: {summary['created_layers']}")
    
    print("\n🏗️ Layer Structure:")
    for layer_name, info in summary['workspace_structure'].items():
        status = "✅" if info['exists'] else "❌"
        readme = "📖" if info['has_readme'] else "❓"
        print(f"{status} {readme} {layer_name}: {info['file_count']} files")
    
    print(f"\n📄 Full report: workspace_organization_index.json")
    print("🎉 Workspace refactoring completed successfully!")

if __name__ == "__main__":
    main()
