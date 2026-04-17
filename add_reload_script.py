#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Ajoute yon script pou fòse reload si paj la soti nan cache
"""

import os
from pathlib import Path

def add_reload_script(filepath):
    """Ajoute script anti-cache nan yon fichye HTML"""
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        # Script pou fòse reload
        reload_script = '''
    <!-- FORCE NO CACHE -->
    <script>
        // Fòse navigatè a pran nouvo vèsyon an
        if (window.location.hash !== '#nocache') {
            window.location.hash = '#nocache';
            window.location.reload(true);
        }
    </script>
'''
        
        # Ajoute script la aprè </title>
        if '<!-- FORCE NO CACHE -->' not in content:
            content = content.replace('</title>', '</title>' + reload_script)
            
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
        if add_reload_script(filepath):
            print(f"✓ {filepath.name}")
            fixed += 1
    
    print("=" * 50)
    print(f"Script ajoute nan: {fixed} fichye")

if __name__ == '__main__':
    main()
