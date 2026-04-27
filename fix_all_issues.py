#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script pou korije tout pwoblèm nan fichye HTML yo:
1. HTML entities (&#233; -> é)
2. Chemen relatifs (../../../assets/ -> /assets/)
3. Tit ak accent
"""

import os
import re
from pathlib import Path

# HTML entities -> karaktè UTF-8
HTML_ENTITIES = {
    '&#233;': 'é',
    '&#232;': 'è',
    '&#224;': 'à',
    '&#231;': 'ç',
    '&#234;': 'ê',
    '&#238;': 'î',
    '&#244;': 'ô',
    '&#249;': 'ù',
    '&#226;': 'â',
    '&#228;': 'ä',
    '&#235;': 'ë',
    '&#239;': 'ï',
    '&#246;': 'ö',
    '&#252;': 'ü',
    '&#8217;': "'",
    '&#8220;': '"',
    '&#8221;': '"',
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
}

def fix_html_file(filepath):
    """Korije tout pwoblèm nan yon fichye HTML"""
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        original = content
        
        # 1. Konvèti HTML entities yo
        for entity, char in HTML_ENTITIES.items():
            content = content.replace(entity, char)
        
        # 2. Korije chemen assets (../../../assets/ -> /assets/)
        content = re.sub(r'\.\./\.\./\.\./assets/', '/assets/', content)
        content = re.sub(r'\.\./\.\./assets/', '/assets/', content)
        
        # 3. Korije chemen css/js (../../../css/ -> /css/)
        content = re.sub(r'\.\./\.\./\.\./css/', '/css/', content)
        content = re.sub(r'\.\./\.\./css/', '/css/', content)
        content = re.sub(r'\.\./\.\./\.\./js/', '/js/', content)
        content = re.sub(r'\.\./\.\./js/', '/js/', content)
        
        # 4. Korije tit ak accent
        content = content.replace('Proprits', 'Propriétés')
        content = content.replace('Proprité', 'Propriété')
        content = content.replace('Paramtres', 'Paramètres')
        content = content.replace('Statistiques', 'Statistiques')
        content = content.replace('Gestionnaires', 'Gestionnaires')
        
        if content != original:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        return False
        
    except Exception as e:
        print(f"✗ Erreur: {filepath.name} - {e}")
        return False

def main():
    base_dir = Path('.')
    
    # Jwenn tout fichye HTML
    html_files = list(base_dir.rglob('*.html'))
    
    # Eskli node_modules, .git, flutter_app
    html_files = [f for f in html_files if not any(x in str(f) for x in ['node_modules', '.git', 'flutter_app'])]
    
    print(f"Total fichye HTML: {len(html_files)}")
    print("=" * 60)
    
    fixed = 0
    for filepath in html_files:
        if fix_html_file(filepath):
            print(f"✓ Korije: {filepath}")
            fixed += 1
    
    print("=" * 60)
    print(f"Total korije: {fixed}")

if __name__ == '__main__':
    main()
