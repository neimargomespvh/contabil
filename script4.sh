cd /home/neimar/Projetos/Contabil

# Verificar se dist/ foi criado com os arquivos JS
ls -la dist/
ls -la dist/main.js 2>/dev/null && echo "✅ main.js gerado"

# Contar arquivos compilados
find dist -name "*.js" | wc -l
# Deve mostrar um número > 0