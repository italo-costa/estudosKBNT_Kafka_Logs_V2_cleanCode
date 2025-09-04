#!/bin/bash

# Script para build de todos os microserviços
echo "🏗️  Building all microservices..."

# Função para build de um microserviço
build_service() {
    local service_name=$1
    echo "📦 Building $service_name..."
    
    if [ -d "$service_name" ]; then
        cd "$service_name"
        if [ -f "pom.xml" ]; then
            mvn clean package -DskipTests
            if [ $? -eq 0 ]; then
                echo "✅ $service_name built successfully"
            else
                echo "❌ Failed to build $service_name"
                return 1
            fi
        else
            echo "⚠️  No pom.xml found in $service_name, skipping..."
        fi
        cd ..
    else
        echo "⚠️  Directory $service_name not found, skipping..."
    fi
}

# Lista de microserviços
services=(
    "log-producer-service"
    "log-consumer-service" 
    "log-analytics-service"
    "api-gateway"
)

# Build de cada serviço
for service in "${services[@]}"; do
    build_service "$service"
done

echo ""
echo "🎯 Build Summary:"
echo "=================="

# Verificar resultados
for service in "${services[@]}"; do
    if [ -f "$service/target/*.jar" ]; then
        echo "✅ $service - JAR created"
    else
        echo "❌ $service - No JAR found"
    fi
done

echo ""
echo "🚀 To run services:"
echo "==================="
echo "Java: java -jar service-name/target/service-name-1.0.0-SNAPSHOT.jar"
echo "Maven: cd service-name && mvn spring-boot:run"
echo "Docker: docker-compose up -d"

echo ""
echo "🏁 Build completed!"
