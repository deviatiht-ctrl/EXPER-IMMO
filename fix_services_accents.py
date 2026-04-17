#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Korije tout accent nan services.html
"""

from pathlib import Path

def fix_services_html():
    """Korije services.html"""
    filepath = Path('c:/Users/HACKER/Pictures/EXPER IMMO/services.html')
    
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        original = content
        
        # Korije tout mo ki gen pwoblèm
        replacements = {
            'efficacitéŒ': 'efficacité',
            'succŒs': 'succès',
            'immobiliŒres': 'immobilières',
            'HaŒti': 'Haïti',
            'complŒte': 'complète',
            'propriŒtaires': 'propriétaires',
            'gŒrons': 'gérons',
            'Œtat': 'état',
            'dŒtaillŒs': 'détaillés',
            'SŒlection': 'Sélection',
            'rŒparations': 'réparations',
            'propriŒtaire': 'propriétaire',
            'immobiliŒre': 'immobilière',
            'Œ notre': 'à notre',
            'Œééquipe': 'équipe',
            'accompagne Œ': 'accompagne à',
            'Œ chaque': 'à chaque',
            'Œétape': 'étape',
            'Œévaluation': 'évaluation',
            'acquŒreurs': 'acquéreurs',
            'qualifiŒs': 'qualifiés',
            'NŒgociation': 'Négociation',
            'dŒmarchéées': 'démarches',
            'rŒnovation': 'rénovation',
            'rŒgulier': 'régulier',
            'dŒtaillŒs': 'détaillés',
            'ContrŒle': 'Contrôle',
            'dŒpenses': 'dépenses',
            'RŒception': 'Réception',
            'AccŒdez Œ': 'Accédez à',
            'bord Œ': 'bord :',
            'personnaliséŒ': 'personnalisé',
            'AccŒs': 'Accès',
            'opŒration': 'opération',
            'intŒgrŒe': 'intégrée',
            'tŒlŒchargeables': 'téléchargeables',
            'grŒce Œ': 'grâce à',
            'personnaliséŒs': 'personnalisés',
            'marchééŒ': 'marché',
            'haŒtien': 'haïtien',
            'StratŒgie': 'Stratégie',
            'Œétude': 'étude',
            'Service Œ la ClientŒle': 'Service à la Clientèle',
            'rŒpondre Œ': 'répondre à',
            'dŒlais': 'délais',
            'dŒdiŒe': 'dédiée',
            'RŒponse': 'Réponse',
            'TraŒabilitŒ': 'Traçabilité',
            'Œéchanges': 'échanges',
            'FiabilitŒ': 'Fiabilité',
            'opŒration': 'opération',
            'tracŒe': 'tracée',
            'sŒcurisŒe': 'sécurisée',
            'RŒactivitŒ': 'Réactivité',
            'rŒpondons Œ': 'répondons à',
            'accŒs': 'accès',
            'donnŒes': 'données',
            'rŒel': 'réel',
            'expŒrience': 'expérience',
        }
        
        for wrong, correct in replacements.items():
            content = content.replace(wrong, correct)
        
        if content != original:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print("✓ services.html korije!")
            return True
        else:
            print("Pa gen chanjman")
            return False
        
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return False

if __name__ == '__main__':
    fix_services_html()
