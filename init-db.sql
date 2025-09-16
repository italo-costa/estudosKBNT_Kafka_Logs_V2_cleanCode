-- Criar usuário kbnt_user
CREATE USER kbnt_user WITH PASSWORD 'kbnt_2024';

-- Conceder privilégios
GRANT ALL PRIVILEGES ON DATABASE virtualstock TO kbnt_user;
GRANT ALL PRIVILEGES ON SCHEMA public TO kbnt_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO kbnt_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO kbnt_user;

-- Definir usuário como proprietário do schema public
ALTER SCHEMA public OWNER TO kbnt_user;
