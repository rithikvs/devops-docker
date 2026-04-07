.PHONY: help up down ps logs status test clean restart health inspect connect

# Default target
help:
	@echo "🐳 Docker Networking Project - Makefile Commands"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  up              - Start all services (docker-compose up -d)"
	@echo "  down            - Stop all services (docker-compose down)"
	@echo "  ps              - Show container status"
	@echo "  logs            - View service logs"
	@echo "  status          - Show detailed status"
	@echo "  health          - Check container health"
	@echo "  test            - Run all tests"
	@echo "  test-isolation  - Test network isolation (should fail)"
	@echo "  test-connect    - Test after network connection"
	@echo "  clean           - Complete cleanup"
	@echo "  restart         - Restart services"
	@echo "  inspect         - Inspect network details"
	@echo "  connect         - Connect nginx-net1 to network2"
	@echo "  disconnect      - Disconnect nginx-net1 from network2"
	@echo "  web1            - Open http://localhost:8081"
	@echo "  web2            - Open http://localhost:8082"
	@echo "  help            - Show this help message"

# Start services
up:
	@echo "Starting Docker services..."
	docker-compose up -d
	@make ps

# Stop services
down:
	@echo "Stopping Docker services..."
	docker-compose down

# Show container status
ps:
	@echo "Container Status:"
	docker-compose ps

# View logs
logs:
	@echo "Viewing service logs..."
	docker-compose logs -f

# Detailed status
status:
	@echo "=== Container Status ==="
	docker-compose ps
	@echo ""
	@echo "=== Network Status ==="
	docker network ls | findstr network
	@echo ""
	@echo "=== Container Details ==="
	docker inspect nginx-net1 --format='Container: {{.Name}} | Status: {{.State.Status}}'
	docker inspect nginx-net2 --format='Container: {{.Name}} | Status: {{.State.Status}}'

# Health check
health:
	@echo "Checking container health..."
	@docker inspect nginx-net1 --format='nginx-net1: {{.State.Health.Status}}'
	@docker inspect nginx-net2 --format='nginx-net2: {{.State.Health.Status}}'

# Restart
restart:
	@echo "Restarting services..."
	docker-compose restart
	@make ps

# Clean everything
clean:
	@echo "Cleaning up all Docker assets..."
	docker-compose down
	docker system prune -f
	@echo "Cleanup complete!"

# Run tests
test: test-isolation test-connect

test-isolation:
	@echo "❌ Testing isolation (should FAIL)..."
	docker exec nginx-net1 curl http://nginx-net2 || echo "✓ Isolation confirmed - networks cannot communicate"

test-connect:
	@echo "🔗 Connecting networks..."
	docker network connect network2 nginx-net1 || true
	@echo "✓ Testing communication (should SUCCEED)..."
	docker exec nginx-net1 curl -s http://nginx-net2 | head -3 || echo "Communication test"

# Inspect networks
inspect:
	@echo "=== Network 1 Details ==="
	docker network inspect network1 --format='Name: {{.Name}} | Driver: {{.Driver}} | Containers: {{len .Containers}}'
	@echo ""
	@echo "=== Network 2 Details ==="
	docker network inspect network2 --format='Name: {{.Name}} | Driver: {{.Driver}} | Containers: {{len .Containers}}'

# Connect networks
connect:
	@echo "Connecting nginx-net1 to network2..."
	docker network connect network2 nginx-net1
	@echo "✓ Connection established"

# Disconnect networks
disconnect:
	@echo "Disconnecting nginx-net1 from network2..."
	docker network disconnect network2 nginx-net1
	@echo "✓ Disconnection complete"

# Open web browsers (Windows)
web1:
	start http://localhost:8081

web2:
	start http://localhost:8082

# Version (for CI/CD)
version:
	@echo "Project Version: 1.2.0"
	@docker --version
	@docker-compose --version
