cd ~/Projetos/Contabil
find src -name "*plano*padrao*" -o -name "*plano-padrao*" | head -5
cat $(find src -name "*plano*padrao*" -o -name "*plano-padrao*" | head -1)