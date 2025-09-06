#!/usr/bin/env python3
"""
Análise Comparativa Detalhada de Arquiteturas
Compara branch master vs refactoring-clean-architecture-v2.1
Execução no WSL Linux
"""

import subprocess
import json
import os
from datetime import datetime
from pathlib import Path

class ArchitectureComparator:
    def __init__(self):
        self.workspace = "/mnt/c/workspace/estudosKBNT_Kafka_Logs"
        self.analysis_results = {
            "timestamp": datetime.now().isoformat(),
            "environment": "WSL Ubuntu Linux",
            "branches": {
                "master": {},
                "refactoring": {}
            },
            "comparison": {},
            "recommendation": ""
        }
    
    def run_command(self, command):
        """Executa comando no WSL"""
        try:
            result = subprocess.run(
                command,
                shell=True,
                capture_output=True,
                text=True,
                cwd=self.workspace
            )
            
            return {
                "success": result.returncode == 0,
                "stdout": result.stdout,
                "stderr": result.stderr,
                "returncode": result.returncode
            }
        except Exception as e:
            return {
                "success": False,
                "stdout": "",
                "stderr": str(e),
                "returncode": -1
            }
    
    def analyze_branch_structure(self, branch_name):
        """Analisa estrutura de uma branch específica"""
        print(f"🔍 Analisando branch: {branch_name}")
        
        # Checkout da branch
        checkout_result = self.run_command(f"git checkout {branch_name}")
        if not checkout_result["success"]:
            print(f"❌ Erro ao fazer checkout da branch {branch_name}")
            return {}
        
        print(f"✅ Checkout para {branch_name} realizado")
        
        analysis = {
            "branch_name": branch_name,
            "file_organization": {},
            "architecture_compliance": {},
            "code_quality": {},
            "testing_structure": {},
            "docker_configuration": {},
            "documentation": {},
            "maintainability": {}
        }
        
        # 1. Análise de organização de arquivos
        print("📁 Analisando organização de arquivos...")
        analysis["file_organization"] = self.analyze_file_organization()
        
        # 2. Análise de conformidade arquitetural
        print("🏗️ Analisando conformidade arquitetural...")
        analysis["architecture_compliance"] = self.analyze_architecture_compliance()
        
        # 3. Análise de qualidade de código
        print("⚙️ Analisando qualidade de código...")
        analysis["code_quality"] = self.analyze_code_quality()
        
        # 4. Análise de estrutura de testes
        print("🧪 Analisando estrutura de testes...")
        analysis["testing_structure"] = self.analyze_testing_structure()
        
        # 5. Análise de configuração Docker
        print("🐳 Analisando configuração Docker...")
        analysis["docker_configuration"] = self.analyze_docker_configuration()
        
        # 6. Análise de documentação
        print("📚 Analisando documentação...")
        analysis["documentation"] = self.analyze_documentation()
        
        # 7. Análise de manutenibilidade
        print("🔧 Analisando manutenibilidade...")
        analysis["maintainability"] = self.analyze_maintainability()
        
        return analysis
    
    def analyze_file_organization(self):
        """Analisa organização dos arquivos"""
        
        # Contar arquivos por tipo
        file_counts = {}
        
        # Arquivos Java
        java_files = self.run_command("find . -name '*.java' | wc -l")
        file_counts["java"] = int(java_files["stdout"].strip()) if java_files["success"] else 0
        
        # Arquivos Python
        python_files = self.run_command("find . -name '*.py' | wc -l")
        file_counts["python"] = int(python_files["stdout"].strip()) if python_files["success"] else 0
        
        # Arquivos de configuração
        config_files = self.run_command("find . -name '*.yml' -o -name '*.yaml' -o -name '*.properties' | wc -l")
        file_counts["config"] = int(config_files["stdout"].strip()) if config_files["success"] else 0
        
        # Verificar estrutura de diretórios
        dirs_result = self.run_command("find . -maxdepth 2 -type d | sort")
        directories = []
        if dirs_result["success"]:
            directories = [d.strip() for d in dirs_result["stdout"].split('\n') if d.strip()]
        
        # Verificar camadas Clean Architecture
        clean_arch_layers = []
        layer_names = [
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
        
        for layer in layer_names:
            if any(layer in d for d in directories):
                clean_arch_layers.append(layer)
        
        return {
            "file_counts": file_counts,
            "total_directories": len(directories),
            "clean_architecture_layers": clean_arch_layers,
            "layer_compliance_percentage": (len(clean_arch_layers) / len(layer_names)) * 100,
            "directory_structure": directories[:20]  # Primeiros 20 diretórios
        }
    
    def analyze_architecture_compliance(self):
        """Analisa conformidade com Clean Architecture"""
        
        # Verificar separação de responsabilidades
        controllers = self.run_command("find . -name '*Controller*' | wc -l")
        services = self.run_command("find . -name '*Service*' | wc -l")
        repositories = self.run_command("find . -name '*Repository*' | wc -l")
        entities = self.run_command("find . -name '*Entity*' -o -name '*Model*' | wc -l")
        
        # Verificar presença de camadas
        has_presentation = self.run_command("find . -name '*presentation*' -o -name '*controller*' | head -1")
        has_application = self.run_command("find . -name '*application*' -o -name '*service*' | head -1")
        has_domain = self.run_command("find . -name '*domain*' -o -name '*entity*' | head -1")
        has_infrastructure = self.run_command("find . -name '*infrastructure*' -o -name '*repository*' | head -1")
        
        # Calcular score de conformidade
        compliance_indicators = 0
        total_indicators = 7
        
        if int(controllers["stdout"].strip()) > 0:
            compliance_indicators += 1
        if int(services["stdout"].strip()) > 0:
            compliance_indicators += 1
        if int(repositories["stdout"].strip()) > 0:
            compliance_indicators += 1
        if int(entities["stdout"].strip()) > 0:
            compliance_indicators += 1
        if has_presentation["success"] and has_presentation["stdout"].strip():
            compliance_indicators += 1
        if has_application["success"] and has_application["stdout"].strip():
            compliance_indicators += 1
        if has_domain["success"] and has_domain["stdout"].strip():
            compliance_indicators += 1
        
        compliance_score = (compliance_indicators / total_indicators) * 100
        
        return {
            "controllers_count": int(controllers["stdout"].strip()) if controllers["success"] else 0,
            "services_count": int(services["stdout"].strip()) if services["success"] else 0,
            "repositories_count": int(repositories["stdout"].strip()) if repositories["success"] else 0,
            "entities_count": int(entities["stdout"].strip()) if entities["success"] else 0,
            "has_layered_structure": compliance_indicators >= 4,
            "compliance_score": compliance_score,
            "architecture_pattern": "Clean Architecture" if compliance_score >= 70 else "Monolithic/Mixed"
        }
    
    def analyze_code_quality(self):
        """Analisa qualidade do código"""
        
        # Verificar duplicação
        duplicate_check = self.run_command("find . -name '*.java' -exec basename {} \\; | sort | uniq -d | wc -l")
        duplicates = int(duplicate_check["stdout"].strip()) if duplicate_check["success"] else 0
        
        # Verificar tamanho médio de arquivos
        avg_file_size = self.run_command("find . -name '*.java' -exec wc -l {} \\; | awk '{sum+=$1; count++} END {if(count>0) print sum/count; else print 0}'")
        average_lines = float(avg_file_size["stdout"].strip()) if avg_file_size["success"] and avg_file_size["stdout"].strip() else 0
        
        # Verificar complexidade (aproximada pela contagem de métodos)
        method_count = self.run_command("grep -r 'public.*(' . --include='*.java' | wc -l")
        total_methods = int(method_count["stdout"].strip()) if method_count["success"] else 0
        
        # Verificar comentários
        comment_lines = self.run_command("grep -r '//' . --include='*.java' | wc -l")
        total_comments = int(comment_lines["stdout"].strip()) if comment_lines["success"] else 0
        
        return {
            "duplicate_files": duplicates,
            "average_file_size_lines": round(average_lines, 2),
            "total_methods": total_methods,
            "comment_lines": total_comments,
            "code_quality_score": min(100, max(0, 100 - (duplicates * 10) - max(0, (average_lines - 200) / 10)))
        }
    
    def analyze_testing_structure(self):
        """Analisa estrutura de testes"""
        
        # Contar arquivos de teste
        unit_tests = self.run_command("find . -name '*Test*.java' -o -name '*test*.py' | wc -l")
        integration_tests = self.run_command("find . -name '*Integration*' -o -name '*IT.java' | wc -l")
        e2e_tests = self.run_command("find . -name '*E2E*' -o -name '*e2e*' | wc -l")
        
        # Verificar cobertura de testes (aproximada)
        test_files = int(unit_tests["stdout"].strip()) if unit_tests["success"] else 0
        source_files = self.run_command("find . -name '*.java' -not -path '*/test/*' | wc -l")
        total_source = int(source_files["stdout"].strip()) if source_files["success"] else 1
        
        coverage_ratio = (test_files / total_source) * 100 if total_source > 0 else 0
        
        return {
            "unit_tests": test_files,
            "integration_tests": int(integration_tests["stdout"].strip()) if integration_tests["success"] else 0,
            "e2e_tests": int(e2e_tests["stdout"].strip()) if e2e_tests["success"] else 0,
            "test_coverage_ratio": round(coverage_ratio, 2),
            "has_testing_framework": test_files > 0,
            "testing_maturity": "Advanced" if test_files > 20 else "Basic" if test_files > 5 else "Minimal"
        }
    
    def analyze_docker_configuration(self):
        """Analisa configuração Docker"""
        
        # Contar arquivos Docker
        dockerfiles = self.run_command("find . -name 'Dockerfile*' | wc -l")
        compose_files = self.run_command("find . -name 'docker-compose*.yml' | wc -l")
        
        # Verificar configurações específicas
        has_multi_stage = self.run_command("grep -r 'FROM.*as' . --include='Dockerfile*' | head -1")
        has_health_checks = self.run_command("grep -r 'healthcheck' . --include='docker-compose*.yml' | head -1")
        has_volumes = self.run_command("grep -r 'volumes:' . --include='docker-compose*.yml' | head -1")
        
        docker_maturity = 0
        if int(dockerfiles["stdout"].strip()) > 0:
            docker_maturity += 1
        if int(compose_files["stdout"].strip()) > 0:
            docker_maturity += 1
        if has_multi_stage["success"] and has_multi_stage["stdout"].strip():
            docker_maturity += 1
        if has_health_checks["success"] and has_health_checks["stdout"].strip():
            docker_maturity += 1
        if has_volumes["success"] and has_volumes["stdout"].strip():
            docker_maturity += 1
        
        return {
            "dockerfiles": int(dockerfiles["stdout"].strip()) if dockerfiles["success"] else 0,
            "compose_files": int(compose_files["stdout"].strip()) if compose_files["success"] else 0,
            "has_multi_stage_builds": has_multi_stage["success"] and bool(has_multi_stage["stdout"].strip()),
            "has_health_checks": has_health_checks["success"] and bool(has_health_checks["stdout"].strip()),
            "has_volume_management": has_volumes["success"] and bool(has_volumes["stdout"].strip()),
            "docker_maturity_score": (docker_maturity / 5) * 100,
            "containerization_level": "Advanced" if docker_maturity >= 4 else "Intermediate" if docker_maturity >= 2 else "Basic"
        }
    
    def analyze_documentation(self):
        """Analisa documentação"""
        
        # Contar arquivos de documentação
        readme_files = self.run_command("find . -name 'README*' -o -name 'readme*' | wc -l")
        markdown_files = self.run_command("find . -name '*.md' | wc -l")
        
        # Verificar qualidade da documentação
        has_api_docs = self.run_command("find . -name '*api*' -name '*.md' | head -1")
        has_setup_docs = self.run_command("grep -r -i 'installation\\|setup\\|getting started' . --include='*.md' | head -1")
        
        documentation_score = 0
        if int(readme_files["stdout"].strip()) > 0:
            documentation_score += 25
        if int(markdown_files["stdout"].strip()) > 5:
            documentation_score += 25
        if has_api_docs["success"] and has_api_docs["stdout"].strip():
            documentation_score += 25
        if has_setup_docs["success"] and has_setup_docs["stdout"].strip():
            documentation_score += 25
        
        return {
            "readme_files": int(readme_files["stdout"].strip()) if readme_files["success"] else 0,
            "markdown_files": int(markdown_files["stdout"].strip()) if markdown_files["success"] else 0,
            "has_api_documentation": has_api_docs["success"] and bool(has_api_docs["stdout"].strip()),
            "has_setup_documentation": has_setup_docs["success"] and bool(has_setup_docs["stdout"].strip()),
            "documentation_score": documentation_score,
            "documentation_level": "Excellent" if documentation_score >= 75 else "Good" if documentation_score >= 50 else "Basic"
        }
    
    def analyze_maintainability(self):
        """Analisa manutenibilidade"""
        
        # Verificar configuração centralizada
        config_centralization = self.run_command("find . -name 'application*.properties' -o -name 'application*.yml' | wc -l")
        
        # Verificar modularização
        modules = self.run_command("find . -name 'pom.xml' | wc -l")
        
        # Verificar separação de concerns
        concerns_separation = 0
        if self.run_command("find . -name '*Controller*' | head -1")["stdout"].strip():
            concerns_separation += 1
        if self.run_command("find . -name '*Service*' | head -1")["stdout"].strip():
            concerns_separation += 1
        if self.run_command("find . -name '*Repository*' | head -1")["stdout"].strip():
            concerns_separation += 1
        if self.run_command("find . -name '*Config*' | head -1")["stdout"].strip():
            concerns_separation += 1
        
        maintainability_score = (
            min(25, int(config_centralization["stdout"].strip()) * 5) +
            min(25, int(modules["stdout"].strip()) * 3) +
            (concerns_separation / 4) * 50
        )
        
        return {
            "config_files": int(config_centralization["stdout"].strip()) if config_centralization["success"] else 0,
            "module_count": int(modules["stdout"].strip()) if modules["success"] else 0,
            "separation_of_concerns": concerns_separation,
            "maintainability_score": round(maintainability_score, 2),
            "maintainability_level": "High" if maintainability_score >= 75 else "Medium" if maintainability_score >= 50 else "Low"
        }
    
    def compare_branches(self, master_analysis, refactoring_analysis):
        """Compara as duas branches"""
        
        comparison = {
            "file_organization": {
                "master": master_analysis["file_organization"]["layer_compliance_percentage"],
                "refactoring": refactoring_analysis["file_organization"]["layer_compliance_percentage"],
                "winner": "refactoring" if refactoring_analysis["file_organization"]["layer_compliance_percentage"] > master_analysis["file_organization"]["layer_compliance_percentage"] else "master"
            },
            "architecture_compliance": {
                "master": master_analysis["architecture_compliance"]["compliance_score"],
                "refactoring": refactoring_analysis["architecture_compliance"]["compliance_score"],
                "winner": "refactoring" if refactoring_analysis["architecture_compliance"]["compliance_score"] > master_analysis["architecture_compliance"]["compliance_score"] else "master"
            },
            "code_quality": {
                "master": master_analysis["code_quality"]["code_quality_score"],
                "refactoring": refactoring_analysis["code_quality"]["code_quality_score"],
                "winner": "refactoring" if refactoring_analysis["code_quality"]["code_quality_score"] > master_analysis["code_quality"]["code_quality_score"] else "master"
            },
            "testing_structure": {
                "master": master_analysis["testing_structure"]["test_coverage_ratio"],
                "refactoring": refactoring_analysis["testing_structure"]["test_coverage_ratio"],
                "winner": "refactoring" if refactoring_analysis["testing_structure"]["test_coverage_ratio"] > master_analysis["testing_structure"]["test_coverage_ratio"] else "master"
            },
            "docker_configuration": {
                "master": master_analysis["docker_configuration"]["docker_maturity_score"],
                "refactoring": refactoring_analysis["docker_configuration"]["docker_maturity_score"],
                "winner": "refactoring" if refactoring_analysis["docker_configuration"]["docker_maturity_score"] > master_analysis["docker_configuration"]["docker_maturity_score"] else "master"
            },
            "documentation": {
                "master": master_analysis["documentation"]["documentation_score"],
                "refactoring": refactoring_analysis["documentation"]["documentation_score"],
                "winner": "refactoring" if refactoring_analysis["documentation"]["documentation_score"] > master_analysis["documentation"]["documentation_score"] else "master"
            },
            "maintainability": {
                "master": master_analysis["maintainability"]["maintainability_score"],
                "refactoring": refactoring_analysis["maintainability"]["maintainability_score"],
                "winner": "refactoring" if refactoring_analysis["maintainability"]["maintainability_score"] > master_analysis["maintainability"]["maintainability_score"] else "master"
            }
        }
        
        # Calcular score geral
        refactoring_wins = sum(1 for category in comparison.values() if category["winner"] == "refactoring")
        total_categories = len(comparison)
        
        return comparison, refactoring_wins, total_categories
    
    def generate_recommendation(self, comparison, refactoring_wins, total_categories, master_analysis, refactoring_analysis):
        """Gera recomendação final"""
        
        win_percentage = (refactoring_wins / total_categories) * 100
        
        if win_percentage >= 80:
            recommendation = "FORTEMENTE RECOMENDADO usar branch REFACTORING-CLEAN-ARCHITECTURE-V2.1"
            confidence = "MUITO ALTA"
        elif win_percentage >= 60:
            recommendation = "RECOMENDADO usar branch REFACTORING-CLEAN-ARCHITECTURE-V2.1"
            confidence = "ALTA"
        elif win_percentage >= 40:
            recommendation = "CONSIDERAR usar branch REFACTORING-CLEAN-ARCHITECTURE-V2.1"
            confidence = "MÉDIA"
        else:
            recommendation = "MANTER branch MASTER por enquanto"
            confidence = "BAIXA para mudança"
        
        # Principais melhorias
        key_improvements = []
        
        if comparison["file_organization"]["winner"] == "refactoring":
            improvement = f"Organização de arquivos melhorou {refactoring_analysis['file_organization']['layer_compliance_percentage'] - master_analysis['file_organization']['layer_compliance_percentage']:.1f}%"
            key_improvements.append(improvement)
        
        if comparison["architecture_compliance"]["winner"] == "refactoring":
            improvement = f"Conformidade arquitetural melhorou {refactoring_analysis['architecture_compliance']['compliance_score'] - master_analysis['architecture_compliance']['compliance_score']:.1f}%"
            key_improvements.append(improvement)
        
        if comparison["testing_structure"]["winner"] == "refactoring":
            improvement = f"Cobertura de testes melhorou {refactoring_analysis['testing_structure']['test_coverage_ratio'] - master_analysis['testing_structure']['test_coverage_ratio']:.1f}%"
            key_improvements.append(improvement)
        
        return {
            "recommendation": recommendation,
            "confidence_level": confidence,
            "win_percentage": win_percentage,
            "refactoring_wins": refactoring_wins,
            "total_categories": total_categories,
            "key_improvements": key_improvements,
            "summary": f"Branch refactoring venceu em {refactoring_wins}/{total_categories} categorias ({win_percentage:.1f}%)"
        }
    
    def run_complete_analysis(self):
        """Executa análise completa"""
        print("🔍 ANÁLISE COMPARATIVA DETALHADA DE ARQUITETURAS")
        print("=" * 65)
        
        try:
            # Salvar branch atual
            current_branch = self.run_command("git branch --show-current")
            original_branch = current_branch["stdout"].strip() if current_branch["success"] else "refactoring-clean-architecture-v2.1"
            
            # Analisar branch master
            print("\n📊 ANALISANDO BRANCH MASTER")
            print("=" * 40)
            master_analysis = self.analyze_branch_structure("master")
            self.analysis_results["branches"]["master"] = master_analysis
            
            # Analisar branch refactoring
            print("\n📊 ANALISANDO BRANCH REFACTORING-CLEAN-ARCHITECTURE-V2.1")
            print("=" * 60)
            refactoring_analysis = self.analyze_branch_structure("refactoring-clean-architecture-v2.1")
            self.analysis_results["branches"]["refactoring"] = refactoring_analysis
            
            # Comparar branches
            print("\n⚖️ COMPARANDO BRANCHES")
            print("=" * 30)
            comparison, refactoring_wins, total_categories = self.compare_branches(master_analysis, refactoring_analysis)
            self.analysis_results["comparison"] = comparison
            
            # Gerar recomendação
            recommendation = self.generate_recommendation(comparison, refactoring_wins, total_categories, master_analysis, refactoring_analysis)
            self.analysis_results["recommendation"] = recommendation
            
            # Voltar para branch original
            self.run_command(f"git checkout {original_branch}")
            
            # Exibir relatório
            self.display_final_report()
            
            # Salvar resultados
            self.save_analysis_results()
            
            return True
            
        except Exception as e:
            print(f"❌ Erro durante análise: {e}")
            return False
    
    def display_final_report(self):
        """Exibe relatório final"""
        print("\n" + "=" * 80)
        print("📊 RELATÓRIO FINAL - COMPARAÇÃO DE ARQUITETURAS")
        print("=" * 80)
        
        master = self.analysis_results["branches"]["master"]
        refactoring = self.analysis_results["branches"]["refactoring"]
        comparison = self.analysis_results["comparison"]
        recommendation = self.analysis_results["recommendation"]
        
        print(f"\n🏗️ CONFORMIDADE ARQUITETURAL:")
        print(f"   • Master: {master['architecture_compliance']['compliance_score']:.1f}% ({master['architecture_compliance']['architecture_pattern']})")
        print(f"   • Refactoring: {refactoring['architecture_compliance']['compliance_score']:.1f}% ({refactoring['architecture_compliance']['architecture_pattern']})")
        print(f"   🏆 Vencedor: {comparison['architecture_compliance']['winner'].upper()}")
        
        print(f"\n📁 ORGANIZAÇÃO DE ARQUIVOS:")
        print(f"   • Master: {master['file_organization']['layer_compliance_percentage']:.1f}% (Clean Architecture)")
        print(f"   • Refactoring: {refactoring['file_organization']['layer_compliance_percentage']:.1f}% (Clean Architecture)")
        print(f"   🏆 Vencedor: {comparison['file_organization']['winner'].upper()}")
        
        print(f"\n⚙️ QUALIDADE DE CÓDIGO:")
        print(f"   • Master: {master['code_quality']['code_quality_score']:.1f}/100")
        print(f"   • Refactoring: {refactoring['code_quality']['code_quality_score']:.1f}/100")
        print(f"   🏆 Vencedor: {comparison['code_quality']['winner'].upper()}")
        
        print(f"\n🧪 ESTRUTURA DE TESTES:")
        print(f"   • Master: {master['testing_structure']['test_coverage_ratio']:.1f}% ({master['testing_structure']['testing_maturity']})")
        print(f"   • Refactoring: {refactoring['testing_structure']['test_coverage_ratio']:.1f}% ({refactoring['testing_structure']['testing_maturity']})")
        print(f"   🏆 Vencedor: {comparison['testing_structure']['winner'].upper()}")
        
        print(f"\n🐳 CONFIGURAÇÃO DOCKER:")
        print(f"   • Master: {master['docker_configuration']['docker_maturity_score']:.1f}% ({master['docker_configuration']['containerization_level']})")
        print(f"   • Refactoring: {refactoring['docker_configuration']['docker_maturity_score']:.1f}% ({refactoring['docker_configuration']['containerization_level']})")
        print(f"   🏆 Vencedor: {comparison['docker_configuration']['winner'].upper()}")
        
        print(f"\n📚 DOCUMENTAÇÃO:")
        print(f"   • Master: {master['documentation']['documentation_score']}/100 ({master['documentation']['documentation_level']})")
        print(f"   • Refactoring: {refactoring['documentation']['documentation_score']}/100 ({refactoring['documentation']['documentation_level']})")
        print(f"   🏆 Vencedor: {comparison['documentation']['winner'].upper()}")
        
        print(f"\n🔧 MANUTENIBILIDADE:")
        print(f"   • Master: {master['maintainability']['maintainability_score']:.1f}/100 ({master['maintainability']['maintainability_level']})")
        print(f"   • Refactoring: {refactoring['maintainability']['maintainability_score']:.1f}/100 ({refactoring['maintainability']['maintainability_level']})")
        print(f"   🏆 Vencedor: {comparison['maintainability']['winner'].upper()}")
        
        print(f"\n🎯 RESULTADO FINAL:")
        print(f"   📊 {recommendation['summary']}")
        print(f"   🏆 {recommendation['recommendation']}")
        print(f"   🎲 Confiança: {recommendation['confidence_level']}")
        
        if recommendation['key_improvements']:
            print(f"\n💡 PRINCIPAIS MELHORIAS:")
            for improvement in recommendation['key_improvements']:
                print(f"   ✅ {improvement}")
    
    def save_analysis_results(self):
        """Salva resultados da análise"""
        try:
            output_file = f"{self.workspace}/ARCHITECTURE_COMPARISON_DETAILED.json"
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(self.analysis_results, f, indent=2, ensure_ascii=False)
            
            print(f"\n💾 Análise detalhada salva: ARCHITECTURE_COMPARISON_DETAILED.json")
            
            # Também criar versão markdown
            self.create_markdown_report()
            
        except Exception as e:
            print(f"❌ Erro ao salvar análise: {e}")
    
    def create_markdown_report(self):
        """Cria relatório em Markdown"""
        
        master = self.analysis_results["branches"]["master"]
        refactoring = self.analysis_results["branches"]["refactoring"]
        recommendation = self.analysis_results["recommendation"]
        
        content = f"""# Análise Comparativa de Arquiteturas

**Data:** {self.analysis_results['timestamp']}  
**Ambiente:** {self.analysis_results['environment']}

## 🎯 Resultado Final

**{recommendation['recommendation']}**

**Confiança:** {recommendation['confidence_level']}  
**Performance:** {recommendation['summary']}

## 📊 Comparação Detalhada

### 🏗️ Conformidade Arquitetural
- **Master:** {master['architecture_compliance']['compliance_score']:.1f}% ({master['architecture_compliance']['architecture_pattern']})
- **Refactoring:** {refactoring['architecture_compliance']['compliance_score']:.1f}% ({refactoring['architecture_compliance']['architecture_pattern']})

### 📁 Organização de Arquivos  
- **Master:** {master['file_organization']['layer_compliance_percentage']:.1f}% Clean Architecture
- **Refactoring:** {refactoring['file_organization']['layer_compliance_percentage']:.1f}% Clean Architecture

### ⚙️ Qualidade de Código
- **Master:** {master['code_quality']['code_quality_score']:.1f}/100
- **Refactoring:** {refactoring['code_quality']['code_quality_score']:.1f}/100

### 🧪 Estrutura de Testes
- **Master:** {master['testing_structure']['test_coverage_ratio']:.1f}% ({master['testing_structure']['testing_maturity']})
- **Refactoring:** {refactoring['testing_structure']['test_coverage_ratio']:.1f}% ({refactoring['testing_structure']['testing_maturity']})

### 🐳 Configuração Docker
- **Master:** {master['docker_configuration']['docker_maturity_score']:.1f}% ({master['docker_configuration']['containerization_level']})
- **Refactoring:** {refactoring['docker_configuration']['docker_maturity_score']:.1f}% ({refactoring['docker_configuration']['containerization_level']})

### 📚 Documentação
- **Master:** {master['documentation']['documentation_score']}/100 ({master['documentation']['documentation_level']})
- **Refactoring:** {refactoring['documentation']['documentation_score']}/100 ({refactoring['documentation']['documentation_level']})

### 🔧 Manutenibilidade
- **Master:** {master['maintainability']['maintainability_score']:.1f}/100 ({master['maintainability']['maintainability_level']})
- **Refactoring:** {refactoring['maintainability']['maintainability_score']:.1f}/100 ({refactoring['maintainability']['maintainability_level']})

## 💡 Principais Melhorias

"""
        
        if recommendation['key_improvements']:
            for improvement in recommendation['key_improvements']:
                content += f"- ✅ {improvement}\n"
        else:
            content += "- Nenhuma melhoria significativa identificada\n"
        
        content += f"""
---
*Relatório gerado automaticamente pelo Architecture Comparator WSL*
"""
        
        try:
            output_file = f"{self.workspace}/ARCHITECTURE_COMPARISON_DETAILED.md"
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(content)
            
            print(f"📄 Relatório Markdown salvo: ARCHITECTURE_COMPARISON_DETAILED.md")
            
        except Exception as e:
            print(f"❌ Erro ao salvar Markdown: {e}")

def main():
    """Função principal"""
    comparator = ArchitectureComparator()
    
    print("🔍 ARCHITECTURE COMPARATOR - WSL LINUX")
    print("Análise detalhada: Master vs Refactoring-Clean-Architecture-v2.1")
    print("=" * 70)
    
    success = comparator.run_complete_analysis()
    return 0 if success else 1

if __name__ == "__main__":
    exit(main())
