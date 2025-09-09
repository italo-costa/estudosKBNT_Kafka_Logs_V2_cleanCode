#!/bin/bash

# Script de inicialização do PostgreSQL para Virtual Stock Service
# Este script garante que o banco de dados seja criado com as configurações corretas

set -e

echo "Inicializando banco de dados PostgreSQL para Virtual Stock Service..."

# Aguardar PostgreSQL estar pronto
until pg_isready -h localhost -p 5432 -U postgres; do
    echo "Aguardando PostgreSQL ficar disponível..."
    sleep 2
done

echo "PostgreSQL está disponível. Executando scripts de inicialização..."

# Executar script de inicialização
psql -h localhost -p 5432 -U postgres -d postgres -f /docker-entrypoint-initdb.d/init-postgres.sql

echo "Inicialização do banco de dados concluída com sucesso!"
