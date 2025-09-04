# Configuração do AMQ Streams para Ambiente Red Hat
# Configure estas variáveis com os valores reais do seu ambiente

# ===========================================
# CONFIGURAÇÕES DO CLUSTER AMQ STREAMS
# ===========================================

# Host e porta do Bootstrap Server
# Obtenha este valor do seu cluster AMQ Streams na Red Hat
export KAFKA_EXTERNAL_HOST="my-cluster-kafka-bootstrap-amq-streams.apps.openshift-cluster.example.com:443"

# Credenciais de autenticação SASL
# Crie um usuário específico no AMQ Streams para os microserviços
export KAFKA_USERNAME="microservices-user"
export KAFKA_PASSWORD="SecurePassword123!"

# ===========================================
# CONFIGURAÇÕES DE SEGURANÇA
# ===========================================

# Senhas dos keystores/truststores
# Use senhas fortes para os certificados
export KAFKA_TRUSTSTORE_PASSWORD="TruststorePass123!"
export KAFKA_KEYSTORE_PASSWORD="KeystorePass123!"

# Protocolo de segurança (não alterar para AMQ Streams)
export KAFKA_SECURITY_PROTOCOL="SASL_SSL"
export KAFKA_SASL_MECHANISM="SCRAM-SHA-512"

# ===========================================
# CONFIGURAÇÕES DOS TÓPICOS
# ===========================================

# Nomes dos tópicos (devem existir no AMQ Streams)
export KAFKA_TOPIC_APPLICATION_LOGS="application-logs"
export KAFKA_TOPIC_ERROR_LOGS="error-logs"
export KAFKA_TOPIC_AUDIT_LOGS="audit-logs"

# Consumer Group ID
export KAFKA_CONSUMER_GROUP="microservices-logs-consumer"

# ===========================================
# CONFIGURAÇÕES DE PERFORMANCE
# ===========================================

# Timeouts para conexões externas (valores aumentados)
export KAFKA_REQUEST_TIMEOUT_MS="60000"
export KAFKA_DELIVERY_TIMEOUT_MS="300000"
export KAFKA_RETRY_BACKOFF_MS="1000"

# Configurações do Consumer
export KAFKA_FETCH_MIN_BYTES="1024"
export KAFKA_FETCH_MAX_WAIT_MS="500"
export KAFKA_MAX_POLL_RECORDS="500"
export KAFKA_AUTO_OFFSET_RESET="earliest"

# ===========================================
# CONFIGURAÇÕES DO OPENSHIFT/KUBERNETES
# ===========================================

# Namespace onde os microserviços serão deployados
export K8S_NAMESPACE="microservices"

# Registry de imagens (se usando registry privado)
# export CONTAINER_REGISTRY="quay.io/myorg"

# ===========================================
# CONFIGURAÇÕES DE BANCO DE DADOS
# ===========================================

export DB_NAME="loganalytics"
export DB_USERNAME="loguser"
export DB_PASSWORD="LogPassword123!"

# ===========================================
# INSTRUÇÕES DE USO
# ===========================================

echo "=============================================="
echo "🔧 Configuração AMQ Streams - Red Hat"
echo "=============================================="
echo ""
echo "1. Configure as variáveis acima com os valores do seu ambiente Red Hat"
echo ""
echo "2. Para obter o Bootstrap Server:"
echo "   oc get kafka my-cluster -o=jsonpath='{.status.listeners[?(@.type==\"external\")].bootstrapServers}'"
echo ""
echo "3. Para criar usuário no AMQ Streams:"
echo "   oc apply -f - <<EOF"
echo "   apiVersion: kafka.strimzi.io/v1beta2"
echo "   kind: KafkaUser"
echo "   metadata:"
echo "     name: microservices-user"
echo "     labels:"
echo "       strimzi.io/cluster: my-cluster"
echo "   spec:"
echo "     authentication:"
echo "       type: scram-sha-512"
echo "     authorization:"
echo "       type: simple"
echo "       acls:"
echo "         - resource:"
echo "             type: topic"
echo "             name: \"*\""
echo "           operations: [Read, Write]"
echo "         - resource:"
echo "             type: group"
echo "             name: \"*\""
echo "           operations: [Read]"
echo "   EOF"
echo ""
echo "4. Para obter a senha do usuário:"
echo "   oc get secret microservices-user -o jsonpath='{.data.password}' | base64 -d"
echo ""
echo "5. Para criar os tópicos:"
echo "   oc apply -f - <<EOF"
echo "   apiVersion: kafka.strimzi.io/v1beta2"
echo "   kind: KafkaTopic"
echo "   metadata:"
echo "     name: application-logs"
echo "     labels:"
echo "       strimzi.io/cluster: my-cluster"
echo "   spec:"
echo "     partitions: 3"
echo "     replicas: 3"
echo "   ---"
echo "   apiVersion: kafka.strimzi.io/v1beta2"
echo "   kind: KafkaTopic"
echo "   metadata:"
echo "     name: error-logs"
echo "     labels:"
echo "       strimzi.io/cluster: my-cluster"
echo "   spec:"
echo "     partitions: 3"
echo "     replicas: 3"
echo "   ---"
echo "   apiVersion: kafka.strimzi.io/v1beta2"
echo "   kind: KafkaTopic"
echo "   metadata:"
echo "     name: audit-logs"
echo "     labels:"
echo "       strimzi.io/cluster: my-cluster"
echo "   spec:"
echo "     partitions: 3"
echo "     replicas: 3"
echo "   EOF"
echo ""
echo "6. Para obter certificados TLS:"
echo "   oc get secret my-cluster-cluster-ca-cert -o jsonpath='{.data.ca\.crt}' | base64 -d > ca.crt"
echo "   keytool -import -trustcacerts -alias root -file ca.crt -keystore truststore.jks -storepass \$KAFKA_TRUSTSTORE_PASSWORD -noprompt"
echo ""
echo "7. Após configurar, execute o deploy:"
echo "   ./deploy.sh deploy"
echo ""
echo "=============================================="
