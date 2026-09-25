ATUALIZAR GIT
git add .
git commit -m "feat: MVP contábil com auth, empresas, plano de contas e lançamentos"

# Subir tudo
~/contabil-start.sh

# Parar tudo
~/contabil-stop.sh

# Ver logs da API
contabil-logs

# Carregar credenciais no terminal
contabil-env

# Rodar testes
cd ~/Projetos/Contabil && npm test

# Recompilar após mudanças
cd ~/Projetos/Contabil && npm run build