Set-Location $PSScriptRoot
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "Starting Findora Smart Campus Lost and Found Portal" -ForegroundColor Green
Write-Host "URL: http://localhost:8080/findora/home" -ForegroundColor Yellow
Write-Host "===================================================" -ForegroundColor Cyan
java -cp "target/classes;target/dependency/*" com.findora.FindoraServer

