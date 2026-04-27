#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script pou migrate tout fichye JS ki gen Supabase an apiClient
"""

import os
import re
from pathlib import Path

def migrate_js_file(filepath):
    """Migrate yon fichye JS soti nan Supabase an apiClient"""
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        original = content
        
        # Skip si deja gen apiClient import
        if 'apiClient' in content and 'supabase' not in content.lower():
            return False
        
        # 1. Remplase import Supabase pa apiClient
        content = re.sub(
            r"import\s+\{\s*supabaseClient\s+as\s+supabase\s*\}\s+from\s+['\"]\.\./supabase-client\.js['\"];?",
            "import { apiClient } from '../api-client.js';",
            content
        )
        
        # 2. Remplase checkAuth ak localStorage
        old_auth = r"async function checkAuth\(\)\s*\{\s*const\s+\{\s*data:\s*\{\s*user\s*\}\s*\}\s*=\s*await\s+supabase\.auth\.getUser\(\);\s*if\s*\(\s*!user\s*\)\s*\{\s*window\.location\.href\s*=\s*['\"]\.\./login\.html['\"];\s*return;\s*\}\s*const\s+\{\s*data:\s*profile\s*\}\s*=\s*await\s+supabase\.from\(['\"]profiles['\"]\)\.select\(['\"]role['\"]\)\.eq\(['\"]id['\"],\s*user\.id\)\.single\(\);\s*if\s*\(profile\?\.role\s*!==?\s*['\"]admin['\"]\)\s*\{\s*window\.location\.href\s*=\s*['\"]\.\./index\.html['\"];\s*\}\s*\}"
        
        new_auth = """async function checkAuth() {
    const user = JSON.parse(localStorage.getItem('exper_immo_user') || '{}');
    const token = localStorage.getItem('exper_immo_token');
    if (!token || !user.id) { window.location.href = '../login.html'; return; }
    if (user.role !== 'admin') { window.location.href = '../index.html'; }
}"""
        content = re.sub(old_auth, new_auth, content, flags=re.DOTALL)
        
        # 3. Remplase logout
        content = re.sub(
            r"await\s+supabase\.auth\.signOut\(\);",
            "localStorage.removeItem('exper_immo_token'); localStorage.removeItem('exper_immo_user');",
            content
        )
        
        # 4. Remplase logout click handler
        content = re.sub(
            r"document\.getElementById\(['\"](\w+)['\"]\)\?\.addEventListener\(['\"]click['\"],\s*async\s*function\(\)\s*\{\s*await\s+supabase\.auth\.signOut\(\);",
            r"document.getElementById('\1')?.addEventListener('click', function() { localStorage.removeItem('exper_immo_token'); localStorage.removeItem('exper_immo_user');",
            content
        )
        
        # 5. Remplase select * from
        # supabase.from('table').select('*') -> apiClient.get('/table')
        content = re.sub(
            r"await\s+supabase\.from\(['\"](\w+)['\"]\)\.select\(['\"]\*['\"]\)",
            r"await apiClient.get('/\1')",
            content
        )
        
        # 6. Remplase select with fields
        content = re.sub(
            r"await\s+supabase\.from\(['\"](\w+)['\"]\)\.select\(['\"]([^'\"]+)['\"]\)",
            r"await apiClient.get('/\1')",
            content
        )
        
        # 7. Remplase insert
        content = re.sub(
            r"await\s+supabase\.from\(['\"](\w+)['\"]\)\.insert\(",
            r"await apiClient.post('/\1', ",
            content
        )
        
        # 8. Remplase update
        content = re.sub(
            r"await\s+supabase\.from\(['\"](\w+)['\"]\)\.update\(([^)]+)\)\.eq\(['\"](\w+)['\"],\s*([^)]+)\)",
            r"await apiClient.put('/\1/' + \4, \2)",
            content
        )
        
        # 9. Remplase delete
        content = re.sub(
            r"await\s+supabase\.from\(['\"](\w+)['\"]\)\.delete\(\)\.eq\(['\"](\w+)['\"],\s*([^)]+)\)",
            r"await apiClient.delete('/\1/' + \3)",
            content
        )
        
        # 10. Remplase { data, error } pa data sèlman
        content = re.sub(
            r"const\s*\{\s*data(?:,\s*error)?\s*\}\s*=\s*await\s+apiClient",
            "const data = await apiClient",
            content
        )
        content = re.sub(
            r"var\s*\{\s*data(?:,\s*error)?\s*\}\s*=\s*await\s+apiClient",
            "var data = await apiClient",
            content
        )
        content = re.sub(
            r"let\s*\{\s*data(?:,\s*error)?\s*\}\s*=\s*await\s+apiClient",
            "let data = await apiClient",
            content
        )
        
        # 11. Retire if (error) throw error
        content = re.sub(
            r"if\s*\(\s*error\s*\)\s*throw\s*error;?\s*",
            "",
            content
        )
        
        # 12. Retire { count: 'exact', head: true } - pa sipòte anko
        content = re.sub(
            r"\.select\(['\"]\*['\"],\s*\{\s*count:\s*['\"]exact['\"],\s*head:\s*true\s*\}\)",
            "",
            content
        )
        
        # 13. Remplase .order() pa sort nan endpoint (si posib)
        content = re.sub(
            r"\.order\(['\"](\w+)['\"],\s*\{\s*ascending:\s*(true|false)\s*\}\)",
            "",
            content
        )
        content = re.sub(
            r"\.order\(['\"](\w+)['\"]\)",
            "",
            content
        )
        
        # 14. Remplase .eq() pa paramèt URL (pa sipòte direkteman)
        content = re.sub(
            r"\.eq\(['\"](\w+)['\"],\s*([^)]+)\)",
            r"/* .eq('\1', \2) - TODO: filter nan server */",
            content
        )
        
        # 15. Remplase .single() pa premye eleman
        content = re.sub(
            r"\.single\(\)",
            "[0]",
            content
        )
        
        if content != original:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        return False
        
    except Exception as e:
        print(f"✗ Erreur: {filepath.name} - {e}")
        return False

def main():
    base_dir = Path('.')
    
    # Jwenn tout fichye JS
    js_files = list(base_dir.rglob('*.js'))
    
    # Eskli node_modules, .git, flutter_app, ak fichye deja koreje
    exclude = ['node_modules', '.git', 'flutter_app', 'supabase-client.js', 'api-client.js', 'auth.js', 'config.js']
    js_files = [f for f in js_files if not any(x in str(f) for x in exclude)]
    
    print(f"Total fichye JS: {len(js_files)}")
    print("=" * 60)
    
    fixed = 0
    for filepath in js_files:
        if migrate_js_file(filepath):
            print(f"✓ Migrate: {filepath}")
            fixed += 1
    
    print("=" * 60)
    print(f"Total migrate: {fixed}")

if __name__ == '__main__':
    main()
