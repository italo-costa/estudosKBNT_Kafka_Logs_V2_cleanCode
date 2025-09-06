#!/usr/bin/env python3
"""
Analisador Comparativo de Branches - WSL Linux Edition
Compara estruturas das branches master vs refactoring-clean-architecture-v2.1
EXECUÇÃO EXCLUSIVA NO AMBIENTE WSL LINUX
"""

import json
import subprocess
from pathlib import Path
from datetime import datetime
from collections import defaultdict

class WSLBranchComparator:
    def __init__(self, workspace_root):
        self.workspace_root = Path(workspace_root)
        self.wsl_distro = "Ubuntu"
        self.comparison_results = {
            "timestamp": datetime.now().isoformat(),
            "branches": {
                "master": "origin/master",
                "refactoring": "refactoring-clean-architecture-v2.1"
            },
            "analysis": {},
            "recommendations": [],
            "execution_environment": "WSL Ubuntu Linux"
        }
        
    def convert_windows_path_to_wsl(self, windows_path):
        """Converte caminho Windows para WSL"""
        windows_path = str(windows_path)
        if windows_path.startswith('C:'):
            wsl_path = windows_path.replace('C:', '/mnt/c').replace('\\', '/')
        else:
            wsl_path = windows_path.replace('\\', '/')
        return wsl_path
        
    def execute_wsl_git_command(self, git_command):
        """Executa comando git no WSL Linux"""
        try:
            # Converter caminho para WSL
            wsl_workspace = self.convert_windows_path_to_wsl(self.workspace_root)
            
            # Comando completo para WSL
            full_command = ["wsl", "-d", self.wsl_distro, "bash", "-c", 
                          f"cd {wsl_workspace} && {git_command}"]
            
            print(f"🐧 Executando no WSL: {git_command}")
            
            result = subprocess.run(
                full_command,
                capture_output=True,
                text=True,
                shell=True
            )
            
            return {
                "success": result.returncode == 0,
                "stdout": result.stdout,
                "stderr": result.stderr,
                "returncode": result.returncode
            }
            
        except Exception as e:
            print(f"❌ Erro ao executar comando WSL: {e}")
            return {
                "success": False,
                "stdout": "",
                "stderr": str(e),
                "returncode": -1
            }
    
    def validate_wsl_git_environment(self):
        """Valida se Git está disponível no WSL"""
        print("🔧 Validando ambiente Git no WSL...")
        
        git_version = self.execute_wsl_git_command("/usr/bin/git --version")
        if not git_version["success"]:
            print("❌ Git não está disponível no WSL")
            return False
        
        print(f"✅ Git detectado: {git_version['stdout'].strip()}")
        
        # Verificar se estamos em um repositório Git
        git_status = self.execute_wsl_git_command("/usr/bin/git status --porcelain")
        if not git_status["success"]:
            print("❌ Não é um repositório Git válido")
            return False
        
        print("✅ Repositório Git válido detectado")
        return True
    
    def analyze_file_organization(self):
        """Analisa organização dos arquivos entre as branches"""
        print("🔍 Analisando organização de arquivos no WSL...")
        
        # Executar git diff no WSL
        git_diff = self.execute_wsl_git_command("/usr/bin/git diff master --name-status")
        
        if not git_diff["success"]:
            print(f"❌ Erro ao executar git diff: {git_diff['stderr']}")
            return {}
        
        changes = git_diff["stdout"].strip().split('\n') if git_diff["stdout"].strip() else []
        
        # Categorizar mudanças
        file_categories = {
            "added": [],
            "modified": [],
            "renamed": [],
            "deleted": [],
            "moved_to_layers": defaultdict(list)
        }
        
        clean_architecture_layers = [
            "01-presentation-layer",
            "02-application-layer", 
            "03-domain-layer",
            "04-infrastructure-layer",
            "05-microservices",
            "06-deployment",
            "07-testing",
            "08-configuration",
            "09-monitoring",
            "10-tools-utilities"
        ]
        
        for change in changes:
            if not change.strip():
                continue
                
            parts = change.split('\t')
            status = parts[0]
            
            if status.startswith('A'):  # Added
                filename = parts[1]
                file_categories["added"].append(filename)
                
                # Verificar se foi movido para camada da Clean Architecture
                for layer in clean_architecture_layers:
                    if filename.startswith(layer):
                        file_categories["moved_to_layers"][layer].append(filename)
                        break
                        
            elif status.startswith('M'):  # Modified
                filename = parts[1]
                file_categories["modified"].append(filename)
                
            elif status.startswith('R'):  # Renamed/Moved
                old_name = parts[1]
                new_name = parts[2] if len(parts) > 2 else parts[1]
                file_categories["renamed"].append({
                    "from": old_name,
                    "to": new_name
                })
                
                # Verificar se foi movido para camada
                for layer in clean_architecture_layers:
                    if new_name.startswith(layer):
                        file_categories["moved_to_layers"][layer].append({
                            "from": old_name,
                            "to": new_name
                        })
                        break
                        
            elif status.startswith('D'):  # Deleted
                filename = parts[1]
                file_categories["deleted"].append(filename)
        
        # Estatísticas
        stats = {
            "total_changes": len(changes),
            "files_added": len(file_categories["added"]),
            "files_modified": len(file_categories["modified"]),
            "files_renamed": len(file_categories["renamed"]),
            "files_deleted": len(file_categories["deleted"]),
            "files_moved_to_layers": sum(len(files) for files in file_categories["moved_to_layers"].values()),
            "layers_with_new_files": len(file_categories["moved_to_layers"])
        }
        
        print(f"📊 Estatísticas de mudanças:")
        print(f"   • Total de mudanças: {stats['total_changes']}")
        print(f"   • Arquivos adicionados: {stats['files_added']}")
        print(f"   • Arquivos modificados: {stats['files_modified']}")
        print(f"   • Arquivos renomeados: {stats['files_renamed']}")
        print(f"   • Arquivos deletados: {stats['files_deleted']}")
        print(f"   • Movidos para camadas: {stats['files_moved_to_layers']}")
        print(f"   • Camadas afetadas: {stats['layers_with_new_files']}")
        
        return {
            "file_categories": dict(file_categories),
            "statistics": stats,
            "clean_architecture_layers": list(file_categories["moved_to_layers"].keys())
        }
    
    def analyze_clean_architecture_compliance(self):
        """Analisa conformidade com Clean Architecture"""
        print("🏗️ Analisando conformidade com Clean Architecture...")
        
        # Verificar estrutura de diretórios na branch atual
        ls_result = self.execute_wsl_git_command("find . -maxdepth 1 -type d -name '*-*' | sort")
        
        if not ls_result["success"]:
            print("❌ Erro ao listar diretórios")
            return {}
        
        current_layers = [
            line.strip().replace('./', '') 
            for line in ls_result["stdout"].split('\n') 
            if line.strip() and '-layer' in line
        ]
        
        expected_layers = [
            "01-presentation-layer",
            "02-application-layer",
            "03-domain-layer", 
            "04-infrastructure-layer",
            "05-microservices",
            "06-deployment",
            "07-testing",
            "08-configuration",
            "09-monitoring",
            "10-tools-utilities"
        ]
        
        compliance_analysis = {
            "expected_layers": expected_layers,
            "current_layers": current_layers,
            "missing_layers": [layer for layer in expected_layers if layer not in current_layers],
            "extra_layers": [layer for layer in current_layers if layer not in expected_layers],
            "compliance_score": len(current_layers) / len(expected_layers) * 100
        }
        
        print(f"✅ Camadas presentes: {len(current_layers)}/{len(expected_layers)}")
        print(f"📈 Score de conformidade: {compliance_analysis['compliance_score']:.1f}%")
        
        if compliance_analysis["missing_layers"]:
            print(f"⚠️ Camadas faltantes: {compliance_analysis['missing_layers']}")
        
        return compliance_analysis
    
    def analyze_testing_structure(self):
        """Analisa estrutura de testes"""
        print("🧪 Analisando estrutura de testes...")
        
        # Buscar arquivos de teste
        test_search = self.execute_wsl_git_command(
            "find . -name '*test*' -o -name '*Test*' -o -name '*spec*' | grep -E '\\.(java|py|js|ts)$' | head -20"
        )
        
        if test_search["success"]:
            test_files = [f.strip() for f in test_search["stdout"].split('\n') if f.strip()]
        else:
            test_files = []
        
        # Categorizar testes por tipo
        test_categories = {
            "unit_tests": [],
            "integration_tests": [],
            "e2e_tests": [],
            "performance_tests": []
        }
        
        for test_file in test_files:
            if 'unit' in test_file.lower():
                test_categories["unit_tests"].append(test_file)
            elif 'integration' in test_file.lower():
                test_categories["integration_tests"].append(test_file)
            elif 'e2e' in test_file.lower() or 'end-to-end' in test_file.lower():
                test_categories["e2e_tests"].append(test_file)
            elif 'performance' in test_file.lower() or 'stress' in test_file.lower():
                test_categories["performance_tests"].append(test_file)
        
        testing_analysis = {
            "total_test_files": len(test_files),
            "test_categories": dict(test_categories),
            "has_testing_layer": "07-testing" in self.execute_wsl_git_command("ls -la").get("stdout", ""),
            "testing_coverage": {
                "unit": len(test_categories["unit_tests"]),
                "integration": len(test_categories["integration_tests"]),
                "e2e": len(test_categories["e2e_tests"]),
                "performance": len(test_categories["performance_tests"])
            }
        }
        
        print(f"📊 Arquivos de teste encontrados: {testing_analysis['total_test_files']}")
        print(f"📋 Distribuição: Unit={testing_analysis['testing_coverage']['unit']}, "
              f"Integration={testing_analysis['testing_coverage']['integration']}, "
              f"E2E={testing_analysis['testing_coverage']['e2e']}, "
              f"Performance={testing_analysis['testing_coverage']['performance']}")
        
        return testing_analysis
    
    def analyze_docker_configuration(self):
        """Analisa configurações Docker"""
        print("🐳 Analisando configurações Docker...")
        
        # Buscar arquivos Docker
        docker_search = self.execute_wsl_git_command(
            "find . -name 'docker-compose*.yml' -o -name 'Dockerfile*' | head -20"
        )
        
        if docker_search["success"]:
            docker_files = [f.strip() for f in docker_search["stdout"].split('\n') if f.strip()]
        else:
            docker_files = []
        
        # Categorizar arquivos Docker
        docker_analysis = {
            "total_docker_files": len(docker_files),
            "docker_compose_files": [f for f in docker_files if 'docker-compose' in f],
            "dockerfiles": [f for f in docker_files if 'Dockerfile' in f],
            "has_infrastructure_layer": "04-infrastructure-layer" in self.execute_wsl_git_command("ls -la").get("stdout", ""),
            "has_deployment_layer": "06-deployment" in self.execute_wsl_git_command("ls -la").get("stdout", "")
        }
        
        print(f"🐳 Arquivos Docker encontrados: {docker_analysis['total_docker_files']}")
        print(f"📋 Compose files: {len(docker_analysis['docker_compose_files'])}")
        print(f"📋 Dockerfiles: {len(docker_analysis['dockerfiles'])}")
        
        return docker_analysis
    
    def generate_recommendations(self, file_org, clean_arch, testing, docker):
        """Gera recomendações baseadas na análise"""
        print("💡 Gerando recomendações...")
        
        recommendations = []
        
        # Recomendações sobre Clean Architecture
        if clean_arch["compliance_score"] >= 90:
            recommendations.append({
                "category": "Clean Architecture",
                "priority": "HIGH",
                "recommendation": "Excelente conformidade com Clean Architecture. Estrutura bem organizada.",
                "reason": f"Score de conformidade: {clean_arch['compliance_score']:.1f}%"
            })
        elif clean_arch["compliance_score"] >= 70:
            recommendations.append({
                "category": "Clean Architecture", 
                "priority": "MEDIUM",
                "recommendation": "Boa estrutura, mas pode ser melhorada.",
                "reason": f"Score de conformidade: {clean_arch['compliance_score']:.1f}%"
            })
        else:
            recommendations.append({
                "category": "Clean Architecture",
                "priority": "HIGH",
                "recommendation": "Estrutura precisa de melhorias significativas.",
                "reason": f"Score baixo: {clean_arch['compliance_score']:.1f}%"
            })
        
        # Recomendações sobre organização de arquivos
        if file_org["statistics"]["files_moved_to_layers"] > 50:
            recommendations.append({
                "category": "File Organization",
                "priority": "HIGH",
                "recommendation": "Excelente reorganização de arquivos em camadas apropriadas.",
                "reason": f"{file_org['statistics']['files_moved_to_layers']} arquivos organizados em camadas"
            })
        
        # Recomendações sobre testes
        if testing["total_test_files"] > 20:
            recommendations.append({
                "category": "Testing",
                "priority": "HIGH", 
                "recommendation": "Boa cobertura de testes implementada.",
                "reason": f"{testing['total_test_files']} arquivos de teste encontrados"
            })
        elif testing["total_test_files"] > 5:
            recommendations.append({
                "category": "Testing",
                "priority": "MEDIUM",
                "recommendation": "Estrutura de testes básica presente, pode ser expandida.",
                "reason": f"{testing['total_test_files']} arquivos de teste"
            })
        else:
            recommendations.append({
                "category": "Testing",
                "priority": "HIGH",
                "recommendation": "Estrutura de testes precisa ser implementada.",
                "reason": f"Apenas {testing['total_test_files']} arquivos de teste"
            })
        
        # Recomendações sobre Docker
        if docker["total_docker_files"] > 10:
            recommendations.append({
                "category": "Docker/Deployment",
                "priority": "HIGH",
                "recommendation": "Excelente configuração de containerização.",
                "reason": f"{docker['total_docker_files']} arquivos Docker configurados"
            })
        
        # Recomendação final sobre qual branch usar
        high_priority_positives = len([r for r in recommendations if r["priority"] == "HIGH" and "Excelente" in r["recommendation"]])
        
        if high_priority_positives >= 3:
            recommendations.append({
                "category": "Branch Selection",
                "priority": "CRITICAL",
                "recommendation": "USAR BRANCH REFACTORING - Estrutura superior em todos os aspectos.",
                "reason": f"{high_priority_positives} melhorias críticas implementadas"
            })
        elif high_priority_positives >= 2:
            recommendations.append({
                "category": "Branch Selection",
                "priority": "HIGH",
                "recommendation": "USAR BRANCH REFACTORING - Melhorias significativas implementadas.",
                "reason": f"{high_priority_positives} melhorias importantes"
            })
        else:
            recommendations.append({
                "category": "Branch Selection",
                "priority": "MEDIUM",
                "recommendation": "Avaliar cuidadosamente - algumas melhorias presentes.",
                "reason": "Melhorias parciais implementadas"
            })
        
        return recommendations
    
    def run_complete_analysis(self):
        """Executa análise completa das branches"""
        print("🚀 ANÁLISE COMPARATIVA DE BRANCHES - WSL LINUX")
        print("=" * 60)
        
        # Validar ambiente
        if not self.validate_wsl_git_environment():
            print("❌ Ambiente WSL Git não está configurado corretamente")
            return False
        
        try:
            # Executar análises
            print("\n1️⃣ Organização de Arquivos")
            file_org = self.analyze_file_organization()
            
            print("\n2️⃣ Conformidade Clean Architecture")
            clean_arch = self.analyze_clean_architecture_compliance()
            
            print("\n3️⃣ Estrutura de Testes")
            testing = self.analyze_testing_structure()
            
            print("\n4️⃣ Configuração Docker")
            docker = self.analyze_docker_configuration()
            
            print("\n5️⃣ Recomendações")
            recommendations = self.generate_recommendations(file_org, clean_arch, testing, docker)
            
            # Salvar resultados
            self.comparison_results["analysis"] = {
                "file_organization": file_org,
                "clean_architecture": clean_arch,
                "testing_structure": testing,
                "docker_configuration": docker
            }
            self.comparison_results["recommendations"] = recommendations
            
            # Exibir relatório
            self.display_final_report()
            
            # Salvar em arquivo
            self.save_results()
            
            return True
            
        except Exception as e:
            print(f"❌ Erro durante análise: {e}")
            return False
    
    def display_final_report(self):
        """Exibe relatório final"""
        print("\n" + "=" * 60)
        print("📊 RELATÓRIO FINAL - COMPARAÇÃO DE BRANCHES")
        print("=" * 60)
        
        # Resumo de mudanças
        file_stats = self.comparison_results["analysis"]["file_organization"]["statistics"]
        print(f"\n📈 RESUMO DE MUDANÇAS:")
        print(f"   • Total de mudanças: {file_stats['total_changes']}")
        print(f"   • Arquivos organizados em camadas: {file_stats['files_moved_to_layers']}")
        print(f"   • Camadas Clean Architecture: {file_stats['layers_with_new_files']}")
        
        # Score Clean Architecture
        clean_score = self.comparison_results["analysis"]["clean_architecture"]["compliance_score"]
        print(f"\n🏗️ CLEAN ARCHITECTURE:")
        print(f"   • Score de conformidade: {clean_score:.1f}%")
        
        # Estrutura de testes
        test_count = self.comparison_results["analysis"]["testing_structure"]["total_test_files"]
        print(f"\n🧪 ESTRUTURA DE TESTES:")
        print(f"   • Arquivos de teste: {test_count}")
        
        # Configuração Docker
        docker_count = self.comparison_results["analysis"]["docker_configuration"]["total_docker_files"]
        print(f"\n🐳 CONFIGURAÇÃO DOCKER:")
        print(f"   • Arquivos Docker: {docker_count}")
        
        # Recomendações críticas
        print(f"\n💡 RECOMENDAÇÕES PRINCIPAIS:")
        for rec in self.comparison_results["recommendations"]:
            if rec["priority"] in ["CRITICAL", "HIGH"]:
                icon = "🔴" if rec["priority"] == "CRITICAL" else "🟡"
                print(f"   {icon} {rec['category']}: {rec['recommendation']}")
        
        # Decisão final
        final_rec = next((r for r in self.comparison_results["recommendations"] if r["category"] == "Branch Selection"), None)
        if final_rec:
            print(f"\n🎯 DECISÃO FINAL:")
            print(f"   {final_rec['recommendation']}")
            print(f"   Razão: {final_rec['reason']}")
    
    def save_results(self):
        """Salva resultados em arquivo JSON"""
        output_file = self.workspace_root / "BRANCH_COMPARISON_REPORT_WSL.json"
        
        try:
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(self.comparison_results, f, indent=2, ensure_ascii=False)
            
            print(f"\n💾 Relatório salvo: {output_file}")
            
            # Também criar versão markdown
            self.save_markdown_report()
            
        except Exception as e:
            print(f"❌ Erro ao salvar relatório: {e}")
    
    def save_markdown_report(self):
        """Salva relatório em formato Markdown"""
        output_file = self.workspace_root / "BRANCH_COMPARISON_REPORT_WSL.md"
        
        content = f"""# Relatório de Comparação de Branches - WSL Linux

**Gerado em:** {self.comparison_results['timestamp']}  
**Ambiente:** {self.comparison_results['execution_environment']}  
**Branches:** master vs refactoring-clean-architecture-v2.1

## 📊 Resumo Executivo

### Estatísticas de Mudanças
- **Total de mudanças:** {self.comparison_results['analysis']['file_organization']['statistics']['total_changes']}
- **Arquivos organizados em camadas:** {self.comparison_results['analysis']['file_organization']['statistics']['files_moved_to_layers']}
- **Camadas Clean Architecture:** {self.comparison_results['analysis']['file_organization']['statistics']['layers_with_new_files']}

### Score de Conformidade
- **Clean Architecture:** {self.comparison_results['analysis']['clean_architecture']['compliance_score']:.1f}%

### Estruturas Analisadas
- **Arquivos de teste:** {self.comparison_results['analysis']['testing_structure']['total_test_files']}
- **Arquivos Docker:** {self.comparison_results['analysis']['docker_configuration']['total_docker_files']}

## 💡 Recomendações

"""
        
        for rec in self.comparison_results["recommendations"]:
            priority_icon = {"CRITICAL": "🔴", "HIGH": "🟡", "MEDIUM": "🟠", "LOW": "🟢"}.get(rec["priority"], "⚪")
            content += f"### {priority_icon} {rec['category']} ({rec['priority']})\n"
            content += f"**Recomendação:** {rec['recommendation']}\n\n"
            content += f"**Justificativa:** {rec['reason']}\n\n"
        
        content += f"""
## 🎯 Conclusão

{next((r['recommendation'] for r in self.comparison_results['recommendations'] if r['category'] == 'Branch Selection'), 'Análise inconclusiva')}

---
*Relatório gerado automaticamente pelo WSL Branch Comparator*
"""
        
        try:
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(content)
            
            print(f"📄 Relatório Markdown salvo: {output_file}")
            
        except Exception as e:
            print(f"❌ Erro ao salvar Markdown: {e}")

def main():
    """Função principal"""
    workspace_root = Path(__file__).parent.parent.parent
    comparator = WSLBranchComparator(workspace_root)
    
    print("🐧 WSL BRANCH COMPARATOR - CLEAN ARCHITECTURE")
    print("Execução exclusiva no ambiente WSL Linux")
    print("=" * 55)
    
    success = comparator.run_complete_analysis()
    return 0 if success else 1

if __name__ == "__main__":
    exit(main())
