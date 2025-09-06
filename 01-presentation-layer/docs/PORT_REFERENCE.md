# REFERÊNCIA DE PORTAS PADRÃO

## Infraestrutura
- PostgreSQL: 5432
- Redis: 6379 
- Zookeeper: 2181
- Kafka: 9092, 29092

## Microserviços (Externa:Interna)
- API Gateway: 8080:8080, 9080:9090
- Log Producer: 8081:8080, 9081:9090
- Log Consumer: 8082:8080, 9082:9090
- Log Analytics: 8083:8080, 9083:9090
- Virtual Stock: 8084:8080, 9084:9090
- KBNT Consumer: 8085:8080, 9085:9090

## URLs de Acesso
- API Gateway: http://localhost:8080
- Log Producer: http://localhost:8081
- Log Consumer: http://localhost:8082  
- Log Analytics: http://localhost:8083
- Virtual Stock: http://localhost:8084
- KBNT Consumer: http://localhost:8085

## Health Checks
- API Gateway: http://localhost:8080/actuator/health
- Log Producer: http://localhost:8081/actuator/health
- Log Consumer: http://localhost:8082/actuator/health
- Log Analytics: http://localhost:8083/actuator/health
- Virtual Stock: http://localhost:8084/actuator/health
- KBNT Consumer: http://localhost:8085/actuator/health
