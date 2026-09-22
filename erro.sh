# 1. Docker está ativo?
sudo systemctl status docker --no-pager

# 2. Containers estão rodando?
docker ps

# 3. Todos os containers (mesmo parados)?
docker ps -a

# 4. Algo está escutando na porta 5432?
sudo lsof -i :5432
# ou
sudo ss -tlnp | grep 5432

# 5. Postgres nativo está instalado?
which psql
systemctl status postgresql --no-pager 2>/dev/null