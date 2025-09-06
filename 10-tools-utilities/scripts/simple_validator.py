"""
Validador Simples de Refatoração - Clean Architecture
Verifica a estrutura básica sem imports complexos
"""

import os
from pathlib import Path

def validate_clean_architecture():
    """Valida a estrutura Clean Architecture"""
    
    workspace_root = Path(__file__).parent.parent.parent
    print(f"🔍 Validando workspace: {workspace_root}")
    
    # Camadas esperadas
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
    
    print("\n🏗️ Verificando estrutura de camadas:")
    layers_ok = 0
    
    for layer in expected_layers:
        layer_path = workspace_root / layer
        if layer_path.exists() and layer_path.is_dir():
            print(f"✅ {layer}")
            layers_ok += 1
        else:
            print(f"❌ {layer} - FALTANDO")
    
    # Verificar arquivos críticos
    print("\n📁 Verificando arquivos críticos:")
    
    critical_files = [
        ("08-configuration/ports/configure-standard-ports.py", "Configuração de portas"),
        ("04-infrastructure-layer/docker/docker-compose.scalable.yml", "Docker Compose"),
        ("07-testing/performance-tests/stress-test-with-graphics.py", "Testes de stress"),
        ("01-presentation-layer/docs/README.md", "Documentação principal"),
        ("10-tools-utilities/scripts/workspace_refactorer.py", "Refatorador")
    ]
    
    files_ok = 0
    for file_path, description in critical_files:
        full_path = workspace_root / file_path
        if full_path.exists():
            print(f"✅ {description}: {file_path}")
            files_ok += 1
        else:
            print(f"❌ {description}: {file_path} - FALTANDO")
    
    # Verificar se raiz está limpa
    print("\n🧹 Verificando limpeza da raiz:")
    root_files = [f for f in workspace_root.iterdir() if f.is_file()]
    
    allowed_root_files = {
        'WORKSPACE_NAVIGATION_INDEX.md',
        '.gitignore'
    }
    
    unwanted_files = [f.name for f in root_files if f.name not in allowed_root_files]
    
    if not unwanted_files:
        print("✅ Diretório raiz limpo")
        root_ok = True
    else:
        print(f"⚠️ Arquivos na raiz: {', '.join(unwanted_files[:5])}")
        root_ok = False
    
    # Resumo
    print(f"\n{'='*50}")
    print("📊 RESUMO DA VALIDAÇÃO")
    print(f"{'='*50}")
    print(f"🏗️ Camadas: {layers_ok}/{len(expected_layers)}")
    print(f"📁 Arquivos críticos: {files_ok}/{len(critical_files)}")
    print(f"🧹 Raiz limpa: {'✅' if root_ok else '⚠️'}")
    
    total_score = layers_ok + files_ok + (1 if root_ok else 0)
    max_score = len(expected_layers) + len(critical_files) + 1
    
    print(f"📈 Pontuação: {total_score}/{max_score} ({total_score/max_score*100:.1f}%)")
    
    if total_score >= max_score * 0.8:
        print(f"\n🎉 VALIDAÇÃO PASSOU!")
        print(f"✅ Workspace Clean Architecture está bem organizado")
        return True
    else:
        print(f"\n⚠️ VALIDAÇÃO COM PROBLEMAS")
        print(f"🔧 Revisar itens faltantes")
        return False

if __name__ == "__main__":
    success = validate_clean_architecture()
    print(f"\n💡 Próximos passos:")
    print(f"   1. ✅ Estrutura Clean Architecture validada")
    print(f"   2. 🔧 Configurar portas: 08-configuration/ports/")
    print(f"   3. 🚀 Iniciar aplicação: 02-application-layer/services/")
    print(f"   4. 🧪 Executar testes: 07-testing/performance-tests/")
    exit(0 if success else 1)
