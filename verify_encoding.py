#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Verifye si genyen karaktè kase nan tout fichye HTML
"""

from pathlib import Path

def check_broken_chars(filepath):
    """Tcheke si genyen karaktè kase nan yon fichye"""
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        # Lis karaktè kase yo
        broken_chars = ['Œ', 'Ã', 'ï', '¿', '½']
        
        found = []
        for char in broken_chars:
            if char in content:
                count = content.count(char)
                found.append(f"{char}({count})")
        
        if found:
            return ', '.join(found)
        return None
        
    except Exception as e:
        return f"ERREUR: {e}"

def main():
    base_dir = Path('c:/Users/HACKER/Pictures/EXPER IMMO')
    
    html_files = list(base_dir.rglob('*.html'))
    html_files = [f for f in html_files if 'flutter_app' not in str(f)]
    
    print("Verifikasyon encoding...")
    print("=" * 60)
    
    files_with_issues = 0
    for filepath in sorted(html_files):
        issues = check_broken_chars(filepath)
        if issues:
            print(f"⚠️  {filepath.name:<35} | {issues}")
            files_with_issues += 1
    
    print("=" * 60)
    if files_with_issues == 0:
        print("✅ Tout fichye yo prop!")
    else:
        print(f"⚠️  {files_with_issues} fichye gen pwoblèm")

if __name__ == '__main__':
    main()
