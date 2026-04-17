#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Korije tout pwoblèm UTF-8 nan tout fichye HTML
"""

import os
from pathlib import Path

# Tout korèksyon encoding
REPLACEMENTS = {
    'ï¿½': 'é',
    'ï¿½': 'è',
    'ï¿½': 'à',
    'ï¿½': 'ù',
    'ï¿½': 'â',
    'ï¿½': 'ê',
    'ï¿½': 'î',
    'ï¿½': 'ô',
    'ï¿½': 'û',
    'ï¿½': 'ë',
    'ï¿½': 'ï',
    'ï¿½': 'ü',
    'ï¿½': 'ç',
    'ï¿½': 'É',
    'ï¿½': 'È',
    'ï¿½': 'À',
    'ï¿½': 'Ù',
    'ï¿½': 'Â',
    'ï¿½': 'Ê',
    'ï¿½': 'Î',
    'ï¿½': 'Ô',
    'ï¿½': 'Û',
    'ï¿½': 'Ë',
    'ï¿½': 'Ï',
    'ï¿½': 'Ü',
    'ï¿½': 'Ç',
    'ï¿½': 'œ',
    'ï¿½': 'Œ',
    'Ã©': 'é',
    'Ã¨': 'è',
    'Ã ': 'à',
    'Ã¹': 'ù',
    'Ã¢': 'â',
    'Ãª': 'ê',
    'Ã®': 'î',
    'Ã´': 'ô',
    'Ã»': 'û',
    'Ã«': 'ë',
    'Ã¯': 'ï',
    'Ã¼': 'ü',
    'Ã§': 'ç',
    'Ã‰': 'É',
    'Ãˆ': 'È',
    '€': '€',
}

def fix_file(filepath):
    """Korije yon fichye HTML"""
    try:
        # Li fichye a
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        original = content
        
        # Aplike tout ranplasman
        for wrong, correct in REPLACEMENTS.items():
            content = content.replace(wrong, correct)
        
        # Korije mo espesifik
        content = content.replace('efficacit', 'efficacité')
        content = content.replace('immobilires', 'immobilières')
        content = content.replace('proposons', 'proposons')
        content = content.replace('complte', 'complète')
        content = content.replace('propritaires', 'propriétaires')
        content = content.replace('locataires', 'locataires')
        content = content.replace('Gestion Locative', 'Gestion Locative')
        content = content.replace('grens', 'gérons')
        content = content.replace('locataires', 'locataires')
        content = content.replace('tats', 'états')
        content = content.replace('dtaills', 'détaillés')
        content = content.replace('slection', 'sélection')
        content = content.replace('rigoureuse', 'rigoureuse')
        content = content.replace('rparations', 'réparations')
        content = content.replace('mensuels', 'mensuels')
        content = content.replace('Transaction Immobilire', 'Transaction Immobilière')
        content = content.replace('quipe', 'équipe')
        content = content.replace('accompagne', 'accompagne')
        content = content.replace('chane', 'chaque')
        content = content.replace('tape', 'étape')
        content = content.replace('expertise', 'expertise')
        content = content.replace('valuation', 'évaluation')
        content = content.replace('acqureurs', 'acquéreurs')
        content = content.replace('qualifis', 'qualifiés')
        content = content.replace('Ngociation', 'Négociation')
        content = content.replace('dmarches', 'démarches')
        content = content.replace('juridiques', 'juridiques')
        content = content.replace('investissement', 'investissement')
        content = content.replace('Gestion de Construction', 'Gestion de Construction')
        content = content.replace('Supervision', 'Supervision')
        content = content.replace('complte', 'complète')
        content = content.replace('rnovation', 'rénovation')
        content = content.replace('rgulier', 'régulier')
        content = content.replace('Coordination', 'Coordination')
        content = content.replace('prestataires', 'prestataires')
        content = content.replace('dtaills', 'détaillés')
        content = content.replace('avancement', 'avancement')
        content = content.replace('Contrle', 'Contrôle')
        content = content.replace('dpenses', 'dépenses')
        content = content.replace('Rception', 'Réception')
        content = content.replace('travaux', 'travaux')
        content = content.replace('Espace Client Digital', 'Espace Client Digital')
        content = content.replace('Accdez', 'Accédez')
        content = content.replace('informations', 'informations')
        content = content.replace('tableau', 'tableau')
        content = content.replace('bord', 'bord')
        content = content.replace('loyers', 'loyers')
        content = content.replace('factures', 'factures')
        content = content.replace('documents', 'documents')
        content = content.replace('personnalis', 'personnalisé')
        content = content.replace('rapports', 'rapports')
        content = content.replace('dopnration', 'd\'opération')
        content = content.replace('finances', 'finances')
        content = content.replace('Messagerie', 'Messagerie')
        content = content.replace('intgre', 'intégrée')
        content = content.replace('tlchargeables', 'téléchargeables')
        content = content.replace('Conseil Patrimonial', 'Conseil Patrimonial')
        content = content.replace('Optimisez', 'Optimisez')
        content = content.replace('patrimoine', 'patrimoine')
        content = content.replace('grce', 'grâce')
        content = content.replace('conseils', 'conseils')
        content = content.replace('personnaliss', 'personnalisés')
        content = content.replace('connaissance', 'connaissance')
        content = content.replace('approfondie', 'approfondie')
        content = content.replace('march', 'marché')
        content = content.replace('hatien', 'haïtien')
        content = content.replace('portefeuille', 'portefeuille')
        content = content.replace('Stratgie', 'Stratégie')
        content = content.replace('investissement', 'investissement')
        content = content.replace('tude', 'étude')
        content = content.replace('rendement', 'rendement')
        content = content.replace('locatif', 'locatif')
        content = content.replace('juridique', 'juridique')
        content = content.replace('Service  la Clientle', 'Service à la Clientèle')
        content = content.replace('quipe', 'équipe')
        content = content.replace('disponible', 'disponible')
        content = content.replace('rpondre', 'répondre')
        content = content.replace('questions', 'questions')
        content = content.replace('traiter', 'traiter')
        content = content.replace('demandes', 'demandes')
        content = content.replace('meilleurs', 'meilleurs')
        content = content.replace('dlai', 'délais')
        content = content.replace('ddie', 'dédiée')
        content = content.replace('propritaires', 'propriétaires')
        content = content.replace('locataires', 'locataires')
        content = content.replace('Rponse', 'Réponse')
        content = content.replace('rapide', 'rapide')
        content = content.replace('garantie', 'garantie')
        content = content.replace('Traabilit', 'Traçabilité')
        content = content.replace('changes', 'échanges')
        content = content.replace('Pourquoi nous choisir', 'Pourquoi nous choisir')
        content = content.replace('Nos engagements', 'Nos engagements')
        content = content.replace('Fiabilit totale', 'Fiabilité totale')
        content = content.replace('opration', 'opération')
        content = content.replace('trace', 'tracée')
        content = content.replace('scurise', 'sécurisée')
        content = content.replace('plateforme', 'plateforme')
        content = content.replace('Ractivit', 'Réactivité')
        content = content.replace('rpondons', 'répondons')
        content = content.replace('demandes', 'demandes')
        content = content.replace('Transparence', 'Transparence')
        content = content.replace('Rapports', 'Rapports')
        content = content.replace('clairs', 'clairs')
        content = content.replace('accs', 'accès')
        content = content.replace('complet', 'complet')
        content = content.replace('donnes', 'données')
        content = content.replace('temps', 'temps')
        content = content.replace('rel', 'réel')
        content = content.replace('Expertise locale', 'Expertise locale')
        content = content.replace('expérience', 'expérience')
        content = content.replace('profonde', 'profonde')
        content = content.replace('connaissance', 'connaissance')
        content = content.replace('march', 'marché')
        content = content.replace('Prêt  commencer', 'Prêt à commencer')
        content = content.replace('Prêt ', 'Prêt ')
        content = content.replace('nous confier', 'nous confier')
        content = content.replace('votre bien', 'votre bien')
        content = content.replace('Rejoignez', 'Rejoignez')
        content = content.replace('propritaires', 'propriétaires')
        content = content.replace('locataires', 'locataires')
        content = content.replace('confiance', 'confiance')
        content = content.replace('gestion', 'gestion')
        content = content.replace('patrimoine', 'patrimoine')
        content = content.replace('immobilier', 'immobilier')
        content = content.replace('propritaire', 'propriétaire')
        content = content.replace('Nous contacter', 'Nous contacter')
        
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
        if fix_file(filepath):
            print(f"✓ {filepath.name}")
            fixed += 1
    
    print("=" * 50)
    print(f"Korije: {fixed} fichye")

if __name__ == '__main__':
    main()
