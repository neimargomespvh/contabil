cd /home/neimar/Projetos/Contabil

# Subir os serviços em segundo plano
docker compose up -d

# Aguardar um pouco e verificar o status dos containers
sleep 10
docker compose ps