#!/bin/bash

# Monitoring Service Network Diagnostics Script
# This script helps diagnose network connectivity issues between Prometheus and monitored services

echo "🔍 Prometheus Network Diagnostics"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Prometheus container is running
echo "1. Checking Prometheus container status..."
if docker ps | grep -q prometheus; then
    echo -e "${GREEN}✅ Prometheus container is running${NC}"
else
    echo -e "${RED}❌ Prometheus container is not running${NC}"
    echo "   Start it with: docker compose up -d"
    exit 1
fi

echo ""

# Check DNS resolution
echo "2. Testing DNS resolution for host.docker.internal..."
if docker exec prometheus nslookup host.docker.internal > /dev/null 2>&1; then
    HOST_IP=$(docker exec prometheus nslookup host.docker.internal 2>/dev/null | grep -A1 "Name:" | tail -1 | awk '{print $2}')
    echo -e "${GREEN}✅ host.docker.internal resolves to: ${HOST_IP}${NC}"
else
    echo -e "${RED}❌ Cannot resolve host.docker.internal${NC}"
    echo "   This may indicate a Docker version issue (need 20.10+)"
fi

echo ""

# Test ping to host
echo "3. Testing ping to host..."
if docker exec prometheus ping -c 2 host.docker.internal > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Can ping host.docker.internal${NC}"
else
    echo -e "${YELLOW}⚠️  Cannot ping host.docker.internal (may be blocked by firewall)${NC}"
fi

echo ""

# Test connectivity to services
echo "4. Testing connectivity to monitored services..."
SERVICES=(
    "4001:back-eradacustomers:/actuator/health"
    "4005:back-sso:/actuator/health"
    "40256:back-loans:/actuator/health"
    "40254:back-transactions:/actuator/health"
    "30252:back-visit:/actuator/health"
    "1652:b-islamic-finance:/actuator/health"
    "1801:back-insurance:/actuator/health"
    "1802:back-penalties:/actuator/health"
    "1803:back-modify-lo:/actuator/health"
    "3000:b-money-trans:/health"
)

for service in "${SERVICES[@]}"; do
    IFS=':' read -r port name endpoint <<< "$service"
    echo -n "   Testing $name (port $port)... "
    
    if docker exec prometheus wget -q -O- --timeout=3 "http://host.docker.internal:$port$endpoint" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ OK${NC}"
    else
        echo -e "${RED}❌ FAILED${NC}"
        echo "      Check if service is running and bound to 0.0.0.0:$port"
    fi
done

echo ""

# Check Prometheus targets
echo "5. Checking Prometheus targets status..."
TARGETS_STATUS=$(curl -s http://localhost:9090/api/v1/targets 2>/dev/null)
if [ $? -eq 0 ]; then
    UP_COUNT=$(echo "$TARGETS_STATUS" | grep -o '"health":"up"' | wc -l)
    DOWN_COUNT=$(echo "$TARGETS_STATUS" | grep -o '"health":"down"' | wc -l)
    echo -e "${GREEN}✅ Prometheus API accessible${NC}"
    echo "   Targets UP: $UP_COUNT"
    echo "   Targets DOWN: $DOWN_COUNT"
    echo ""
    echo "   View detailed status at: http://localhost:9090/targets"
else
    echo -e "${RED}❌ Cannot access Prometheus API${NC}"
fi

echo ""

# Check Docker version
echo "6. Checking Docker version..."
DOCKER_VERSION=$(docker --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
MAJOR=$(echo $DOCKER_VERSION | cut -d. -f1)
MINOR=$(echo $DOCKER_VERSION | cut -d. -f2)

if [ "$MAJOR" -gt 20 ] || ([ "$MAJOR" -eq 20 ] && [ "$MINOR" -ge 10 ]); then
    echo -e "${GREEN}✅ Docker version $DOCKER_VERSION supports host-gateway${NC}"
else
    echo -e "${YELLOW}⚠️  Docker version $DOCKER_VERSION may not support host-gateway${NC}"
    echo "   Consider upgrading to Docker 20.10+ for Linux compatibility"
fi

echo ""
echo "=================================="
echo "✅ Diagnostics complete!"
echo ""
echo "💡 Tips:"
echo "   - If services are unreachable, verify they bind to 0.0.0.0, not 127.0.0.1"
echo "   - Check firewall rules if ping fails but services are running"
echo "   - View Prometheus targets: http://localhost:9090/targets"
echo "   - Check Prometheus logs: docker logs prometheus"

