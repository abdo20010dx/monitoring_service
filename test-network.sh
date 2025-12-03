#!/bin/bash

# Quick Network Test Script
# Tests if host.docker.internal works from Prometheus container

echo "🔍 Testing host.docker.internal connectivity..."
echo ""

# Check if Prometheus container is running
if ! docker ps | grep -q prometheus; then
    echo "❌ Prometheus container is not running!"
    echo "   Start it with: docker compose up -d"
    exit 1
fi

echo "1. Testing DNS resolution..."
docker exec prometheus nslookup host.docker.internal 2>/dev/null
if [ $? -eq 0 ]; then
    echo "   ✅ DNS resolution works!"
else
    echo "   ❌ DNS resolution failed!"
    exit 1
fi

echo ""
echo "2. Testing ping to host..."
docker exec prometheus ping -c 2 host.docker.internal > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "   ✅ Ping successful!"
else
    echo "   ⚠️  Ping failed (may be blocked by firewall, but HTTP might still work)"
fi

echo ""
echo "3. Testing HTTP connectivity to a service..."
echo "   Testing: http://host.docker.internal:4005/actuator/health"
docker exec prometheus wget -q -O- --timeout=5 http://host.docker.internal:4005/actuator/health 2>/dev/null
if [ $? -eq 0 ]; then
    echo "   ✅ HTTP connectivity works! host.docker.internal is working correctly."
else
    echo "   ❌ HTTP connectivity failed!"
    echo ""
    echo "   Troubleshooting:"
    echo "   - Check if service is running on port 4005"
    echo "   - Verify service binds to 0.0.0.0, not 127.0.0.1"
    echo "   - Check Docker version: docker --version (need 20.10+)"
    exit 1
fi

echo ""
echo "✅ All tests passed! host.docker.internal is working correctly."

