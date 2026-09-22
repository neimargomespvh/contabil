curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Neimar Gomes",
    "email": "neimargomes@gmail.com",
    "senha": "200644ng",
    "nomeTenant": "Escritório F2",
    "cnpjTenant": "11222333000144"
  }'