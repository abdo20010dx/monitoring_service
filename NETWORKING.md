# Network Configuration Guide

## Overview

This document explains the network configuration for Prometheus monitoring in a Docker environment, specifically how Prometheus containers can access services running on the host machine.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Host Machine                          │
│                                                          │
│  ┌──────────────┐    ┌──────────────┐                  │
│  │   Service 1  │    │   Service 2  │  ... (ports)      │
│  │   :4001      │    │   :4005      │                  │
│  └──────────────┘    └──────────────┘                  │
│         ▲                    ▲                          │
│         │                    │                          │
│         └────────┬───────────┘                          │
│                  │                                      │
│         host.docker.internal                            │
│                  │                                      │
│  ┌──────────────────────────────────────┐               │
│  │     Docker Bridge Network            │               │
│  │                                       │               │
│  │  ┌──────────────┐  ┌──────────────┐ │               │
│  │  │  Prometheus   │  │ Alertmanager │ │               │
│  │  │  :9090        │  │  :9093      │ │               │
│  │  └──────────────┘  └──────────────┘ │               │
│  └──────────────────────────────────────┘               │
└─────────────────────────────────────────────────────────┘
```

## Solution: Cross-Platform Host Access

### Configuration

The `docker-compose.yml` uses `extra_hosts` with `host-gateway`:

```yaml
services:
  prometheus:
    extra_hosts:
      - "host.docker.internal:host-gateway"
```

### How It Works

1. **host.docker.internal**: A special DNS name that resolves to the host machine's IP
2. **host-gateway**: Docker Compose v2 feature that automatically detects the host IP
3. **Cross-platform**: Works on Windows, macOS, and Linux (Docker 20.10+)

### Platform Support

| Platform | Support | Notes |
|----------|---------|-------|
| Windows | ✅ Native | Built-in Docker Desktop support |
| macOS | ✅ Native | Built-in Docker Desktop support |
| Linux | ✅ Docker 20.10+ | Requires `host-gateway` feature |

## Service Requirements

### Port Binding

Services **MUST** bind to `0.0.0.0`, not `127.0.0.1`:

```properties
# ✅ Correct - Accessible from containers
server.port=4005
# Spring Boot binds to 0.0.0.0 by default

# ❌ Wrong - Only accessible from host
server.address=127.0.0.1
server.port=4005
```

### Verification

Check service binding:

```bash
# Linux/Mac
netstat -tulpn | grep :4005
# Should show: 0.0.0.0:4005

# Windows
netstat -ano | findstr :4005
```

## Network Troubleshooting

### 1. Test DNS Resolution

```bash
docker exec prometheus nslookup host.docker.internal
```

Expected output:
```
Name:   host.docker.internal
Address: 172.17.0.1  # or similar host IP
```

### 2. Test Connectivity

```bash
# Ping test
docker exec prometheus ping -c 2 host.docker.internal

# HTTP test
docker exec prometheus curl http://host.docker.internal:4005/actuator/health
```

### 3. Check Prometheus Targets

Visit: http://localhost:9090/targets

All targets should show as "UP" (green).

### 4. Run Diagnostics

```bash
# Linux/Mac
./diagnose.sh

# Windows
diagnose.cmd
```

## Common Issues

### Issue: "Connection refused" or "No route to host"

**Causes:**
1. Service not running
2. Service bound to `127.0.0.1` instead of `0.0.0.0`
3. Firewall blocking container-to-host communication
4. Docker version too old (Linux)

**Solutions:**
1. Verify service is running: `docker ps` or `netstat -tulpn`
2. Check service binding configuration
3. Check firewall rules (usually not needed on Windows/Mac)
4. Upgrade Docker to 20.10+ on Linux

### Issue: "host.docker.internal: Name or service not known"

**Causes:**
1. Docker version too old (Linux)
2. Docker Compose version issue

**Solutions:**
1. Upgrade Docker to 20.10+
2. Use Docker Compose v2: `docker compose` (not `docker-compose`)
3. Alternative: Use Docker bridge IP directly (`172.17.0.1`)

### Issue: Services accessible from host but not from Prometheus

**Causes:**
1. Service bound to `127.0.0.1`
2. Network isolation

**Solutions:**
1. Change service to bind to `0.0.0.0`
2. Verify `extra_hosts` configuration in docker-compose.yml

## Alternative Configurations

### Option 1: Host Network Mode (Linux Only)

```yaml
services:
  prometheus:
    network_mode: "host"
    # Remove networks section
```

**Pros:** Simple, no DNS issues  
**Cons:** Less isolation, Linux only

### Option 2: Docker Bridge IP (Not Recommended)

```yaml
# In prometheus.yml, use:
targets: ['172.17.0.1:4005']
```

**Pros:** Works on all platforms  
**Cons:** Hardcoded IP, may change

### Option 3: Shared Docker Network (Best for Containerized Services)

If all services run in Docker containers:

```yaml
services:
  prometheus:
    networks:
      - monitoring
      - erada-services  # Shared network

networks:
  erada-services:
    external: true
    name: erada-network
```

Then use container names in `prometheus.yml`:
```yaml
targets: ['back-sso-container:4005']
```

## Best Practices

1. ✅ Use `extra_hosts` with `host-gateway` for cross-platform support
2. ✅ Always bind services to `0.0.0.0`, not `127.0.0.1`
3. ✅ Run diagnostics script after deployment
4. ✅ Monitor Prometheus targets page regularly
5. ✅ Use Docker Compose v2 (`docker compose`)
6. ✅ Keep Docker updated (20.10+ for Linux)

## References

- [Docker Compose Networking](https://docs.docker.com/compose/networking/)
- [Docker Host Gateway](https://docs.docker.com/desktop/networking/#i-want-to-connect-from-a-container-to-a-service-on-the-host)
- [Prometheus Configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)

