#!/usr/bin/env bash
set -e

# ---------- tsconfig.json ----------
cat > tsconfig.json <<'EOF'
{
  "compilerOptions": {
    "module": "commonjs",
    "declaration": true,
    "removeComments": true,
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true,
    "allowSyntheticDefaultImports": true,
    "target": "ES2022",
    "sourceMap": true,
    "outDir": "./dist",
    "baseUrl": "./",
    "incremental": true,
    "skipLibCheck": true,
    "strictNullChecks": true,
    "noImplicitAny": true,
    "strictBindCallApply": true,
    "forceConsistentCasingInFileNames": true,
    "noFallthroughCasesInSwitch": true,
    "esModuleInterop": true,
    "resolveJsonModule": true,
    "paths": {
      "@/*": ["src/*"],
      "@common/*": ["src/common/*"],
      "@config/*": ["src/config/*"],
      "@infra/*": ["src/infra/*"],
      "@modules/*": ["src/modules/*"]
    }
  },
  "exclude": ["node_modules", "dist", "coverage"]
}
EOF

# ---------- tsconfig.build.json ----------
cat > tsconfig.build.json <<'EOF'
{
  "extends": "./tsconfig.json",
  "exclude": ["node_modules", "test", "dist", "**/*spec.ts"]
}
EOF

# ---------- nest-cli.json ----------
cat > nest-cli.json <<'EOF'
{
  "$schema": "https://json.schemastore.org/nest-cli",
  "collection": "@nestjs/schematics",
  "sourceRoot": "src",
  "compilerOptions": {
    "deleteOutDir": true,
    "webpack": false,
    "tsConfigPath": "tsconfig.build.json"
  }
}
EOF

# ---------- .prettierrc ----------
cat > .prettierrc <<'EOF'
{
  "singleQuote": true,
  "trailingComma": "all",
  "printWidth": 100,
  "tabWidth": 2,
  "semi": true
}
EOF

# ---------- .gitignore ----------
cat > .gitignore <<'EOF'
node_modules/
dist/
build/
coverage/
.env
.env.local
.env.*.local
!.env.example
*.log
.DS_Store
.vscode/
.idea/
prisma/migrations/dev.db
*.db
*.sqlite
.cache/
EOF

echo "✅ Arquivos de configuração criados"
