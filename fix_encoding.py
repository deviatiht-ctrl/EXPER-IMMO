#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script pou korije tout fichye HTML ki gen pwoblèm encoding
"""

import os
import re
from pathlib import Path

def fix_html_encoding(filepath):
    """Korije encoding yon fichye HTML"""
    try:
        # Li fichye a ak encoding UTF-8
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        original = content
        
        # Korije tit ki kase (Proprits -> Propriétés)
        content = re.sub(
            r'<title>Proprits\s*\|',
            '<title>Propriétés |',
            content,
            flags=re.IGNORECASE
        )
        
        # Korije lòt mo ki kase yo
        content = content.replace('Proprits', 'Propriétés')
        content = content.replace('Proprité', 'Propriété')
        content = content.replace('proprits', 'propriétés')
        content = content.replace('proprités', 'propriétés')
        
        # Korije tout meta tags ki sou menm lign
        content = re.sub(
            r'<meta name="viewport" content="width=device-width, initial-scale=1\.0">\s*<meta http-equiv="Cache-Control"',
            '<meta name="viewport" content="width=device-width, initial-scale=1.0">\n    \n    <!-- Anti-cache meta tags -->\n    <meta http-equiv="Cache-Control"',
            content
        )
        
        # Korije lign yo ki tache ansanm
        content = re.sub(
            r'\.png">\\n\s*<link rel="shortcut',
            '.png">\n    <link rel="shortcut',
            content
        )
        
        # Korije tit ki gen ak sant lan
        if '<title>Propriétés | EXPERIMMO</title>' not in content and 'Propriétés' in filepath:
            content = re.sub(
                r'<title>[^<]*</title>',
                '<title>Propriétés | EXPERIMMO</title>',
                content
            )
        
        if content != original:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        return False
        
    except Exception as e:
        print(f"Erreur: {filepath} - {e}")
        return False

def main():
    base_dir = Path('c:/Users/HACKER/Pictures/EXPER IMMO')
    
    # Jwenn tout fichye HTML
    html_files = list(base_dir.rglob('*.html'))
    
    # Eskli flutter_app
    html_files = [f for f in html_files if 'flutter_app' not in str(f)]
    
    print(f"Total fichye HTML: {len(html_files)}")
    print("=" * 50)
    
    fixed = 0
    for filepath in html_files:
        if fix_html_encoding(filepath):
            print(f"✓ Korije: {filepath.name}")
            fixed += 1
    
    print("=" * 50)
    print(f"Total korije: {fixed}")

if __name__ == '__main__':
    main()
