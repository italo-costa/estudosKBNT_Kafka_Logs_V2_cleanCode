#!/usr/bin/env python3
"""
Kubernetes Performance Tester for Both Branches
Creates separate namespaces for each branch
"""

import subprocess
import time
import json
import requests
import statistics
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed
import yaml

class KubernetesPerformanceTester:
    """Testa performance usando Kubernetes com namespaces separados"""
    
    def __init__(self):
        self.base_path = "/mnt/c/workspace/estudosKBNT_Kafka_Logs"
        self.namespaces = {
            'master': 'performance-test-master',
            'refactoring-clean-architecture-v2.1': 'performance-test-refactoring'
        }
        self.results = {}
        
    def run_wsl_command(self, command, capture_output=True):
        """Executa comando no WSL Ubuntu"""
        try:
            full_command = f'wsl -d Ubuntu -- bash -c "cd {self.base_path} && {command}"'
            print(f"🔧 K8s: {command}")
            
            result = subprocess.run(
                full_command,
                shell=True,
                capture_output=capture_output,
                text=True,
                timeout=300
            )
            
            if result.returncode == 0:
                return result.stdout.strip() if capture_output else "Success"
            else:
                print(f"❌ Erro K8s: {result.stderr}")
                return None
                
        except subprocess.TimeoutExpired:
            print(f"⏰ Timeout K8s: {command}")
            return None
        except Exception as e:
            print(f"💥 Exceção K8s: {e}")
            return None
    
    def create_namespace_config(self, branch_name):
        """Cria configuração do namespace para a branch"""
        namespace = self.namespaces[branch_name]
        
        # Criar namespace YAML
        namespace_yaml = f"""
apiVersion: v1
kind: Namespace
metadata:
  name: {namespace}
  labels:
    branch: {branch_name.replace('/', '-')}
    test-type: performance
---
apiVersion: v1
kind: Service
metadata:
  name: api-gateway-service
  namespace: {namespace}
spec:
  selector:
    app: api-gateway
  ports:
    - port: 8080
      targetPort: 8080
      nodePort: {30080 if 'master' in branch_name else 30081}
  type: NodePort
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  namespace: {namespace}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api-gateway
  template:
    metadata:
      labels:
        app: api-gateway
    spec:
      containers:
      - name: api-gateway
        image: kbnt-api-gateway:{branch_name.replace('/', '-')}
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "kubernetes"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
"""
        
        filename = f"k8s-{branch_name.replace('/', '-')}.yaml"
        with open(filename, 'w') as f:
            f.write(namespace_yaml)
        
        return filename
    
    def build_and_tag_images(self, branch_name):
        """Constrói e tagea imagens para a branch específica"""
        print(f"🔨 Construindo imagens para {branch_name}...")
        
        # Checkout da branch
        result = self.run_wsl_command(f"git checkout {branch_name}")
        if not result:
            return False
        
        # Build das imagens com tag específica
        tag = branch_name.replace('/', '-')
        
        services = [
            "api-gateway",
            "log-analytics-service", 
            "log-consumer-service",
            "log-producer-service"
        ]
        
        for service in services:
            build_cmd = f"docker build -t kbnt-{service}:{tag} ./05-microservices/{service}/"
            result = self.run_wsl_command(build_cmd, False)
            if not result:
                print(f"❌ Falha ao buildar {service}")
                return False
        
        return True
    
    def deploy_branch_to_k8s(self, branch_name):
        """Deploy da branch no Kubernetes"""
        print(f"🚀 Fazendo deploy de {branch_name} no K8s...")
        
        namespace = self.namespaces[branch_name]
        
        # Criar namespace
        self.run_wsl_command(f"kubectl create namespace {namespace} --dry-run=client -o yaml | kubectl apply -f -")
        
        # Aplicar configurações
        config_file = self.create_namespace_config(branch_name)
        result = self.run_wsl_command(f"kubectl apply -f {config_file}")
        
        if not result:
            print(f"❌ Falha no deploy de {branch_name}")
            return False
        
        # Aguardar pods ficarem prontos
        print(f"⏳ Aguardando pods de {namespace} ficarem prontos...")
        self.run_wsl_command(f"kubectl wait --for=condition=ready pod --all -n {namespace} --timeout=300s")
        
        return True
    
    def get_service_endpoints(self, branch_name):
        """Obtém endpoints dos serviços no K8s"""
        namespace = self.namespaces[branch_name]
        
        # Listar serviços
        result = self.run_wsl_command(f"kubectl get services -n {namespace} -o json")
        
        if not result:
            return []
        
        try:
            services = json.loads(result)
            endpoints = []
            
            for service in services['items']:
                if service['spec']['type'] == 'NodePort':
                    for port in service['spec']['ports']:
                        if 'nodePort' in port:
                            endpoint = f"http://localhost:{port['nodePort']}"
                            endpoints.append(endpoint)
            
            return endpoints
            
        except Exception as e:
            print(f"❌ Erro ao parsear serviços: {e}")
            return []
    
    def test_k8s_performance(self, branch_name, num_requests=1000):
        """Testa performance da branch no Kubernetes"""
        print(f"\n🎯 TESTANDO {branch_name} NO KUBERNETES")
        print("=" * 50)
        
        # Build e deploy
        if not self.build_and_tag_images(branch_name):
            print(f"❌ Falha no build para {branch_name}")
            return None
            
        if not self.deploy_branch_to_k8s(branch_name):
            print(f"❌ Falha no deploy para {branch_name}")
            return None
        
        # Aguardar estabilização
        time.sleep(60)
        
        # Obter endpoints
        endpoints = self.get_service_endpoints(branch_name)
        
        if not endpoints:
            print(f"❌ Nenhum endpoint encontrado para {branch_name}")
            return None
        
        # Executar testes de performance
        branch_results = {
            'branch': branch_name,
            'namespace': self.namespaces[branch_name],
            'timestamp': datetime.now().isoformat(),
            'endpoints': {},
            'summary': {}
        }
        
        for endpoint in endpoints:
            print(f"📊 Testando {endpoint}...")
            test_result = self.perform_load_test(endpoint, num_requests)
            branch_results['endpoints'][endpoint] = test_result
        
        return branch_results
    
    def perform_load_test(self, endpoint, num_requests=1000):
        """Executa teste de carga (mesmo do Docker tester)"""
        print(f"🎯 Testando {endpoint} com {num_requests} requisições...")
        
        results = {
            'successful_requests': 0,
            'failed_requests': 0,
            'latencies': [],
            'errors': [],
            'start_time': time.time()
        }
        
        def make_request():
            try:
                start = time.time()
                response = requests.get(endpoint, timeout=10)
                end = time.time()
                
                latency = (end - start) * 1000  # ms
                
                if response.status_code < 500:
                    return {'success': True, 'latency': latency, 'status': response.status_code}
                else:
                    return {'success': False, 'error': f"HTTP {response.status_code}", 'latency': latency}
                    
            except Exception as e:
                end = time.time()
                latency = (end - start) * 1000
                return {'success': False, 'error': str(e), 'latency': latency}
        
        # Executa requisições concorrentes
        with ThreadPoolExecutor(max_workers=10) as executor:
            futures = [executor.submit(make_request) for _ in range(num_requests)]
            
            for future in as_completed(futures):
                result = future.result()
                
                if result['success']:
                    results['successful_requests'] += 1
                    results['latencies'].append(result['latency'])
                else:
                    results['failed_requests'] += 1
                    results['errors'].append(result['error'])
                    if 'latency' in result:
                        results['latencies'].append(result['latency'])
        
        results['end_time'] = time.time()
        results['total_time'] = results['end_time'] - results['start_time']
        
        # Calcular métricas
        if results['latencies']:
            results['avg_latency'] = statistics.mean(results['latencies'])
            results['p95_latency'] = sorted(results['latencies'])[int(len(results['latencies']) * 0.95)]
            results['throughput'] = results['successful_requests'] / results['total_time']
            results['success_rate'] = (results['successful_requests'] / num_requests) * 100
        
        return results
    
    def cleanup_namespaces(self):
        """Limpa namespaces de teste"""
        print("🧹 Limpando namespaces de teste...")
        
        for namespace in self.namespaces.values():
            self.run_wsl_command(f"kubectl delete namespace {namespace} --ignore-not-found=true")
    
    def compare_k8s_performance(self):
        """Compara performance entre branches no K8s"""
        print("🎯 COMPARAÇÃO DE PERFORMANCE NO KUBERNETES")
        print("=" * 60)
        
        try:
            # Limpar namespaces existentes
            self.cleanup_namespaces()
            
            # Testar master
            master_results = self.test_k8s_performance("master", 500)
            
            # Testar refactoring
            refactoring_results = self.test_k8s_performance("refactoring-clean-architecture-v2.1", 500)
            
            if master_results and refactoring_results:
                # Gerar comparação
                comparison = self.generate_comparison(master_results, refactoring_results)
                
                # Salvar resultados
                self.save_results(master_results, refactoring_results, comparison)
                
                return comparison
            else:
                print("❌ Falha nos testes")
                return None
                
        finally:
            # Cleanup final
            self.cleanup_namespaces()
    
    def generate_comparison(self, master_results, refactoring_results):
        """Gera comparação (implementar conforme necessário)"""
        # Similar ao Docker tester
        pass
    
    def save_results(self, master_results, refactoring_results, comparison):
        """Salva resultados (implementar conforme necessário)"""
        # Similar ao Docker tester
        pass

def main():
    print("☸️ Testador de Performance com Kubernetes")
    print("Criando namespaces separados para cada branch")
    print("=" * 50)
    
    # Verificar se kubectl está disponível
    try:
        subprocess.run(['wsl', '-d', 'Ubuntu', '--', 'kubectl', 'version', '--client'], 
                      check=True, capture_output=True)
        print("✅ kubectl disponível")
    except:
        print("❌ kubectl não disponível - use o testador Docker")
        return
    
    tester = KubernetesPerformanceTester()
    comparison = tester.compare_k8s_performance()
    
    if comparison:
        print("✅ Teste K8s concluído!")
    else:
        print("❌ Teste K8s falhou")

if __name__ == "__main__":
    main()
