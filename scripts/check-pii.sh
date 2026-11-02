#!/usr/bin/env bash
# PII sentinel scanner (bash). Zero exit = clean.
set -eo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"
EXCLUDE_DIRS=('.git' 'node_modules' 'dist' 'out' 'build')
EXCLUDE_FILES=('scripts/check-pii.js' 'scripts/check-pii.ps1' 'scripts/check-pii.sh' '.gitleaks.toml' 'CONTRIBUTING.md' 'SECURITY.md')
INC='-type f \( -name "*.md" -o -name "*.js" -o -name "*.ps1" -o -name "*.cmd" -o -name "*.sh" -o -name "*.py" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" -o -name "*.toml" -o -name "*.html" -o -name "*.css" -o -name "*.txt" \)'
PATTERNS=(
  'sk-ant-oat01-[A-Za-z0-9_-]{30,}'
  'sk-ant-ort01-[A-Za-z0-9_-]{30,}'
  'sk-ant-api03-[A-Za-z0-9_-]{30,}'
  '[a-z0-9._%+-]+@(?!example\.com|users\.noreply\.github\.com)[a-z0-9.-]+\.[a-z]{2,}'
  '[A-Z]:\\Users\\(?!<)[A-Za-z][a-zA-Z0-9_.-]{2,}'
  '(?!00000000-0000-0000-0000-)[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
)
hits=0
echo "scanning $REPO"
for p in "${PATTERNS[@]}"; do
  while IFS= read -r line; do
    skip=0
    for ef in "${EXCLUDE_FILES[@]}"; do
      if [[ "$line" == "./$ef"* ]]; then skip=1; break; fi
    done
    [[ $skip -eq 1 ]] && continue
    echo "$line"
    hits=$((hits + 1))
  done < <(grep -rnE --include='*.md' --include='*.js' --include='*.ps1' --include='*.cmd' --include='*.sh' --include='*.py' --include='*.json' --include='*.yaml' --include='*.yml' --include='*.toml' --include='*.html' --include='*.css' --include='*.txt' --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=dist --exclude-dir=out --exclude-dir=build "$p" . 2>/dev/null || true)
done
echo ""
if [[ $hits -eq 0 ]]; then echo '[OK] no sentinel hits'; exit 0
else echo "[FAIL] $hits sentinel hit(s)"; exit 1; fi
