#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Korije tout atribi 'réel' yo an 'rel' nan tout fichye HTML
"""

from pathlib import Path

def fix_rel_attributes(filepath):
    """Korije atribi rel nan yon fichye HTML"""
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        original = content
        
        # Ranplase tout 'réel' pa 'rel'
        content = content.replace('réel=', 'rel=')
        
        # Ranplase lòt varyasyon
        content = content.replace('réelative', 'relative')
        content = content.replace('pré=', 'pre=')
        
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
        if fix_rel_attributes(filepath):
            print(f"✓ {filepath.name}")
            fixed += 1
    
    print("=" * 50)
    print(f"Korije: {fixed} fichye")

if __name__ == '__main__':
    main()
