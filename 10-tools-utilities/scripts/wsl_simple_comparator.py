#!/usr/bin/env python3
"""
Comparação Simplificada de Branches - WSL Linux
Execução direta no ambiente WSL Ubuntu
"""

import os
import subprocess
import json
from datetime import datetime

def run_command(command):
    """Executa comando e retorna resultado"""
    try:
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            cwd="/mnt/c/workspace/estudosKBNT_Kafka_Logs"
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

def main():
    print("🐧 COMPARAÇÃO DE BRANCHES - WSL DIRETO")
    print("=" * 50)
    
    # Verificar ambiente
    print("🔧 Verificando ambiente...")
    
    git_version = run_command("git --version")
    if not git_version["success"]:
        print("❌ Git não disponível")
        return 1
    
    print(f"✅ Git: {git_version['stdout'].strip()}")
    
    # Verificar repositório
    print("📁 Verificando repositório...")
    
    git_status = run_command("git status --porcelain")
    if not git_status["success"]:
        print("❌ Não é um repositório Git")
        return 1
    
    print("✅ Repositório Git válido")
    
    # Análise de diferenças
    print("🔍 Analisando diferenças entre branches...")
    
    git_diff = run_command("git diff master --name-status")
    if not git_diff["success"]:
        print(f"❌ Erro no git diff: {git_diff['stderr']}")
        return 1
    
    changes = git_diff["stdout"].strip().split('\n') if git_diff["stdout"].strip() else []
    
    # Estatísticas
    stats = {
        "total_changes": len(changes),
        "added": 0,
        "modified": 0,
        "deleted": 0,
        "renamed": 0,
        "clean_architecture_files": 0
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
        filename = parts[1] if len(parts) > 1 else ""
        
        if status.startswith('A'):
            stats["added"] += 1
        elif status.startswith('M'):
            stats["modified"] += 1
        elif status.startswith('D'):
            stats["deleted"] += 1
        elif status.startswith('R'):
            stats["renamed"] += 1
        
        # Verificar se está em camada Clean Architecture
        for layer in clean_architecture_layers:
            if filename.startswith(layer):
                stats["clean_architecture_files"] += 1
                break
    
    # Verificar estrutura de diretórios
    print("🏗️ Verificando estrutura Clean Architecture...")
    
    ls_result = run_command("find . -maxdepth 1 -type d -name '*-*' | sort")
    current_layers = []
    
    if ls_result["success"]:
        current_layers = [
            line.strip().replace('./', '') 
            for line in ls_result["stdout"].split('\n') 
            if line.strip() and '-layer' in line
        ]
    
    compliance_score = len(current_layers) / len(clean_architecture_layers) * 100
    
    # Contar arquivos de teste
    print("🧪 Verificando estrutura de testes...")
    
    test_search = run_command("find . -name '*test*' -o -name '*Test*' | head -20")
    test_files = []
    
    if test_search["success"]:
        test_files = [f.strip() for f in test_search["stdout"].split('\n') if f.strip()]
    
    # Contar arquivos Docker
    print("🐳 Verificando configurações Docker...")
    
    docker_search = run_command("find . -name 'docker-compose*.yml' -o -name 'Dockerfile*' | head -20")
    docker_files = []
    
    if docker_search["success"]:
        docker_files = [f.strip() for f in docker_search["stdout"].split('\n') if f.strip()]
    
    # Relatório
    print("\n" + "=" * 60)
    print("📊 RELATÓRIO DE COMPARAÇÃO DE BRANCHES")
    print("=" * 60)
    
    print(f"\n📈 ESTATÍSTICAS DE MUDANÇAS:")
    print(f"   • Total de mudanças: {stats['total_changes']}")
    print(f"   • Arquivos adicionados: {stats['added']}")
    print(f"   • Arquivos modificados: {stats['modified']}")
    print(f"   • Arquivos deletados: {stats['deleted']}")
    print(f"   • Arquivos renomeados: {stats['renamed']}")
    print(f"   • Arquivos em camadas Clean: {stats['clean_architecture_files']}")
    
    print(f"\n🏗️ CLEAN ARCHITECTURE:")
    print(f"   • Camadas presentes: {len(current_layers)}/{len(clean_architecture_layers)}")
    print(f"   • Score de conformidade: {compliance_score:.1f}%")
    print(f"   • Camadas: {', '.join(current_layers[:5])}{'...' if len(current_layers) > 5 else ''}")
    
    print(f"\n🧪 ESTRUTURA DE TESTES:")
    print(f"   • Arquivos de teste: {len(test_files)}")
    
    print(f"\n🐳 CONFIGURAÇÃO DOCKER:")
    print(f"   • Arquivos Docker: {len(docker_files)}")
    
    # Recomendações
    print(f"\n💡 RECOMENDAÇÕES:")
    
    if compliance_score >= 90:
        print("   ✅ Excelente conformidade com Clean Architecture")
    elif compliance_score >= 70:
        print("   🟡 Boa estrutura, mas pode ser melhorada")
    else:
        print("   🔴 Estrutura precisa de melhorias significativas")
    
    if stats["clean_architecture_files"] > 50:
        print("   ✅ Excelente organização de arquivos em camadas")
    elif stats["clean_architecture_files"] > 20:
        print("   🟡 Boa organização, pode ser expandida")
    else:
        print("   🔴 Poucos arquivos organizados em camadas")
    
    if len(test_files) > 20:
        print("   ✅ Boa cobertura de testes")
    elif len(test_files) > 5:
        print("   🟡 Estrutura de testes básica")
    else:
        print("   🔴 Estrutura de testes insuficiente")
    
    if len(docker_files) > 10:
        print("   ✅ Excelente configuração de containerização")
    elif len(docker_files) > 5:
        print("   🟡 Configuração Docker adequada")
    else:
        print("   🔴 Configuração Docker insuficiente")
    
    # Decisão final
    print(f"\n🎯 DECISÃO FINAL:")
    
    positive_indicators = 0
    
    if compliance_score >= 90:
        positive_indicators += 1
    if stats["clean_architecture_files"] > 50:
        positive_indicators += 1
    if len(test_files) > 20:
        positive_indicators += 1
    if len(docker_files) > 10:
        positive_indicators += 1
    
    if positive_indicators >= 3:
        print("   🟢 USAR BRANCH REFACTORING - Estrutura superior implementada")
        print("   📈 Melhorias significativas em arquitetura, organização e testes")
    elif positive_indicators >= 2:
        print("   🟡 USAR BRANCH REFACTORING - Melhorias importantes implementadas")
        print("   📊 Progresso considerável na estruturação do projeto")
    else:
        print("   🔴 AVALIAR CUIDADOSAMENTE - Melhorias parciais")
        print("   ⚠️ Algumas melhorias presentes, mas não conclusivas")
    
    # Salvar relatório
    report = {
        "timestamp": datetime.now().isoformat(),
        "environment": "WSL Ubuntu Linux",
        "statistics": stats,
        "clean_architecture": {
            "layers_present": len(current_layers),
            "total_layers": len(clean_architecture_layers),
            "compliance_score": compliance_score,
            "current_layers": current_layers
        },
        "testing": {
            "test_files_count": len(test_files)
        },
        "docker": {
            "docker_files_count": len(docker_files)
        },
        "positive_indicators": positive_indicators,
        "recommendation": "USAR BRANCH REFACTORING" if positive_indicators >= 2 else "AVALIAR CUIDADOSAMENTE"
    }
    
    try:
        with open("/mnt/c/workspace/estudosKBNT_Kafka_Logs/BRANCH_COMPARISON_WSL_SIMPLE.json", 'w') as f:
            json.dump(report, f, indent=2)
        print(f"\n💾 Relatório salvo: BRANCH_COMPARISON_WSL_SIMPLE.json")
    except Exception as e:
        print(f"⚠️ Erro ao salvar relatório: {e}")
    
    print(f"\n🎉 Análise concluída com sucesso!")
    return 0

if __name__ == "__main__":
    exit(main())
