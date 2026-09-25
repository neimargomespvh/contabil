cd ~/Projetos/Contabil

echo "═══════════════════════════════════════════"
echo "Arquivos que começam com 'cat >' ou contêm 'EOF'"
echo "═══════════════════════════════════════════"

find src -name "*.ts" -type f | while read f; do
  if head -5 "$f" | grep -q "^cat >"; then
    echo "❌ CORROMPIDO: $f"
  fi
done

echo ""
echo "═══════════════════════════════════════════"
echo "Linhas 'cat >' e 'EOF' em qualquer lugar"
echo "═══════════════════════════════════════════"

grep -rn "^cat >" src/ 2>/dev/null || echo "(nenhum)"
echo "---"
grep -rln "^EOF$" src/ 2>/dev/null || echo "(nenhum)"