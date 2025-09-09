-- Inicialização do banco de dados PostgreSQL para Virtual Stock Service

-- Criar banco de dados virtualstock se não existir
CREATE DATABASE IF NOT EXISTS virtualstock;

-- Conectar ao banco virtualstock
\c virtualstock;

-- Criar tabela de stocks se não existir
CREATE TABLE IF NOT EXISTS stocks (
    id BIGSERIAL PRIMARY KEY,
    stock_code VARCHAR(10) NOT NULL UNIQUE,
    product_name VARCHAR(255) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 0,
    unit_price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Inserir dados de exemplo
INSERT INTO stocks (stock_code, product_name, quantity, unit_price) VALUES
('PROD001', 'Produto Exemplo 1', 100, 25.50),
('PROD002', 'Produto Exemplo 2', 50, 45.00),
('PROD003', 'Produto Exemplo 3', 200, 15.75)
ON CONFLICT (stock_code) DO NOTHING;

-- Criar índices para otimização
CREATE INDEX IF NOT EXISTS idx_stocks_code ON stocks(stock_code);
CREATE INDEX IF NOT EXISTS idx_stocks_created_at ON stocks(created_at);

-- Conceder permissões ao usuário postgres
GRANT ALL PRIVILEGES ON DATABASE virtualstock TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;
