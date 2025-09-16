# Test connectivity to Virtual Stock Service
$url = "http://localhost:8084/actuator/health"
Write-Host "Testing connection to: $url"

try {
    $response = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 10
    Write-Host "SUCCESS: Application is responding!" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json -Depth 2)" -ForegroundColor Cyan
    
    # Test API endpoint
    $apiUrl = "http://localhost:8084/api/v1/virtual-stock/stocks"
    Write-Host "`nTesting API endpoint: $apiUrl"
    $apiResponse = Invoke-RestMethod -Uri $apiUrl -Method Get -TimeoutSec 10
    Write-Host "API SUCCESS: $($apiResponse.message)" -ForegroundColor Green
    Write-Host "Data Count: $($apiResponse.data.Count) stocks" -ForegroundColor Cyan
    
} catch {
    Write-Host "FAILURE: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Error Details: $($_.Exception.InnerException.Message)" -ForegroundColor Yellow
}