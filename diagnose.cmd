@echo off
REM Monitoring Service Network Diagnostics Script for Windows
REM This script helps diagnose network connectivity issues between Prometheus and monitored services

echo 🔍 Prometheus Network Diagnostics
echo ==================================
echo.

REM Check if Prometheus container is running
echo 1. Checking Prometheus container status...
docker ps | findstr prometheus >nul
if %errorlevel% equ 0 (
    echo ✅ Prometheus container is running
) else (
    echo ❌ Prometheus container is not running
    echo    Start it with: docker compose up -d
    exit /b 1
)

echo.

REM Check DNS resolution
echo 2. Testing DNS resolution for host.docker.internal...
docker exec prometheus nslookup host.docker.internal >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ host.docker.internal resolves correctly
) else (
    echo ❌ Cannot resolve host.docker.internal
    echo    This may indicate a Docker configuration issue
)

echo.

REM Test ping to host
echo 3. Testing ping to host...
docker exec prometheus ping -c 2 host.docker.internal >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Can ping host.docker.internal
) else (
    echo ⚠️  Cannot ping host.docker.internal (may be blocked by firewall)
)

echo.

REM Test connectivity to services
echo 4. Testing connectivity to monitored services...
echo    Testing back-eradacustomers (port 4001)...
docker exec prometheus wget -q -O- --timeout=3 http://host.docker.internal:4001/actuator/health >nul 2>&1
if %errorlevel% equ 0 (echo    ✅ OK) else (echo    ❌ FAILED)

echo    Testing back-sso (port 4005)...
docker exec prometheus wget -q -O- --timeout=3 http://host.docker.internal:4005/actuator/health >nul 2>&1
if %errorlevel% equ 0 (echo    ✅ OK) else (echo    ❌ FAILED)

echo    Testing back-loans (port 40256)...
docker exec prometheus wget -q -O- --timeout=3 http://host.docker.internal:40256/actuator/health >nul 2>&1
if %errorlevel% equ 0 (echo    ✅ OK) else (echo    ❌ FAILED)

echo    Testing back-transactions (port 40254)...
docker exec prometheus wget -q -O- --timeout=3 http://host.docker.internal:40254/actuator/health >nul 2>&1
if %errorlevel% equ 0 (echo    ✅ OK) else (echo    ❌ FAILED)

echo.

REM Check Prometheus targets
echo 5. Checking Prometheus targets status...
curl -s http://localhost:9090/api/v1/targets >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Prometheus API accessible
    echo    View detailed status at: http://localhost:9090/targets
) else (
    echo ❌ Cannot access Prometheus API
)

echo.

REM Check Docker version
echo 6. Checking Docker version...
docker --version
echo    ✅ Docker version check complete

echo.
echo ==================================
echo ✅ Diagnostics complete!
echo.
echo 💡 Tips:
echo    - If services are unreachable, verify they bind to 0.0.0.0, not 127.0.0.1
echo    - Check firewall rules if ping fails but services are running
echo    - View Prometheus targets: http://localhost:9090/targets
echo    - Check Prometheus logs: docker logs prometheus

