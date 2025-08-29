# Dockerfile para Log Producer Service
FROM eclipse-temurin:17-jdk-alpine AS builder

WORKDIR /app
COPY pom.xml .
COPY src ./src

# Build da aplicação
RUN ./mvnw clean package -DskipTests

# Imagem final
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Criar usuário não-root
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Copiar JAR
COPY --from=builder /app/target/*.jar app.jar

# Configurações do container
RUN chown -R appuser:appgroup /app
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8081/actuator/health || exit 1

# Exposição de portas
EXPOSE 8081 9081

# Comando de inicialização
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
