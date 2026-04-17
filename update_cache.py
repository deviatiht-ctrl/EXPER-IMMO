#!/usr/bin/env python3
"""
Script pou ajoute cache-busting ak favicon nan tout fichye HTML
"""

import os
import re
from pathlib import Path

# Antèt cache ki dwe ajoute
CACHE_META = '''    <!-- Anti-cache meta tags -->
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
    <meta http-equiv="Pragma" content="no-cache">
    <meta http-equiv="Expires" content="0">
    
    <!-- Favicon / Logo -->
    <link rel="icon" type="image/png" href="assets/EXPER IMMO LOGO.png">
    <link rel="shortcut icon" type="image/png" href="assets/EXPER IMMO LOGO.png">
    <link rel="apple-touch-icon" href="assets/EXPER IMMO LOGO.png">
'''

def update_html_file(filepath):
    """Mete ajou yon fichye HTML ak cache-busting"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Verify si se yon fichye HTML valide
        if not content.strip().startswith('<!DOCTYPE html>'):
            return False
        
        original = content
        
        # 1. Ajoute anti-cache meta tags apre viewport
        if 'Cache-Control' not in content:
            content = re.sub(
                r'(<meta name="viewport"[^>]+>)',
                r'\1\n    \n' + CACHE_META.strip(),
                content
            )
        
        # 2. Ajoute cache-busting nan CSS fichye (.css -> .css?v=2.0)
        content = re.sub(
            r'href="(css/[^"]+\.css)"(?!\?)',
            r'href="\1?v=2.0"',
            content
        )
        
        # 3. Ajoute cache-busting nan JS fichye (.js -> .js?v=2.0)
        content = re.sub(
            r'src="(js/[^"]+\.js)"(?!\?)',
            r'src="\1?v=2.0"',
            content
        )
        
        # 4. Ajoute cache-busting nan import JS
        content = re.sub(
            r"from ['\"](\./js/[^'\"]+\.js)['\"](?!\?)",
            r"from '\1?v=2.0'",
            content
        )
        
        # 5. Ranplase icon-192.png ak EXPER IMMO LOGO.png
        content = re.sub(
            r'href="/?assets/icons/icon-192\.png"',
            'href="assets/EXPER IMMO LOGO.png"',
            content
        )
        
        if content != original:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"✓ Updated: {filepath}")
            return True
        else:
            print(f"- Skipped (no changes): {filepath}")
            return False
            
    except Exception as e:
        print(f"✗ Error: {filepath} - {e}")
        return False

def main():
    # Jwenn tout fichye HTML
    base_dir = Path('c:/Users/HACKER/Pictures/EXPER IMMO')
    html_files = list(base_dir.rglob('*.html'))
    
    # Eskli flutter_app pou kounye a
    html_files = [f for f in html_files if 'flutter_app' not in str(f)]
    
    print(f"Found {len(html_files)} HTML files")
    print("=" * 50)
    
    updated = 0
    for filepath in html_files:
        if update_html_file(filepath):
            updated += 1
    
    print("=" * 50)
    print(f"Updated {updated} files")

if __name__ == '__main__':
    main()
