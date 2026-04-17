#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Korije tout karaktè kase nan tout fichye HTML
"""

from pathlib import Path

def fix_broken_chars(filepath):
    """Korije karaktè kase nan yon fichye HTML"""
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        original = content
        
        # Ranplase tout karaktè kase yo
        # Œ -> è, é, à, ù selon konteks
        content = content.replace('Œtats', 'États')
        content = content.replace('Œ', 'é')  # Nan plis ka, Œ se é ki kase
        content = content.replace('Ã©', 'é')
        content = content.replace('Ã¨', 'è')
        content = content.replace('Ã ', 'à')
        content = content.replace('Ã¹', 'ù')
        content = content.replace('Ã¢', 'â')
        content = content.replace('Ãª', 'ê')
        content = content.replace('Ã®', 'î')
        content = content.replace('Ã´', 'ô')
        content = content.replace('Ã»', 'û')
        content = content.replace('Ã«', 'ë')
        content = content.replace('Ã¯', 'ï')
        content = content.replace('Ã¼', 'ü')
        content = content.replace('Ã§', 'ç')
        content = content.replace('Ã‰', 'É')
        content = content.replace('Ã€', 'À')
        content = content.replace('Ã ', 'à')
        content = content.replace('Ã©', 'é')
        content = content.replace('Ã¨', 'è')
        
        # ï¿½ se yon lòt fòm kase
        content = content.replace('ï¿½', 'é')
        content = content.replace('ï', 'i')  # ï pa bon, dwe i
        
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
    
    html_files = list(base_dir.rglob('*.html'))
    html_files = [f for f in html_files if 'flutter_app' not in str(f)]
    
    print(f"Total fichye: {len(html_files)}")
    print("=" * 50)
    
    fixed = 0
    for filepath in sorted(html_files):
        if fix_broken_chars(filepath):
            print(f"✓ {filepath.name}")
            fixed += 1
    
    print("=" * 50)
    print(f"Korije: {fixed} fichye")

if __name__ == '__main__':
    main()
