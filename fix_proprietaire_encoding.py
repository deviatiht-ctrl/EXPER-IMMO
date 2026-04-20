#!/usr/bin/env python3
"""
Script pou korije tout pwoblèm enkodin nan fichye /proprietaire/*.html
Fiks: â€¢, Ã©, Ã¨, Ã , ak tout lòt senbòl kase
"""

import os
import glob

# Mapping tout senbòl kase → byen
REPLACEMENTS = {
    # Senbòl pou password (pi enpòtan)
    'â€¢': '•',
    'â\x80¢': '•',
    '\u2022': '•',  # Bullet unicode
    
    # Akant ak trema
    'Ã©': 'é',
    'Ã¨': 'è',
    'Ã ': 'à',
    'Ã¢': 'â',
    'Ã´': 'ô',
    'Ã»': 'û',
    'Ã´': 'ô',
    'Ã»': 'û',
    'Ã§': 'ç',
    'Å\x93': 'œ',
    'Å“': 'œ',
    'Å½': 'œ',
    'Ã ': 'à',
    'Ã\x80': 'À',
    'Ã\x89': 'É',
    'Ã\x88': 'È',
    'Ã\x8e': 'Î',
    'Ã\x8f': 'Ï',
    
    # Let ak trèm nan
    'Ã«': 'ë',
    'Ã¯': 'ï',
    'Ã¼': 'ü',
    'Ã¶': 'ö',
    'Ã¤': 'ä',
    'Ã\x8b': 'Ë',
    'Ã\x8f': 'Ï',
    'Ã\x9c': 'Ü',
    'Ã\x96': 'Ö',
    'Ã\x84': 'Ä',
    
    # Lòt senbòl
    'â\x80\x99': "'",   # Apostrof kwochi
    'â€™': "'",
    'â\x80\x9c': '"',    # Gwo koutasyon gòch
    'â\x80\x9d': '"',    # Gwo koutasyon dwat
    'â€œ': '"',
    'â€': '"',
    'â\x80\x98': "'",    # Ti koutasyon gòch
    'â\x80\x99': "'",    # Ti koutasyon dwat
    'â€˜': "'",
    'â€™': "'",
    'â\x80\x93': '–',    # Tiret
    'â\x80\x94': '—',
    'â€“': '–',
    'â€”': '—',
    'Â«': '«',
    'Â»': '»',
    'â\x80\x8b': '',      # Zero-width space
    'â\x80\x89': ' ',     # Thin space
    'Â\xa0': ' ',         # Non-breaking space
    'Ã‚': '',             # Kombinasyon kase
    
    # Non-breaking space
    '\xa0': ' ',
    '\xc2\xa0': ' ',
    
    # Pwoblèm espesyal Haïti
    'HaÃ¯ti': 'Haïti',
    'HaÃ¯': 'Haï',
    'Ã¯': 'ï',
    
    # Doublaj akant (lè gen 2 fwa menm bagay)
    'éé': 'é',
    'èè': 'è',
    'àà': 'à',
    'çç': 'ç',
}

def fix_file(filepath):
    """Korije yon sèl fichye"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original = content
        changes = []
        
        # Aplike tout ranplasman
        for old, new in REPLACEMENTS.items():
            if old in content:
                count = content.count(old)
                content = content.replace(old, new)
                changes.append(f"  {old!r} → {new!r} ({count} fwa)")
        
        # Si gen chanjman, save fichye a
        if content != original:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            return True, changes
        return False, []
        
    except Exception as e:
        return False, [f"  ERREUR: {e}"]

def main():
    proprietaire_dir = r"c:\Users\HACKER\Pictures\EXPER IMMO\proprietaire"
    
    # Jwenn tout fichye HTML nan proprietaire/
    html_files = glob.glob(os.path.join(proprietaire_dir, "*.html"))
    
    print("=" * 60)
    print("KORIKSyon ENKODIN nan /proprietaire/")
    print("=" * 60)
    
    total_fixed = 0
    
    for filepath in sorted(html_files):
        filename = os.path.basename(filepath)
        fixed, changes = fix_file(filepath)
        
        if fixed:
            print(f"\n✅ {filename}")
            for change in changes:
                print(change)
            total_fixed += 1
        else:
            print(f"\n⏭️  {filename} (pa gen chanjman)")
    
    print("\n" + "=" * 60)
    print(f"REZILTA: {total_fixed}/{len(html_files)} fichye korije")
    print("=" * 60)

if __name__ == "__main__":
    main()
