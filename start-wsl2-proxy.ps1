# Proxy HTTP Node.js para resolver problema WSL2 -> Windows
# Este proxy roda no Windows e encaminha requisições para o WSL2

$proxyCode = @'
const http = require('http');
const httpProxy = require('http-proxy');

// Configuração do proxy
const WSL_IP = '172.30.221.62';
const WSL_PORT = 8084;
const PROXY_PORT = 8085;

// Criar proxy
const proxy = httpProxy.createProxyServer({});

// Criar servidor proxy
const server = http.createServer((req, res) => {
    // Headers CORS para Postman
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    
    if (req.method === 'OPTIONS') {
        res.writeHead(200);
        res.end();
        return;
    }
    
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.url} -> http://${WSL_IP}:${WSL_PORT}`);
    
    proxy.web(req, res, {
        target: `http://${WSL_IP}:${WSL_PORT}`,
        changeOrigin: true
    });
});

// Tratamento de erros
proxy.on('error', (err, req, res) => {
    console.error('Proxy Error:', err.message);
    res.writeHead(500, { 'Content-Type': 'text/plain' });
    res.end('Proxy Error: ' + err.message);
});

// Iniciar servidor
server.listen(PROXY_PORT, () => {
    console.log('🚀 KBNT WSL2 Proxy Server iniciado!');
    console.log(`📡 Proxy: http://localhost:${PROXY_PORT}`);
    console.log(`🎯 Target: http://${WSL_IP}:${WSL_PORT}`);
    console.log('');
    console.log('✅ USE NO POSTMAN: http://localhost:8085/api/v1/virtual-stock/stocks');
    console.log('');
    console.log('Pressione Ctrl+C para parar...');
});
'@

# Verificar se Node.js está instalado
try {
    $nodeVersion = node --version 2>$null
    Write-Host "✅ Node.js encontrado: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js não encontrado!" -ForegroundColor Red
    Write-Host "💡 Instale Node.js: https://nodejs.org/" -ForegroundColor Yellow
    Write-Host "📝 Ou use a solução alternativa abaixo..." -ForegroundColor Cyan
    exit 1
}

# Criar arquivo do proxy
$proxyCode | Out-File -FilePath "wsl2-proxy.js" -Encoding UTF8

Write-Host "🔧 Criando proxy HTTP para resolver problema WSL2..." -ForegroundColor Cyan

# Instalar dependência se necessário
try {
    npm list http-proxy 2>$null | Out-Null
} catch {
    Write-Host "📦 Instalando http-proxy..." -ForegroundColor Yellow
    npm install http-proxy
}

Write-Host ""
Write-Host "🚀 Iniciando proxy em segundo plano..." -ForegroundColor Green
Write-Host "📡 Proxy disponível em: http://localhost:8085" -ForegroundColor Cyan
Write-Host "🎯 Redirecionando para: http://172.30.221.62:8084" -ForegroundColor Yellow
Write-Host ""
Write-Host "✅ USE ESTA URL NO POSTMAN:" -ForegroundColor Green
Write-Host "   http://localhost:8085/api/v1/virtual-stock/stocks" -ForegroundColor White
Write-Host ""

# Iniciar proxy
Start-Process node -ArgumentList "wsl2-proxy.js" -WindowStyle Hidden

Write-Host "🎉 Proxy iniciado! Teste no Postman agora!" -ForegroundColor Green
