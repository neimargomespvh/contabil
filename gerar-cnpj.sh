cd ~/Projetos/Contabil

cat > gerar-cnpj.sh <<'EOF'
#!/usr/bin/env bash
# Gera um CNPJ válido aleatório

gera_dv() {
  local base=$1
  local pesos=$2
  local soma=0
  for i in $(seq 0 $((${#base} - 1))); do
    soma=$((soma + ${base:$i:1} * ${pesos:$i:1}))
  done
  local resto=$((soma % 11))
  if [ $resto -lt 2 ]; then echo 0; else echo $((11 - resto)); fi
}

base=$(printf "%012d" $((RANDOM * RANDOM % 1000000000000)))
dv1=$(gera_dv "$base" "543298765432")
dv2=$(gera_dv "${base}${dv1}" "6543298765432")
echo "${base}${dv1}${dv2}"
EOF

chmod +x gerar-cnpj.sh
./gerar-cnpj.sh