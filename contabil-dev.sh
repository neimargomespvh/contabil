cat > ~/contabil-dev.sh <<'EOF'
#!/usr/bin/env bash
# Abre 2 terminais: backend e frontend

gnome-terminal --tab --title="Backend" -- bash -c \
  "cd /home/neimar/Projetos/Contabil && npm run dev; exec bash" \
  --tab --title="Frontend" -- bash -c \
  "cd /home/neimar/Projetos/Contabil/frontend && npm run dev; exec bash"
EOF

chmod +x ~/contabil-dev.sh