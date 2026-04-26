import os
import re

count = 0
for root, dirs, files in os.walk('.'):
    for file in files:
        if file.endswith('.html'):
            filepath = os.path.join(root, file)
            try:
                with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                
                original = content
                # Replace relative paths with absolute paths
                content = re.sub(r'href="css/', 'href="/css/', content)
                content = re.sub(r'href="js/', 'href="/js/', content)
                content = re.sub(r'href="assets/', 'href="/assets/', content)
                content = re.sub(r'href="\.\./css/', 'href="/css/', content)
                content = re.sub(r'href="\.\./js/', 'href="/js/', content)
                content = re.sub(r'href="\.\./assets/', 'href="/assets/', content)
                content = re.sub(r'href="\.\./\.\./assets/', 'href="/assets/', content)
                content = re.sub(r'src="js/', 'src="/js/', content)
                content = re.sub(r'src="css/', 'src="/css/', content)
                content = re.sub(r'src="assets/', 'src="/assets/', content)
                content = re.sub(r'src="\.\./js/', 'src="/js/', content)
                content = re.sub(r'src="\.\./css/', 'src="/css/', content)
                content = re.sub(r'src="\.\./assets/', 'src="/assets/', content)
                content = re.sub(r'src="\.\./\.\./assets/', 'src="/assets/', content)
                content = re.sub(r"import CONFIG from '[^']*/js/", "import CONFIG from '/js/", content)
                content = re.sub(r'import CONFIG from "[^"]*/js/', 'import CONFIG from "/js/', content)
                
                if content != original:
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(content)
                    count += 1
                    print(f'Fixed: {filepath}')
            except Exception as e:
                print(f'Error with {filepath}: {e}')

print(f'\nTotal files fixed: {count}')
