node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));

// Configuração do Prisma para seed
pkg.prisma = {
  seed: 'tsx prisma/seed.ts'
};

// Script para gerar o client
pkg.scripts['prisma:generate'] = 'prisma generate';

fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
console.log('✅ package.json atualizado');
"