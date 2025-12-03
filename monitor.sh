#!/bin/bash

# Monitoring Service Management Script

case "$1" in
  start)
    echo "🚀 Starting monitoring services..."
    docker compose up -d
    echo "✅ Services started!"
    echo "📊 Prometheus: http://localhost:9090"
    echo "🔔 Alertmanager: http://localhost:9093"
    ;;
  stop)
    echo "🛑 Stopping monitoring services..."
    docker compose down
    echo "✅ Services stopped!"
    ;;
  restart)
    echo "🔄 Restarting monitoring services..."
    docker compose restart
    echo "✅ Services restarted!"
    ;;
  status)
    echo "📊 Monitoring Services Status:"
    docker compose ps
    ;;
  logs)
    echo "📋 Showing logs (Ctrl+C to exit)..."
    docker compose logs -f
    ;;
  diagnose)
    echo "🔍 Running network diagnostics..."
    if [ -f "./diagnose.sh" ]; then
      chmod +x ./diagnose.sh
      ./diagnose.sh
    else
      echo "❌ diagnose.sh not found in current directory"
    fi
    ;;
  reload-prometheus)
    echo "🔄 Reloading Prometheus configuration..."
    curl -X POST http://localhost:9090/-/reload
    echo "✅ Prometheus configuration reloaded!"
    ;;
  reload-alertmanager)
    echo "🔄 Reloading Alertmanager configuration..."
    curl -X POST http://localhost:9093/-/reload
    echo "✅ Alertmanager configuration reloaded!"
    ;;
  validate-prometheus)
    echo "✔️ Validating Prometheus configuration..."
    docker exec prometheus promtool check config /etc/prometheus/prometheus.yml
    ;;
  validate-alertmanager)
    echo "✔️ Validating Alertmanager configuration..."
    docker exec alertmanager amtool config test /etc/alertmanager/alertmanager.yml
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|status|logs|diagnose|reload-prometheus|reload-alertmanager|validate-prometheus|validate-alertmanager}"
    exit 1
    ;;
esac

exit 0

