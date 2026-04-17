#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Fòse tout fichye HTML yo an UTF-8 san BOM
"""

import os
from pathlib import Path

def force_utf8(filepath):
    """Li fichye a epi anrejistre l nan UTF-8 kòrèk"""
    try:
        # Eseye li ak diferan encoding
        content = None
        for encoding in ['utf-8', 'utf-8-sig', 'latin-1', 'cp1252', 'iso-8859-1']:
            try:
                with open(filepath, 'r', encoding=encoding) as f:
                    content = f.read()
                break
            except:
                continue
        
        if content is None:
            print(f"❌ Pa ka li: {filepath.name}")
            return False
        
        # Anrejistre nan UTF-8 san BOM
        with open(filepath, 'w', encoding='utf-8', newline='\n') as f:
            f.write(content)
        
        return True
        
    except Exception as e:
        print(f"❌ Erreur: {filepath.name} - {e}")
        return False

def main():
    base_dir = Path('c:/Users/HACKER/Pictures/EXPER IMMO')
    
    # Jwenn tout fichye HTML
    html_files = list(base_dir.rglob('*.html'))
    html_files = [f for f in html_files if 'flutter_app' not in str(f)]
    
    print(f"Total fichye HTML: {len(html_files)}")
    print("=" * 50)
    
    fixed = 0
    for filepath in sorted(html_files):
        if force_utf8(filepath):
            fixed += 1
            print(f"✓ {filepath.name}")
    
    print("=" * 50)
    print(f"Total: {fixed} fichye anrejistre nan UTF-8")

if __name__ == '__main__':
    main()
