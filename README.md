# Monitoring Service - Prometheus & Alertmanager

This monitoring service provides comprehensive monitoring and alerting for all Erada Finance Platform services using Prometheus and Alertmanager.

## 🏗️ Architecture

- **Prometheus**: Metrics collection and storage
- **Alertmanager**: Alert routing and notification management
- **Email Alerts**: Configured to send alerts via Gmail SMTP

## 📋 Prerequisites

- Docker and Docker Compose installed
- Docker version 20.10+ (for `host-gateway` support on Linux)
- Services running on the server with exposed ports
- Services must bind to `0.0.0.0` (not `127.0.0.1`) to be accessible from containers
- Network access to services from Docker containers

## 🚀 Quick Start

### Option 1: Using Docker Compose (Manual)

```bash
cd monitoring_service
docker compose up -d
```

### Option 2: Using Jenkins Pipeline

The monitoring service includes a Jenkinsfile for automated deployment:

1. Push code to your Git repository
2. Jenkins will automatically:
   - Load configuration from `JF.conf`
   - Clean up existing containers
   - Validate docker-compose configuration
   - Start Prometheus and Alertmanager
   - Verify services are healthy

### 2. Verify Services are Running

```bash
# Using docker compose (v2)
docker compose ps

# Or using docker-compose (v1)
docker-compose ps
```

You should see:
- `prometheus` running on port `9090`
- `alertmanager` running on port `9093`

### 3. Access Web UIs

- **Prometheus**: http://localhost:9090
- **Alertmanager**: http://localhost:9093

## 📊 Monitored Services

The following services are monitored:

| Service | Port | Job Name | Notes |
|---------|------|----------|-------|
| Loans | 40256 | back-loans | Spring Boot |
| Transactions | 40254 | back-transactions | Spring Boot |
| Visit | 30252 | back-visit | Spring Boot |
| SSO | 4005 | back-sso | Spring Boot (b_sso) |
| Erada Customers | 4001 | back-eradacustomers | Spring Boot (b_custom_portal) |
| Islamic Finance Platform | 1652 | b-islamic-finance-platform | Spring Boot |
| Insurance | 1801 | back-insurance | Spring Boot |
| Penalties | 1802 | back-penalties | Spring Boot |
| Modify LO | 1803 | back-modify-lo | Spring Boot |
| Money Transfer | 3000 | b-money-trans | NestJS (b_money_trans) |

## 🔔 Alert Rules

The following alerts are configured:

1. **ServiceDown**: Service is down for more than 1 minute
2. **HighErrorRate**: Error rate exceeds 5% for 5 minutes
3. **HighResponseTime**: 95th percentile response time > 2s for 5 minutes
4. **ServiceUnavailable**: Backend service unavailable for 2 minutes
5. **HealthCheckFailed**: Health check endpoint not responding
6. **HighMemoryUsage**: Memory usage > 90% for 5 minutes
7. **HighCPUUsage**: CPU usage > 80% for 5 minutes

## 📧 Email Configuration

Alerts are sent to: **AMahmoud@Eradafinance.com**

Email settings:
- SMTP Server: smtp.gmail.com:587
- From: erada.alertmanager@gmail.com
- TLS: Required

## 🔧 Configuration Files

### prometheus.yml
- Prometheus scrape configuration
- Service discovery and metrics collection
- Alert rule file reference

### alertmanager.yml
- Alert routing rules
- Email notification configuration
- Alert grouping and timing

### alerts.yml
- Alert rule definitions
- Thresholds and conditions
- Alert severity levels

## 🛠️ Customization

### Adding a New Service

1. Edit `prometheus.yml` and add a new scrape config:

**For Spring Boot services:**
```yaml
- job_name: 'new-service'
  metrics_path: '/actuator/prometheus'
  static_configs:
    - targets: ['host.docker.internal:PORT']
      labels:
        service: 'new-service'
        type: 'backend'
```

**For NestJS services:**
```yaml
- job_name: 'new-service'
  metrics_path: '/metrics'
  static_configs:
    - targets: ['host.docker.internal:PORT']
      labels:
        service: 'new-service'
        type: 'backend'
        framework: 'nestjs'
```

2. Add the service to health checks section:
```yaml
- targets:
    - 'host.docker.internal:PORT'
```

3. Reload Prometheus configuration:

```bash
curl -X POST http://localhost:9090/-/reload
```

### Modifying Alert Rules

1. Edit `alerts.yml`
2. Reload Prometheus:

```bash
curl -X POST http://localhost:9090/-/reload
```

### Changing Email Recipients

1. Edit `alertmanager.yml` and update the `to` field:

```yaml
email_configs:
  - to: 'new-email@Eradafinance.com'
```

2. Reload Alertmanager:

```bash
curl -X POST http://localhost:9093/-/reload
```

## 🔧 Network Diagnostics

Run the diagnostic script to check network connectivity:

**Linux/Mac:**
```bash
chmod +x diagnose.sh
./diagnose.sh
```

**Windows:**
```cmd
diagnose.cmd
```

This will test:
- Prometheus container status
- DNS resolution for `host.docker.internal`
- Network connectivity to host
- HTTP connectivity to all monitored services
- Prometheus targets status
- Docker version compatibility

## 🔍 Troubleshooting

### Services Not Being Scraped

1. **Test DNS resolution** (verify `host.docker.internal` works):
   ```bash
   docker exec prometheus nslookup host.docker.internal
   # Should resolve to host IP (e.g., 172.17.0.1 on Linux)
   ```

2. **Test network connectivity** from Prometheus container:
   ```bash
   # Test ping to host
   docker exec prometheus ping -c 2 host.docker.internal
   
   # Test HTTP connectivity to a service
   docker exec prometheus wget -O- http://host.docker.internal:4001/actuator/health
   # Or using curl
   docker exec prometheus curl -v http://host.docker.internal:4005/actuator/health
   ```

3. **Verify service binding** (services must bind to 0.0.0.0, not 127.0.0.1):
   ```bash
   # Linux/Mac
   netstat -tulpn | grep :4005
   # Should show: 0.0.0.0:4005, NOT 127.0.0.1:4005
   
   # Windows
   netstat -ano | findstr :4005
   ```

4. **Check Prometheus targets status**:
   ```bash
   # View all targets
   curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health, lastError: .lastError}'
   
   # Or visit in browser
   http://localhost:9090/targets
   ```

5. **Check Prometheus logs** for connection errors:
   ```bash
   docker logs prometheus | grep -i "connection\|timeout\|refused\|dial tcp"
   ```

6. **Linux-specific troubleshooting**:
   ```bash
   # If host.docker.internal doesn't work, check Docker version
   docker --version  # Should be 20.10+
   
   # Alternative: Use Docker bridge IP directly
   # Find bridge IP: ip addr show docker0 | grep inet
   # Then update prometheus.yml to use 172.17.0.1 instead of host.docker.internal
   ```

### Alerts Not Sending

1. Check Alertmanager logs:
   ```bash
   docker logs alertmanager
   ```

2. Verify email credentials in `alertmanager.yml`

3. Test email configuration:
   ```bash
   docker exec alertmanager amtool config test /etc/alertmanager/alertmanager.yml
   ```

### Prometheus Not Starting

1. Check Prometheus logs:
   ```bash
   docker logs prometheus
   ```

2. Validate configuration:
   ```bash
   docker exec prometheus promtool check config /etc/prometheus/prometheus.yml
   ```

## 📈 Useful Prometheus Queries

### Service Availability
```
up{job=~"back-.*"}
```

### Error Rate by Service
```
rate(http_server_requests_seconds_count{status=~"5.."}[5m])
```

### Response Time (95th percentile)
```
histogram_quantile(0.95, rate(http_server_requests_seconds_bucket[5m]))
```

### Memory Usage
```
jvm_memory_used_bytes / jvm_memory_max_bytes
```

## 🔄 Maintenance

### Restart Services
```bash
# Using docker compose (v2)
docker compose restart

# Or using docker-compose (v1)
docker-compose restart
```

### Stop Services
```bash
docker compose down
# Or: docker-compose down
```

### Stop and Remove Volumes (⚠️ Deletes Data)
```bash
docker compose down -v
# Or: docker-compose down -v
```

### View Logs
```bash
# All services
docker compose logs -f
# Or: docker-compose logs -f

# Specific service
docker compose logs -f prometheus
docker compose logs -f alertmanager
```

## 📝 Notes

### Network Configuration

- **host.docker.internal**: Configured via `extra_hosts` with `host-gateway` for cross-platform support
  - ✅ **Windows**: Built-in support, works out of the box
  - ✅ **macOS**: Built-in support, works out of the box  
  - ✅ **Linux**: Works with Docker 20.10+ using `host-gateway` (configured in docker-compose.yml)
  
- **Service Binding**: Services must bind to `0.0.0.0:PORT`, not `127.0.0.1:PORT` to be accessible from containers

- **Network Isolation**: Prometheus runs on isolated `monitoring` network but can access host services via `host.docker.internal`

### Metrics Endpoints

- **Spring Boot**: `/actuator/prometheus` (requires Spring Boot Actuator with Prometheus dependency)
- **NestJS**: `/metrics` (requires Prometheus metrics exporter)
- **Health Checks**: `/actuator/health` (Spring Boot) or `/health` (NestJS)

### Platform Compatibility

The configuration uses `extra_hosts` with `host-gateway` which provides:
- Cross-platform compatibility (Windows, Mac, Linux)
- No need to hardcode IP addresses
- Automatic host IP detection
- Works with Docker Compose v2

## 🔐 Security Considerations

- Email password is stored in plain text in `alertmanager.yml`
- Consider using Docker secrets or environment variables for production
- Restrict access to Prometheus/Alertmanager UIs in production
- Use reverse proxy with authentication for web interfaces

## 📚 Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Alertmanager Documentation](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [Spring Boot Actuator](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)
