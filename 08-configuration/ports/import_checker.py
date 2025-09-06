#!/usr/bin/env python3
"""
KBNT Kafka Logs - Import Checker and Fixer
Verifica e corrige imports em arquivos Java dos microserviços
"""

import os
import re
import json
from pathlib import Path
from typing import List, Dict, Set, Tuple

class ImportChecker:
    def __init__(self, workspace_path: str):
        self.workspace_path = Path(workspace_path)
        self.microservices_path = self.workspace_path / "05-microservices"
        self.issues = []
        self.fixed_files = []
        
        # Mapeamento de packages comuns
        self.common_imports = {
            'Spring Boot': [
                'org.springframework.boot.SpringApplication',
                'org.springframework.boot.autoconfigure.SpringBootApplication',
                'org.springframework.web.bind.annotation.*',
                'org.springframework.stereotype.*',
                'org.springframework.beans.factory.annotation.*'
            ],
            'Spring Kafka': [
                'org.springframework.kafka.annotation.*',
                'org.springframework.kafka.core.*',
                'org.springframework.kafka.support.*'
            ],
            'Spring Data': [
                'org.springframework.data.jpa.repository.*',
                'org.springframework.data.domain.*'
            ],
            'JPA/Hibernate': [
                'javax.persistence.*',
                'jakarta.persistence.*'
            ],
            'Validation': [
                'javax.validation.*',
                'jakarta.validation.*'
            ],
            'Lombok': [
                'lombok.*'
            ]
        }
        
    def scan_all_java_files(self) -> List[Path]:
        """Escaneia todos os arquivos Java no workspace"""
        java_files = []
        
        # Escanear microserviços
        if self.microservices_path.exists():
            java_files.extend(list(self.microservices_path.rglob("*.java")))
            
        return java_files
    
    def analyze_java_file(self, file_path: Path) -> Dict:
        """Analisa um arquivo Java específico"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                
            analysis = {
                'file': str(file_path),
                'package': self.extract_package(content),
                'imports': self.extract_imports(content),
                'classes': self.extract_classes(content),
                'issues': [],
                'suggestions': []
            }
            
            # Verificar problemas comuns
            analysis['issues'].extend(self.check_import_issues(content))
            analysis['suggestions'].extend(self.suggest_improvements(content, analysis))
            
            return analysis
            
        except Exception as e:
            return {
                'file': str(file_path),
                'error': str(e),
                'issues': [f"Error reading file: {e}"],
                'suggestions': []
            }
    
    def extract_package(self, content: str) -> str:
        """Extrai o package declaration"""
        package_match = re.search(r'package\s+([a-zA-Z0-9_.]+);', content)
        return package_match.group(1) if package_match else ""
    
    def extract_imports(self, content: str) -> List[str]:
        """Extrai todos os imports"""
        import_pattern = r'import\s+(static\s+)?([a-zA-Z0-9_.$*]+);'
        imports = re.findall(import_pattern, content)
        return [imp[1] for imp in imports]
    
    def extract_classes(self, content: str) -> List[str]:
        """Extrai nomes das classes/interfaces"""
        class_pattern = r'(?:public|private|protected)?\s*(?:abstract\s+)?(?:class|interface|enum)\s+([A-Z][a-zA-Z0-9_]*)'
        classes = re.findall(class_pattern, content)
        return classes
    
    def check_import_issues(self, content: str) -> List[str]:
        """Verifica problemas nos imports"""
        issues = []
        
        imports = self.extract_imports(content)
        
        # Verificar imports duplicados
        seen_imports = set()
        for imp in imports:
            if imp in seen_imports:
                issues.append(f"Duplicate import: {imp}")
            seen_imports.add(imp)
        
        # Verificar imports não utilizados
        for imp in imports:
            simple_name = imp.split('.')[-1]
            if simple_name != '*' and simple_name not in content.replace(f"import {imp};", ""):
                issues.append(f"Unused import: {imp}")
        
        # Verificar imports com wildcard desnecessários
        wildcard_imports = [imp for imp in imports if imp.endswith('*')]
        if len(wildcard_imports) > 3:
            issues.append(f"Too many wildcard imports: {len(wildcard_imports)}")
        
        # Verificar imports de javax vs jakarta
        javax_imports = [imp for imp in imports if 'javax.' in imp]
        jakarta_imports = [imp for imp in imports if 'jakarta.' in imp]
        if javax_imports and jakarta_imports:
            issues.append("Mixed javax and jakarta imports")
        
        return issues
    
    def suggest_improvements(self, content: str, analysis: Dict) -> List[str]:
        """Sugere melhorias nos imports"""
        suggestions = []
        
        imports = analysis['imports']
        
        # Sugerir reorganização por grupos
        spring_imports = [imp for imp in imports if 'springframework' in imp]
        java_imports = [imp for imp in imports if imp.startswith('java.')]
        lombok_imports = [imp for imp in imports if 'lombok' in imp]
        
        if spring_imports and not self.are_imports_grouped(content):
            suggestions.append("Group imports by framework (Java -> Spring -> Others)")
        
        # Sugerir uso de static imports para constantes
        if 'import java.util.Collections' in content and 'emptyList()' in content:
            suggestions.append("Consider static import for Collections.emptyList()")
        
        # Sugerir conversão javax -> jakarta
        javax_imports = [imp for imp in imports if 'javax.persistence' in imp or 'javax.validation' in imp]
        if javax_imports:
            suggestions.append("Consider migrating from javax to jakarta imports")
        
        return suggestions
    
    def are_imports_grouped(self, content: str) -> bool:
        """Verifica se os imports estão agrupados"""
        import_section = re.search(r'(import\s+.*?;)+', content, re.MULTILINE | re.DOTALL)
        if not import_section:
            return True
            
        import_lines = import_section.group().split('\n')
        import_lines = [line.strip() for line in import_lines if line.strip().startswith('import')]
        
        # Verificar se estão ordenados
        return import_lines == sorted(import_lines)
    
    def fix_import_issues(self, file_path: Path, analysis: Dict) -> bool:
        """Corrige problemas de imports automaticamente"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            
            # Remover imports duplicados
            content = self.remove_duplicate_imports(content)
            
            # Organizar imports em grupos
            content = self.organize_imports(content)
            
            # Converter javax para jakarta (quando apropriado)
            content = self.convert_javax_to_jakarta(content)
            
            if content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                self.fixed_files.append(str(file_path))
                return True
                
            return False
            
        except Exception as e:
            print(f"Error fixing {file_path}: {e}")
            return False
    
    def remove_duplicate_imports(self, content: str) -> str:
        """Remove imports duplicados"""
        lines = content.split('\n')
        import_lines = []
        seen_imports = set()
        non_import_lines = []
        
        in_import_section = False
        
        for line in lines:
            if line.strip().startswith('import '):
                in_import_section = True
                if line.strip() not in seen_imports:
                    import_lines.append(line)
                    seen_imports.add(line.strip())
            else:
                if in_import_section and line.strip() == '':
                    continue  # Skip empty lines in import section
                non_import_lines.append(line)
                if in_import_section and line.strip():
                    in_import_section = False
        
        # Reconstruir arquivo
        result_lines = []
        
        # Adicionar package e imports
        for line in lines:
            if line.strip().startswith('package '):
                result_lines.append(line)
                break
        
        result_lines.append('')
        result_lines.extend(sorted(import_lines))
        result_lines.append('')
        
        # Adicionar resto do código
        found_class = False
        for line in non_import_lines:
            if not found_class and (line.strip().startswith('package ') or line.strip().startswith('import ')):
                continue
            if 'class ' in line or 'interface ' in line or 'enum ' in line:
                found_class = True
            if found_class:
                result_lines.append(line)
        
        return '\n'.join(result_lines)
    
    def organize_imports(self, content: str) -> str:
        """Organiza imports em grupos"""
        lines = content.split('\n')
        imports = []
        
        for line in lines:
            if line.strip().startswith('import '):
                imports.append(line.strip())
        
        if not imports:
            return content
        
        # Grupos de imports
        java_imports = [imp for imp in imports if 'import java.' in imp or 'import javax.' in imp]
        jakarta_imports = [imp for imp in imports if 'import jakarta.' in imp]
        spring_imports = [imp for imp in imports if 'import org.springframework.' in imp]
        other_imports = [imp for imp in imports if imp not in java_imports + jakarta_imports + spring_imports]
        
        # Ordenar cada grupo
        organized_imports = []
        if java_imports:
            organized_imports.extend(sorted(java_imports))
            organized_imports.append('')
        
        if jakarta_imports:
            organized_imports.extend(sorted(jakarta_imports))
            organized_imports.append('')
        
        if spring_imports:
            organized_imports.extend(sorted(spring_imports))
            organized_imports.append('')
        
        if other_imports:
            organized_imports.extend(sorted(other_imports))
        
        # Remover linha vazia no final se existir
        if organized_imports and organized_imports[-1] == '':
            organized_imports.pop()
        
        # Substituir seção de imports
        new_content = re.sub(
            r'(package\s+[^;]+;)\s*\n+(import\s+[^;]+;\s*\n)*',
            lambda m: m.group(1) + '\n\n' + '\n'.join(organized_imports) + '\n\n',
            content
        )
        
        return new_content
    
    def convert_javax_to_jakarta(self, content: str) -> str:
        """Converte imports javax para jakarta quando apropriado"""
        # Mapeamento de conversões
        conversions = {
            'javax.persistence': 'jakarta.persistence',
            'javax.validation': 'jakarta.validation',
            'javax.servlet': 'jakarta.servlet',
            'javax.annotation': 'jakarta.annotation'
        }
        
        for old, new in conversions.items():
            content = content.replace(f'import {old}', f'import {new}')
        
        return content
    
    def generate_report(self, analyses: List[Dict]) -> Dict:
        """Gera relatório consolidado"""
        report = {
            'summary': {
                'total_files': len(analyses),
                'files_with_issues': len([a for a in analyses if a.get('issues')]),
                'files_fixed': len(self.fixed_files),
                'total_issues': sum(len(a.get('issues', [])) for a in analyses)
            },
            'issue_types': {},
            'suggestions': {},
            'files': analyses,
            'fixed_files': self.fixed_files
        }
        
        # Categorizar problemas
        for analysis in analyses:
            for issue in analysis.get('issues', []):
                issue_type = issue.split(':')[0]
                if issue_type not in report['issue_types']:
                    report['issue_types'][issue_type] = 0
                report['issue_types'][issue_type] += 1
        
        return report

def main():
    """Função principal"""
    workspace_path = "C:/workspace/estudosKBNT_Kafka_Logs"
    
    print("🔍 KBNT Kafka Logs - Import Checker & Fixer")
    print("=" * 50)
    
    checker = ImportChecker(workspace_path)
    
    # Escanear arquivos
    print("📁 Scanning Java files...")
    java_files = checker.scan_all_java_files()
    print(f"Found {len(java_files)} Java files")
    
    # Analisar arquivos
    print("\n🔍 Analyzing imports...")
    analyses = []
    for file_path in java_files:
        analysis = checker.analyze_java_file(file_path)
        analyses.append(analysis)
        
        if analysis.get('issues'):
            print(f"❌ {file_path.name}: {len(analysis['issues'])} issues")
            
            # Tentar corrigir automaticamente
            if checker.fix_import_issues(file_path, analysis):
                print(f"✅ Fixed: {file_path.name}")
        else:
            print(f"✅ {file_path.name}: OK")
    
    # Gerar relatório
    print("\n📊 Generating report...")
    report = checker.generate_report(analyses)
    
    # Salvar relatório
    report_path = Path(workspace_path) / "import_analysis_report.json"
    with open(report_path, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    # Exibir resumo
    print("\n" + "=" * 50)
    print("📋 IMPORT ANALYSIS SUMMARY")
    print("=" * 50)
    print(f"Total files analyzed: {report['summary']['total_files']}")
    print(f"Files with issues: {report['summary']['files_with_issues']}")
    print(f"Files automatically fixed: {report['summary']['files_fixed']}")
    print(f"Total issues found: {report['summary']['total_issues']}")
    
    if report['issue_types']:
        print("\n🔍 Issue breakdown:")
        for issue_type, count in report['issue_types'].items():
            print(f"  - {issue_type}: {count}")
    
    if report['fixed_files']:
        print("\n✅ Fixed files:")
        for fixed_file in report['fixed_files']:
            print(f"  - {Path(fixed_file).name}")
    
    print(f"\n📄 Detailed report saved to: {report_path}")

if __name__ == "__main__":
    main()
