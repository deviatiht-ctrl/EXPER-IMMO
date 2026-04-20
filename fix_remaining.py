from pathlib import Path

base = Path('c:/Users/HACKER/Pictures/EXPER IMMO')
replacements = [
    ('Ã  ', 'à '),
    ('dÃ©', 'dé'),
    ('Ã©', 'é'),
    ('Ã¨', 'è'),
    ('Ãª', 'ê'),
    ('HaÃ¯ti', 'Haïti'),
    ('Ã¯', 'ï'),
    ('Ã§', 'ç'),
    ('PÃ©', 'Pé'),
    ('Ã¢', 'â'),
    ('Ã´', 'ô'),
    ('Ã‰', 'É'),
    ('Ã€', 'À'),
    ('Ã', 'é'),  # fallback
]

for f in base.rglob('*.html'):
    if 'flutter_app' in str(f):
        continue
    try:
        content = f.read_text(encoding='utf-8', errors='ignore')
        original = content
        for old, new in replacements:
            content = content.replace(old, new)
        if content != original:
            f.write_text(content, encoding='utf-8')
            print(f'✓ {f.relative_to(base)}')
    except Exception as e:
        print(f'❌ {f.name}: {e}')

print('Done!')
