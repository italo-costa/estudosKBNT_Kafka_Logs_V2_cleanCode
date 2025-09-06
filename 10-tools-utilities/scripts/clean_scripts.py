#!/usr/bin/env python3
"""
Limpeza dos Scripts - Remove arquivos da biblioteca Python que foram copiados indevidamente
"""

import os
import shutil
from pathlib import Path

def clean_scripts_directory():
    """Remove arquivos de biblioteca Python que não pertencem ao projeto"""
    
    scripts_dir = Path(__file__).parent
    
    # Arquivos que devem ser mantidos (arquivos do nosso projeto)
    keep_files = {
        'final_cleanup.py',
        'startup-microservices.ps1', 
        'resources_comparison_chart_20250903_235758.png',
        'workspace_refactorer.py',
        'workspace_refactoring_report.json',
        'refactoring_validator.py',
        'workspace_organizer.py',
        'create_resources_comparison.py',
        'workspace_organization_index.json',
        'clean_scripts.py'  # este próprio arquivo
    }
    
    # Scripts que são claramente do projeto (começam com certos padrões)
    project_patterns = [
        'complete-',
        'demo-',
        'deploy-',
        'enhanced-',
        'final-',
        'infrastructure-',
        'message-tracking-',
        'microservices-',
        'simple-',
        'start-',
        'virtualization-',
        'workflow-',
        'working-'
    ]
    
    removed_count = 0
    kept_count = 0
    
    print("🧹 Limpando diretório de scripts...")
    print(f"📂 Diretório: {scripts_dir}")
    
    for item in scripts_dir.iterdir():
        if item.is_file():
            filename = item.name
            
            # Manter arquivos específicos do projeto
            if filename in keep_files:
                kept_count += 1
                print(f"✅ Mantendo: {filename}")
                continue
            
            # Manter scripts que claramente são do projeto
            is_project_file = any(filename.startswith(pattern) for pattern in project_patterns)
            if is_project_file:
                kept_count += 1
                print(f"✅ Mantendo: {filename}")
                continue
            
            # Remover arquivos de biblioteca Python
            try:
                item.unlink()
                removed_count += 1
                print(f"🗑️ Removido: {filename}")
            except Exception as e:
                print(f"❌ Erro ao remover {filename}: {e}")
    
    print(f"\n📊 Resumo da limpeza:")
    print(f"✅ Arquivos mantidos: {kept_count}")
    print(f"🗑️ Arquivos removidos: {removed_count}")
    print(f"🎉 Limpeza concluída!")

if __name__ == "__main__":
    clean_scripts_directory()
