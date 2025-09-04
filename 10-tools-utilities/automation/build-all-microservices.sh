#!/bin/bash
set -e

cd microservices/log-producer-service
mvn clean package -DskipTests

cd ../log-consumer-service
mvn clean package -DskipTests

cd ../log-analytics-service
mvn clean package -DskipTests

cd ../api-gateway
mvn clean package -DskipTests

cd ../virtual-stock-service
mvn clean package -DskipTests

cd ../kbnt-stock-consumer-service
mvn clean package -DskipTests

cd ../kbnt-log-service
mvn clean package -DskipTests

cd ../../..
echo "Build de todos os microserviços finalizado!"
