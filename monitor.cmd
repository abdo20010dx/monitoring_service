@echo off
REM Monitoring Service Management Script for Windows

if "%1"=="start" (
    echo Starting monitoring services...
    docker compose up -d
    echo Services started!
    echo Prometheus: http://localhost:9090
    echo Alertmanager: http://localhost:9093
    goto :end
)

if "%1"=="stop" (
    echo Stopping monitoring services...
    docker compose down
    echo Services stopped!
    goto :end
)

if "%1"=="restart" (
    echo Restarting monitoring services...
    docker compose restart
    echo Services restarted!
    goto :end
)

if "%1"=="status" (
    echo Monitoring Services Status:
    docker compose ps
    goto :end
)

if "%1"=="logs" (
    echo Showing logs (Ctrl+C to exit)...
    docker compose logs -f
    goto :end
)

if "%1"=="diagnose" (
    echo Running network diagnostics...
    if exist "diagnose.cmd" (
        call diagnose.cmd
    ) else (
        echo diagnose.cmd not found in current directory
    )
    goto :end
)

if "%1"=="reload-prometheus" (
    echo Reloading Prometheus configuration...
    curl -X POST http://localhost:9090/-/reload
    echo Prometheus configuration reloaded!
    goto :end
)

if "%1"=="reload-alertmanager" (
    echo Reloading Alertmanager configuration...
    curl -X POST http://localhost:9093/-/reload
    echo Alertmanager configuration reloaded!
    goto :end
)

if "%1"=="validate-prometheus" (
    echo Validating Prometheus configuration...
    docker exec prometheus promtool check config /etc/prometheus/prometheus.yml
    goto :end
)

if "%1"=="validate-alertmanager" (
    echo Validating Alertmanager configuration...
    docker exec alertmanager amtool config test /etc/alertmanager/alertmanager.yml
    goto :end
)

echo Usage: %0 {start^|stop^|restart^|status^|logs^|diagnose^|reload-prometheus^|reload-alertmanager^|validate-prometheus^|validate-alertmanager}
exit /b 1

:end
exit /b 0

