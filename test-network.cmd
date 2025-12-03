@echo off
REM Quick Network Test Script for Windows
REM Tests if host.docker.internal works from Prometheus container

echo Testing host.docker.internal connectivity...
echo.

REM Check if Prometheus container is running
docker ps | findstr prometheus >nul
if %errorlevel% neq 0 (
    echo Prometheus container is not running!
    echo Start it with: docker compose up -d
    exit /b 1
)

echo 1. Testing DNS resolution...
docker exec prometheus nslookup host.docker.internal >nul 2>&1
if %errorlevel% equ 0 (
    echo    DNS resolution works!
) else (
    echo    DNS resolution failed!
    exit /b 1
)

echo.
echo 2. Testing HTTP connectivity to a service...
echo    Testing: http://host.docker.internal:4005/actuator/health
docker exec prometheus wget -q -O- --timeout=5 http://host.docker.internal:4005/actuator/health >nul 2>&1
if %errorlevel% equ 0 (
    echo    HTTP connectivity works! host.docker.internal is working correctly.
) else (
    echo    HTTP connectivity failed!
    echo.
    echo    Troubleshooting:
    echo    - Check if service is running on port 4005
    echo    - Verify service binds to 0.0.0.0, not 127.0.0.1
    exit /b 1
)

echo.
echo All tests passed! host.docker.internal is working correctly.

