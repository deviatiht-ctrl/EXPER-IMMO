#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Korije tout pwoblèm accent nan tout fichye HTML
"""

import os
import re
from pathlib import Path

# Mo ki dwe korije ak vèsyon kòrèk yo
CORRECTIONS = {
    'Proprits': 'Propriétés',
    'Proprit': 'Propriété',
    'proprits': 'propriétés',
    'proprit': 'propriété',
    'Hati': 'Haïti',
    'rservs': 'réservés',
    'Cr': 'Créé',
    'Ption': 'Pétion',
    'rfrence': 'référence',
    'rcentes': 'récentes',
    'dcroissant': 'décroissant',
    'Rinitialiser': 'Réinitialiser',
    'Meubl': 'Meublé',
    'rsultat': 'résultat',
    'Ressayez': 'Réessayez',
    'Propos': 'À Propos',
    'A propos': 'À Propos',
    'Acheter': 'Acheter',
}

def fix_file(filepath):
    """Korije yon fichye HTML"""
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        original = content
        
        # Korije tout mo yo
        for wrong, correct in CORRECTIONS.items():
            content = content.replace(wrong, correct)
        
        # Korije meta tags ki tache
        content = re.sub(
            r'<meta name="viewport" content="width=device-width, initial-scale=1\.0">\s*<meta http-equiv="Cache-Control"',
            '<meta name="viewport" content="width=device-width, initial-scale=1.0">\n    \n    <!-- Anti-cache meta tags -->\n    <meta http-equiv="Cache-Control"',
            content
        )
        
        # Retire doublo tit
        titles = re.findall(r'<title>[^<]*</title>', content)
        if len(titles) > 1:
            # Kenbe sèlman premye tit la
            content = re.sub(r'<title>[^<]*</title>', '', content, count=len(titles)-1)
        
        if content != original:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        return False
        
    except Exception as e:
        print(f"❌ {filepath.name}: {e}")
        return False

def main():
    base_dir = Path('c:/Users/HACKER/Pictures/EXPER IMMO')
    
    # Jwenn tout fichye HTML
    html_files = list(base_dir.rglob('*.html'))
    html_files = [f for f in html_files if 'flutter_app' not in str(f)]
    
    print(f"Total fichye: {len(html_files)}")
    print("=" * 50)
    
    fixed = 0
    for filepath in sorted(html_files):
        if fix_file(filepath):
            print(f"✓ {filepath.name}")
            fixed += 1
    
    print("=" * 50)
    print(f"Korije: {fixed} fichye")

if __name__ == '__main__':
    main()
