#!/usr/bin/env python3
"""
Comparação Simplificada de Arquiteturas
Análise rápida: Master vs Refactoring-Clean-Architecture-v2.1
"""

import subprocess
import json
from datetime import datetime

class SimpleArchitectureComparator:
    def __init__(self):
        self.workspace = "/mnt/c/workspace/estudosKBNT_Kafka_Logs"
    
    def run_command(self, command):
        """Executa comando"""
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
                "stderr": result.stderr
            }
        except Exception as e:
            return {"success": False, "stdout": "", "stderr": str(e)}
    
    def analyze_current_branch(self):
        """Analisa branch atual (refactoring)"""
        print("🔍 Analisando branch atual (refactoring-clean-architecture-v2.1)...")
        
        # Verificar estrutura Clean Architecture
        layers = [
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
        
        present_layers = []
        for layer in layers:
            check = self.run_command(f"test -d {layer} && echo 'exists'")
            if check["success"] and "exists" in check["stdout"]:
                present_layers.append(layer)
        
        # Contar arquivos por tipo
        java_files = self.run_command("find . -name '*.java' | wc -l")
        python_files = self.run_command("find . -name '*.py' | wc -l")
        docker_files = self.run_command("find . -name 'docker-compose*.yml' | wc -l")
        test_files = self.run_command("find . -name '*Test*.java' -o -name '*test*.py' | wc -l")
        config_files = self.run_command("find . -name '*.yml' -o -name '*.properties' | wc -l")
        
        # Verificar microserviços
        microservices = self.run_command("find 05-microservices -maxdepth 1 -type d | tail -n +2 | wc -l")
        
        return {
            "clean_architecture_layers": len(present_layers),
            "total_expected_layers": len(layers),
            "layer_compliance": (len(present_layers) / len(layers)) * 100,
            "present_layers": present_layers,
            "file_counts": {
                "java": int(java_files["stdout"].strip()) if java_files["success"] else 0,
                "python": int(python_files["stdout"].strip()) if python_files["success"] else 0,
                "docker": int(docker_files["stdout"].strip()) if docker_files["success"] else 0,
                "tests": int(test_files["stdout"].strip()) if test_files["success"] else 0,
                "configs": int(config_files["stdout"].strip()) if config_files["success"] else 0
            },
            "microservices_count": int(microservices["stdout"].strip()) if microservices["success"] else 0
        }
    
    def analyze_git_differences(self):
        """Analisa diferenças entre branches via git"""
        print("📊 Analisando diferenças entre master e refactoring...")
        
        # Verificar diferenças
        diff_result = self.run_command("git diff master --name-status")
        
        if not diff_result["success"]:
            print("⚠️ Não foi possível comparar com master diretamente")
            return {"total_changes": 0, "analysis": "Não foi possível acessar branch master"}
        
        changes = diff_result["stdout"].strip().split('\n') if diff_result["stdout"].strip() else []
        
        # Categorizar mudanças
        stats = {
            "total_changes": len(changes),
            "added_files": 0,
            "modified_files": 0,
            "deleted_files": 0,
            "renamed_files": 0,
            "clean_arch_files": 0
        }
        
        for change in changes:
            if not change.strip():
                continue
            
            parts = change.split('\t')
            status = parts[0]
            filename = parts[1] if len(parts) > 1 else ""
            
            if status.startswith('A'):
                stats["added_files"] += 1
            elif status.startswith('M'):
                stats["modified_files"] += 1
            elif status.startswith('D'):
                stats["deleted_files"] += 1
            elif status.startswith('R'):
                stats["renamed_files"] += 1
            
            # Verificar se é arquivo de Clean Architecture
            if any(layer in filename for layer in ["01-presentation", "02-application", "03-domain", "04-infrastructure", "05-microservices", "06-deployment", "07-testing", "08-configuration", "09-monitoring", "10-tools"]):
                stats["clean_arch_files"] += 1
        
        return stats
    
    def evaluate_architecture_quality(self, current_analysis, git_analysis):
        """Avalia qualidade arquitetural"""
        print("⚖️ Avaliando qualidade arquitetural...")
        
        scores = {}
        
        # 1. Score Clean Architecture (0-100)
        clean_arch_score = current_analysis["layer_compliance"]
        scores["clean_architecture"] = clean_arch_score
        
        # 2. Score de Organização (0-100)
        if git_analysis["clean_arch_files"] > 100:
            organization_score = 100
        elif git_analysis["clean_arch_files"] > 50:
            organization_score = 80
        elif git_analysis["clean_arch_files"] > 20:
            organization_score = 60
        else:
            organization_score = 40
        scores["organization"] = organization_score
        
        # 3. Score de Modularização (0-100)
        microservices_count = current_analysis["microservices_count"]
        if microservices_count >= 5:
            modularization_score = 100
        elif microservices_count >= 3:
            modularization_score = 80
        elif microservices_count >= 1:
            modularization_score = 60
        else:
            modularization_score = 20
        scores["modularization"] = modularization_score
        
        # 4. Score de Containerização (0-100)
        docker_files = current_analysis["file_counts"]["docker"]
        if docker_files >= 10:
            containerization_score = 100
        elif docker_files >= 5:
            containerization_score = 80
        elif docker_files >= 2:
            containerization_score = 60
        else:
            containerization_score = 30
        scores["containerization"] = containerization_score
        
        # 5. Score de Testes (0-100)
        test_files = current_analysis["file_counts"]["tests"]
        total_source = current_analysis["file_counts"]["java"] + current_analysis["file_counts"]["python"]
        if total_source > 0:
            test_ratio = (test_files / total_source) * 100
            testing_score = min(100, test_ratio * 2)  # Máximo 100
        else:
            testing_score = 0
        scores["testing"] = testing_score
        
        # Score geral
        overall_score = sum(scores.values()) / len(scores)
        
        return scores, overall_score
    
    def generate_recommendation(self, scores, overall_score, current_analysis, git_analysis):
        """Gera recomendação"""
        print("💡 Gerando recomendação...")
        
        # Determinar nível de qualidade
        if overall_score >= 85:
            quality_level = "EXCELENTE"
            recommendation = "FORTEMENTE RECOMENDADO usar branch REFACTORING-CLEAN-ARCHITECTURE-V2.1"
            confidence = "MUITO ALTA"
        elif overall_score >= 70:
            quality_level = "BOA"
            recommendation = "RECOMENDADO usar branch REFACTORING-CLEAN-ARCHITECTURE-V2.1"
            confidence = "ALTA"
        elif overall_score >= 55:
            quality_level = "ADEQUADA"
            recommendation = "CONSIDERAR usar branch REFACTORING-CLEAN-ARCHITECTURE-V2.1"
            confidence = "MÉDIA"
        else:
            quality_level = "PRECISA MELHORAR"
            recommendation = "AGUARDAR melhorias antes de usar branch REFACTORING"
            confidence = "BAIXA"
        
        # Identificar pontos fortes
        strong_points = []
        if scores["clean_architecture"] >= 80:
            strong_points.append("Excelente conformidade com Clean Architecture")
        if scores["organization"] >= 80:
            strong_points.append("Organização de arquivos muito boa")
        if scores["modularization"] >= 80:
            strong_points.append("Modularização adequada com microserviços")
        if scores["containerization"] >= 80:
            strong_points.append("Configuração Docker robusta")
        if scores["testing"] >= 60:
            strong_points.append("Estrutura de testes adequada")
        
        # Identificar pontos fracos
        weak_points = []
        if scores["clean_architecture"] < 60:
            weak_points.append("Conformidade Clean Architecture pode melhorar")
        if scores["organization"] < 60:
            weak_points.append("Organização de arquivos precisa de atenção")
        if scores["modularization"] < 60:
            weak_points.append("Modularização insuficiente")
        if scores["containerization"] < 60:
            weak_points.append("Configuração Docker básica")
        if scores["testing"] < 40:
            weak_points.append("Estrutura de testes insuficiente")
        
        return {
            "recommendation": recommendation,
            "confidence": confidence,
            "quality_level": quality_level,
            "overall_score": overall_score,
            "strong_points": strong_points,
            "weak_points": weak_points,
            "summary": f"Qualidade {quality_level} com score {overall_score:.1f}/100"
        }
    
    def run_analysis(self):
        """Executa análise completa"""
        print("🏗️ ANÁLISE ARQUITETURAL SIMPLIFICADA")
        print("=" * 50)
        
        try:
            # Análise da branch atual
            current_analysis = self.analyze_current_branch()
            
            # Análise das diferenças Git
            git_analysis = self.analyze_git_differences()
            
            # Avaliação da qualidade
            scores, overall_score = self.evaluate_architecture_quality(current_analysis, git_analysis)
            
            # Geração de recomendação
            recommendation = self.generate_recommendation(scores, overall_score, current_analysis, git_analysis)
            
            # Exibir relatório
            self.display_report(current_analysis, git_analysis, scores, recommendation)
            
            # Salvar resultados
            self.save_results(current_analysis, git_analysis, scores, recommendation)
            
            return True
            
        except Exception as e:
            print(f"❌ Erro durante análise: {e}")
            return False
    
    def display_report(self, current_analysis, git_analysis, scores, recommendation):
        """Exibe relatório"""
        print("\n" + "=" * 60)
        print("📊 RELATÓRIO DE ANÁLISE ARQUITETURAL")
        print("=" * 60)
        
        print(f"\n🏗️ CONFORMIDADE CLEAN ARCHITECTURE:")
        print(f"   • Camadas implementadas: {current_analysis['clean_architecture_layers']}/{current_analysis['total_expected_layers']}")
        print(f"   • Percentual de conformidade: {current_analysis['layer_compliance']:.1f}%")
        print(f"   • Score: {scores['clean_architecture']:.1f}/100")
        
        print(f"\n📁 ORGANIZAÇÃO DE ARQUIVOS:")
        print(f"   • Total de mudanças vs master: {git_analysis['total_changes']}")
        print(f"   • Arquivos em camadas Clean: {git_analysis['clean_arch_files']}")
        print(f"   • Score: {scores['organization']:.1f}/100")
        
        print(f"\n🎯 MODULARIZAÇÃO:")
        print(f"   • Microserviços implementados: {current_analysis['microservices_count']}")
        print(f"   • Score: {scores['modularization']:.1f}/100")
        
        print(f"\n🐳 CONTAINERIZAÇÃO:")
        print(f"   • Arquivos Docker: {current_analysis['file_counts']['docker']}")
        print(f"   • Score: {scores['containerization']:.1f}/100")
        
        print(f"\n🧪 ESTRUTURA DE TESTES:")
        print(f"   • Arquivos de teste: {current_analysis['file_counts']['tests']}")
        print(f"   • Score: {scores['testing']:.1f}/100")
        
        print(f"\n📊 RESUMO GERAL:")
        print(f"   • Score geral: {recommendation['overall_score']:.1f}/100")
        print(f"   • Qualidade: {recommendation['quality_level']}")
        
        print(f"\n✅ PONTOS FORTES:")
        for point in recommendation['strong_points']:
            print(f"   • {point}")
        
        if recommendation['weak_points']:
            print(f"\n⚠️ PONTOS PARA MELHORIA:")
            for point in recommendation['weak_points']:
                print(f"   • {point}")
        
        print(f"\n🎯 RECOMENDAÇÃO FINAL:")
        print(f"   📋 {recommendation['recommendation']}")
        print(f"   🎲 Confiança: {recommendation['confidence']}")
        print(f"   💡 {recommendation['summary']}")
    
    def save_results(self, current_analysis, git_analysis, scores, recommendation):
        """Salva resultados"""
        results = {
            "timestamp": datetime.now().isoformat(),
            "environment": "WSL Ubuntu Linux",
            "branch_analyzed": "refactoring-clean-architecture-v2.1",
            "current_analysis": current_analysis,
            "git_analysis": git_analysis,
            "scores": scores,
            "recommendation": recommendation
        }
        
        try:
            # Salvar JSON
            with open(f"{self.workspace}/ARCHITECTURE_ANALYSIS_SIMPLE.json", 'w') as f:
                json.dump(results, f, indent=2)
            
            print(f"\n💾 Análise salva: ARCHITECTURE_ANALYSIS_SIMPLE.json")
            
            # Criar relatório Markdown
            self.create_markdown_report(results)
            
        except Exception as e:
            print(f"❌ Erro ao salvar: {e}")
    
    def create_markdown_report(self, results):
        """Cria relatório Markdown"""
        rec = results["recommendation"]
        scores = results["scores"]
        current = results["current_analysis"]
        
        content = f"""# Análise Arquitetural - Branch Refactoring

**Data:** {results['timestamp']}  
**Branch:** {results['branch_analyzed']}  
**Ambiente:** {results['environment']}

## 🎯 Recomendação Final

**{rec['recommendation']}**

- **Qualidade:** {rec['quality_level']}
- **Score Geral:** {rec['overall_score']:.1f}/100
- **Confiança:** {rec['confidence']}

## 📊 Scores Detalhados

| Categoria | Score | Status |
|-----------|-------|--------|
| Clean Architecture | {scores['clean_architecture']:.1f}/100 | {'✅' if scores['clean_architecture'] >= 70 else '⚠️' if scores['clean_architecture'] >= 50 else '❌'} |
| Organização | {scores['organization']:.1f}/100 | {'✅' if scores['organization'] >= 70 else '⚠️' if scores['organization'] >= 50 else '❌'} |
| Modularização | {scores['modularization']:.1f}/100 | {'✅' if scores['modularization'] >= 70 else '⚠️' if scores['modularization'] >= 50 else '❌'} |
| Containerização | {scores['containerization']:.1f}/100 | {'✅' if scores['containerization'] >= 70 else '⚠️' if scores['containerization'] >= 50 else '❌'} |
| Testes | {scores['testing']:.1f}/100 | {'✅' if scores['testing'] >= 70 else '⚠️' if scores['testing'] >= 50 else '❌'} |

## 🏗️ Estrutura Clean Architecture

- **Camadas implementadas:** {current['clean_architecture_layers']}/{current['total_expected_layers']}
- **Conformidade:** {current['layer_compliance']:.1f}%
- **Microserviços:** {current['microservices_count']}

## ✅ Pontos Fortes

"""
        
        for point in rec['strong_points']:
            content += f"- {point}\n"
        
        if rec['weak_points']:
            content += "\n## ⚠️ Pontos para Melhoria\n\n"
            for point in rec['weak_points']:
                content += f"- {point}\n"
        
        content += "\n---\n*Relatório gerado automaticamente*"
        
        try:
            with open(f"{self.workspace}/ARCHITECTURE_ANALYSIS_SIMPLE.md", 'w') as f:
                f.write(content)
            
            print(f"📄 Relatório Markdown salvo: ARCHITECTURE_ANALYSIS_SIMPLE.md")
            
        except Exception as e:
            print(f"❌ Erro ao salvar Markdown: {e}")

def main():
    """Função principal"""
    comparator = SimpleArchitectureComparator()
    
    print("🔍 SIMPLE ARCHITECTURE COMPARATOR")
    print("Análise da arquitetura atual vs padrões Clean Architecture")
    print("=" * 60)
    
    success = comparator.run_analysis()
    return 0 if success else 1

if __name__ == "__main__":
    exit(main())
