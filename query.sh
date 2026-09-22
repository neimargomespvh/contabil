docker exec -i contabil-postgres psql -U postgres -d contabil <<'SQL'
SELECT
  u.email,
  r.nome AS role,
  COUNT(rp.permission_id) AS total_permissoes
FROM users u
LEFT JOIN user_roles ur ON ur.user_id = u.id
LEFT JOIN roles r ON r.id = ur.role_id
LEFT JOIN role_permissions rp ON rp.role_id = r.id
WHERE u.email = 'neimargomes@gmail.com'
GROUP BY u.email, r.nome;
SQL