#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ETAP 1: Korije tout senbòl kase nan tout fichye HTML
"""

from pathlib import Path

# Tout ranplasman yo nan lòd enpòtans
REPLACEMENTS = [
    # Bullet points kase
    ('â€¢', '•'),
    ('â€”', '—'),
    ('â€"', '–'),
    ('â€˜', "'"),
    ('â€™', "'"),
    ('â€œ', '"'),
    ('â€\x9d', '"'),
    ('â€¦', '…'),
    ('Â«', '«'),
    ('Â»', '»'),
    ('Â ', ' '),  # non-breaking space kase
    ('Â°', '°'),
    
    # UTF-8 doub-encode
    ('Ã©', 'é'),
    ('Ã¨', 'è'),
    ('Ã ', 'à'),
    ('Ã¹', 'ù'),
    ('Ã¢', 'â'),
    ('Ãª', 'ê'),
    ('Ã®', 'î'),
    ('Ã´', 'ô'),
    ('Ã»', 'û'),
    ('Ã«', 'ë'),
    ('Ã¯', 'ï'),
    ('Ã¼', 'ü'),
    ('Ã§', 'ç'),
    ('Ã‰', 'É'),
    ('Ãˆ', 'È'),
    ('Ã€', 'À'),
    ('Ã™', 'Ù'),
    ('Ã‚', 'Â'),
    ('ÃŠ', 'Ê'),
    ('ÃŽ', 'Î'),
    ('Ã"', 'Ô'),
    ('Ã›', 'Û'),
    ('Ã‡', 'Ç'),
    
    # Doub accent (erè previous fix)
    ('dééequipe', 'équipe'),
    ('éééquipe', 'équipe'),
    ('ééequipe', 'équipe'),
    ('Œééequipe', 'équipe'),
    ('déemarchéées', 'démarches'),
    ('démarchéées', 'démarches'),
    ('démarchées', 'démarches'),
    ('dééemarches', 'démarches'),
    ('Créééé', 'Créé'),
    ('Crééé', 'Créé'),
    ('réservéés', 'réservés'),
    ('propriééé', 'proprié'),
    ('marchééé', 'marché'),
    ('étééétape', 'étape'),
    ('Œétape', 'étape'),
    ('Œétude', 'étude'),
    ('Œéchanges', 'échanges'),
    ('Œétats', 'États'),
    ('Œévaluation', 'évaluation'),
    
    # Doub "À" tankou "À À Propos"
    ('À À Propos', 'À Propos'),
    ('a À Propos', 'À Propos'),
    ('é À Propos', 'À Propos'),
    ('À A Propos', 'À Propos'),
    
    # Haiti/Haïti fix
    ('Haéti', 'Haïti'),
    ('HaŒti', 'Haïti'),
    ('haéti', 'haïti'),
    ('haŒti', 'haïti'),
    ('Pétion', 'Pétion'),  # preserve good one
    
    # Espesyal chars kase
    ('Œ', 'é'),  # default fallback pou Œ
    ('ï¿½', 'é'),
    ('\ufffd', 'é'),
    
    # Retour À l'accueil
    ('Retour Ã  l\'accueil', "Retour à l'accueil"),
    ('Retour A l\'accueil', "Retour à l'accueil"),
    ('Connectez-vous Ã ', 'Connectez-vous à'),
    ('Connectez-vous A ', 'Connectez-vous à'),
    
    # "?? pour Haiti" kase (emoji)
    ('Fait avec ?? pour', 'Fait avec ❤ pour'),
    
    # PowerShell rezidi
    ('.Value -replace', ''),
    ('$12026', '© 2026'),
    ('$1', ''),
]

def fix_file(filepath):
    """Korije yon fichye HTML"""
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        original = content
        
        for wrong, correct in REPLACEMENTS:
            content = content.replace(wrong, correct)
        
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
    print("=" * 60)
    
    fixed = 0
    for filepath in sorted(html_files):
        if fix_file(filepath):
            rel_path = filepath.relative_to(base_dir)
            print(f"✓ {rel_path}")
            fixed += 1
    
    print("=" * 60)
    print(f"✅ Korije: {fixed} / {len(html_files)} fichye")

if __name__ == '__main__':
    main()
