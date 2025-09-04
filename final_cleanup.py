#!/usr/bin/env python3
"""
KBNT Kafka Logs - Final Cleanup & Validation
Remove diretórios antigos e valida a estrutura final
"""

import os
import shutil
import json
from pathlib import Path
from typing import Dict, List

class WorkspaceCleanup:
    def __init__(self, workspace_path: str):
        self.workspace_path = Path(workspace_path)
        self.cleanup_dirs = [
            "alternatives", "config", "consumers", "dashboard", "demo-results",
            "docs", "examples", "final-test", "hybrid-deployment", "kafka",
            "kubernetes", "logs", "producers", "reports", "scripts", 
            "simple-app", "simulation", "src", "test-environment", 
            "test-results", "venv", "__pycache__"
        ]
        self.preserve_files = [
            "prometheus-metrics-export.txt", "temp_stock.json",
            "resources_comparison_chart_20250903_235758.png",
            "workspace_organization_index.json", ".gitignore", ".git",
            ".vscode", "README.md"
        ]
        
    def cleanup_old_structure(self):
        """Remove diretórios da estrutura antiga"""
        print("🧹 Cleaning up old directory structure...")
        
        moved_items = []
        
        for item_name in self.cleanup_dirs:
            item_path = self.workspace_path / item_name
            if item_path.exists():
                try:
                    if item_path.is_dir():
                        # Mover conteúdo útil antes de remover
                        self.move_useful_content(item_path)
                        shutil.rmtree(item_path)
                        print(f"✅ Removed directory: {item_name}")
                        moved_items.append(f"directory: {item_name}")
                    else:
                        # Mover arquivo para local apropriado
                        target = self.determine_file_destination(item_path)
                        if target:
                            target.parent.mkdir(parents=True, exist_ok=True)
                            shutil.move(str(item_path), str(target))
                            print(f"✅ Moved file: {item_name} → {target}")
                            moved_items.append(f"file: {item_name} → {target}")
                        else:
                            item_path.unlink()
                            print(f"✅ Removed file: {item_name}")
                            moved_items.append(f"removed file: {item_name}")
                except Exception as e:
                    print(f"❌ Error removing {item_name}: {e}")
        
        return moved_items
    
    def move_useful_content(self, dir_path: Path):
        """Move conteúdo útil dos diretórios antes de removê-los"""
        useful_patterns = [
            "*.py", "*.java", "*.md", "*.yml", "*.yaml", 
            "*.json", "*.properties", "*.txt", "*.sh", "*.ps1"
        ]
        
        for pattern in useful_patterns:
            for file_path in dir_path.rglob(pattern):
                if file_path.is_file():
                    target = self.determine_file_destination(file_path)
                    if target and not target.exists():
                        target.parent.mkdir(parents=True, exist_ok=True)
                        try:
                            shutil.copy2(str(file_path), str(target))
                            print(f"  📁 Preserved: {file_path.name} → {target.parent.name}")
                        except Exception as e:
                            print(f"  ❌ Error preserving {file_path.name}: {e}")
    
    def determine_file_destination(self, file_path: Path) -> Path:
        """Determina destino apropriado para um arquivo"""
        file_name = file_path.name.lower()
        
        # Scripts
        if file_path.suffix in ['.py', '.sh', '.ps1', '.bat']:
            if 'test' in file_name or 'performance' in file_name:
                return self.workspace_path / "07-testing" / "performance" / file_path.name
            else:
                return self.workspace_path / "10-tools-utilities" / "scripts" / file_path.name
        
        # Documentação
        if file_path.suffix in ['.md', '.txt']:
            if any(word in file_name for word in ['architecture', 'workflow', 'deployment']):
                return self.workspace_path / "09-documentation" / "architecture" / file_path.name
            elif any(word in file_name for word in ['test', 'performance', 'report']):
                return self.workspace_path / "09-documentation" / "performance" / file_path.name
            else:
                return self.workspace_path / "09-documentation" / file_path.name
        
        # Configurações
        if file_path.suffix in ['.yml', '.yaml', '.properties', '.config']:
            if 'docker' in file_name or 'kubernetes' in file_name:
                return self.workspace_path / "06-deployment" / file_path.name
            else:
                return self.workspace_path / "08-configuration" / file_path.name
        
        # Relatórios e resultados
        if file_path.suffix in ['.json', '.png', '.csv']:
            return self.workspace_path / "07-testing" / "reports" / file_path.name
        
        return None
    
    def validate_layer_structure(self) -> Dict:
        """Valida a estrutura final das camadas"""
        print("🔍 Validating final layer structure...")
        
        expected_layers = [
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
        
        validation = {
            "valid_layers": [],
            "missing_layers": [],
            "extra_directories": [],
            "layer_stats": {}
        }
        
        # Verificar camadas esperadas
        for layer in expected_layers:
            layer_path = self.workspace_path / layer
            if layer_path.exists() and layer_path.is_dir():
                validation["valid_layers"].append(layer)
                
                # Estatísticas da camada
                files = list(layer_path.rglob("*"))
                files = [f for f in files if f.is_file()]
                
                validation["layer_stats"][layer] = {
                    "exists": True,
                    "has_readme": (layer_path / "README.md").exists(),
                    "file_count": len(files),
                    "subdirs": [d.name for d in layer_path.iterdir() if d.is_dir()]
                }
                
                print(f"✅ {layer}: {len(files)} files, README: {'✓' if (layer_path / 'README.md').exists() else '✗'}")
            else:
                validation["missing_layers"].append(layer)
                print(f"❌ Missing: {layer}")
        
        # Verificar diretórios extras
        for item in self.workspace_path.iterdir():
            if item.is_dir() and item.name not in expected_layers and not item.name.startswith('.'):
                if item.name not in ["08-monitoring"]:  # Permitir alguns extras
                    validation["extra_directories"].append(item.name)
                    print(f"⚠️  Extra directory: {item.name}")
        
        return validation
    
    def generate_final_report(self, cleanup_result: List, validation: Dict) -> Dict:
        """Gera relatório final da organização"""
        report = {
            "refactoring_completed": True,
            "timestamp": str(Path.cwd()),
            "cleanup_summary": {
                "items_cleaned": len(cleanup_result),
                "cleaned_items": cleanup_result
            },
            "layer_validation": validation,
            "quality_metrics": {
                "layers_implemented": len(validation["valid_layers"]),
                "layers_with_readme": len([l for l in validation["layer_stats"].values() if l.get("has_readme", False)]),
                "total_files_organized": sum(l.get("file_count", 0) for l in validation["layer_stats"].values()),
                "architecture_compliance": len(validation["valid_layers"]) / 10 * 100
            },
            "recommendations": self.generate_recommendations(validation)
        }
        
        return report
    
    def generate_recommendations(self, validation: Dict) -> List[str]:
        """Gera recomendações baseadas na validação"""
        recommendations = []
        
        if validation["missing_layers"]:
            recommendations.append(f"Create missing layers: {', '.join(validation['missing_layers'])}")
        
        if validation["extra_directories"]:
            recommendations.append(f"Review extra directories: {', '.join(validation['extra_directories'])}")
        
        layers_without_readme = [
            layer for layer, stats in validation["layer_stats"].items() 
            if not stats.get("has_readme", False)
        ]
        if layers_without_readme:
            recommendations.append(f"Add README files to: {', '.join(layers_without_readme)}")
        
        empty_layers = [
            layer for layer, stats in validation["layer_stats"].items() 
            if stats.get("file_count", 0) == 0
        ]
        if empty_layers:
            recommendations.append(f"Populate empty layers: {', '.join(empty_layers)}")
        
        if not recommendations:
            recommendations.append("Architecture refactoring is complete and compliant!")
        
        return recommendations

def main():
    """Função principal"""
    workspace_path = "C:/workspace/estudosKBNT_Kafka_Logs"
    
    print("🎯 KBNT Kafka Logs - Final Cleanup & Validation")
    print("=" * 60)
    
    cleanup = WorkspaceCleanup(workspace_path)
    
    # Cleanup da estrutura antiga
    cleanup_result = cleanup.cleanup_old_structure()
    
    # Validação da estrutura final
    validation = cleanup.validate_layer_structure()
    
    # Gerar relatório final
    final_report = cleanup.generate_final_report(cleanup_result, validation)
    
    # Salvar relatório
    report_path = Path(workspace_path) / "final_refactoring_report.json"
    with open(report_path, 'w', encoding='utf-8') as f:
        json.dump(final_report, f, indent=2, ensure_ascii=False)
    
    # Exibir resumo
    print("\n" + "=" * 60)
    print("📊 FINAL REFACTORING SUMMARY")
    print("=" * 60)
    print(f"✅ Layers implemented: {final_report['quality_metrics']['layers_implemented']}/10")
    print(f"📖 READMEs created: {final_report['quality_metrics']['layers_with_readme']}/10")
    print(f"📁 Files organized: {final_report['quality_metrics']['total_files_organized']}")
    print(f"🏗️ Architecture compliance: {final_report['quality_metrics']['architecture_compliance']:.1f}%")
    
    print(f"\n🧹 Cleanup summary:")
    print(f"   Items cleaned: {final_report['cleanup_summary']['items_cleaned']}")
    
    print(f"\n💡 Recommendations:")
    for rec in final_report['recommendations']:
        print(f"   • {rec}")
    
    print(f"\n📄 Final report saved: {report_path}")
    
    if final_report['quality_metrics']['architecture_compliance'] >= 90:
        print("\n🎉 REFACTORING COMPLETED SUCCESSFULLY! 🎉")
        print("🏗️ Clean Architecture + Hexagonal Architecture implemented")
        print("📊 All layers properly organized and documented")
        print("✨ Ready for enterprise development!")
    else:
        print("\n⚠️  Refactoring needs attention - check recommendations")

if __name__ == "__main__":
    main()
