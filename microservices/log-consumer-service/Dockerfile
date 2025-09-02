FROM eclipse-temurin:17-jdk AS builder

WORKDIR /app
COPY pom.xml .
COPY src ./src

# Instalar Maven
RUN apt-get update && apt-get install -y maven

# Build da aplicação
RUN mvn clean package -DskipTests

# Imagem final
FROM eclipse-temurin:17-jre

WORKDIR /app

# Criar usuário não-root
RUN groupadd -g 1001 appgroup && useradd -u 1001 -g appgroup appuser

# Copiar JAR
COPY --from=builder /app/target/*.jar app.jar

# Configurações do container
RUN chown -R appuser:appgroup /app
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
	CMD wget --no-verbose --tries=1 --spider http://localhost:8082/actuator/health || exit 1

EXPOSE 8082 9082

# Comando de inicialização
ENTRYPOINT ["java", "-jar", "app.jar"]
