@echo off
cd /d "%~dp0"
echo ===================================================
echo Starting Findora Smart Campus Lost and Found Portal
echo URL: http://localhost:8080/findora/home
echo ===================================================
java -cp "target/classes;target/dependency/*" com.findora.FindoraServer
pause

