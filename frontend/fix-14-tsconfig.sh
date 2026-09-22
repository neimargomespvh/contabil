#!/usr/bin/env bash
set -e
cd /home/neimar/Projetos/Contabil/frontend

# ============================================================
# 1. SUBSTITUIR POR UM ÚNICO TSCONFIG
# ============================================================
cat > tsconfig.json <<'TSCONF_EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "useDefineForClassFields": true,
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "moduleDetection": "force",
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": false,
    "noUnusedParameters": false,
    "noFallthroughCasesInSwitch": true,
    "allowSyntheticDefaultImports": true,
    "esModuleInterop": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    },
    "types": ["vite/client", "node"]
  },
  "include": ["src", "vite.config.ts"]
}
TSCONF_EOF

# Remover os antigos
rm -f tsconfig.app.json tsconfig.node.json

# ============================================================
# 2. ADICIONAR TIPOS DO VITE
# ============================================================
cat > src/vite-env.d.ts <<'ENV_EOF'
/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_URL: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
ENV_EOF

# ============================================================
# 3. AJUSTAR PACKAGE.JSON (remover -b do tsc)
# ============================================================
node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.scripts.build = 'tsc && vite build';
pkg.scripts['type-check'] = 'tsc --noEmit';
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
console.log('✅ package.json atualizado');
"

# ============================================================
# 4. GARANTIR TIPOS INSTALADOS
# ============================================================
echo "📦 Instalando @types/node..."
npm install -D @types/node 2>/dev/null || true

echo ""
echo "✅ tsconfig corrigido"
echo ""
echo "Rode agora:"
echo "  npm run dev"