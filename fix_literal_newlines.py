"""Fix literal \\n sequences that appear as text in HTML files"""
from pathlib import Path
import re

base = Path('c:/Users/HACKER/Pictures/EXPER IMMO')

fixed = 0
for f in base.rglob('*.html'):
    if 'flutter_app' in str(f):
        continue
    try:
        content = f.read_text(encoding='utf-8', errors='ignore')
        original = content
        
        # Fix literal \n that appear in text (backslash followed by n as chars)
        # These were likely inserted by a script that escaped newlines
        # Replace with actual newlines + indentation
        if '\\n    \\n' in content or '">\\n' in content:
            # Replace \n sequences with actual newlines
            content = content.replace('\\n    \\n    ', '\n    \n    ')
            content = content.replace('\\n    ', '\n    ')
            content = content.replace('\\n', '\n')
        
        # Also fix réeload -> reload
        content = content.replace('réeload', 'reload')
        content = content.replace('sétats-grid', 'stats-grid')
        content = content.replace('Sétats ', 'Stats ')
        content = content.replace('sétats ', 'stats ')
        
        if content != original:
            f.write_text(content, encoding='utf-8')
            print(f'✓ {f.relative_to(base)}')
            fixed += 1
    except Exception as e:
        print(f'❌ {f.name}: {e}')

print(f'\n✅ Korije: {fixed} fichye')
