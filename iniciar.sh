# 1. Subir Docker (só uma vez)
cd /home/neimar/Projetos/Contabil
docker compose up -d
sleep 10
docker compose ps

# 2. Terminal 1 — Backend
cd /home/neimar/Projetos/Contabil
npm run dev

# 3. Terminal 2 (outra aba) — Frontend
cd /home/neimar/Projetos/Contabil/frontend
npm run dev

# 4. Navegador
# http://localhost:5173