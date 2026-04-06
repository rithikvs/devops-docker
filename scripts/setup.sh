#!/bin/bash

# Docker Networking Setup Script for Linux/Mac
# This script automates the entire Docker networking demonstration

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "\n${BLUE}════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if Docker is installed
check_docker() {
    print_header "Checking Docker Installation"
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    print_success "Docker is installed"
    docker --version
}

# Check if Docker daemon is running
check_docker_daemon() {
    print_header "Checking Docker Daemon"
    if ! docker ps &> /dev/null; then
        print_error "Docker daemon is not running. Please start Docker."
        exit 1
    fi
    print_success "Docker daemon is running"
}

# Cleanup previous setup
cleanup() {
    print_header "Cleaning Up Previous Setup"
    
    print_info "Stopping and removing containers..."
    docker stop nginx-net1 nginx-net2 2>/dev/null || true
    docker rm nginx-net1 nginx-net2 2>/dev/null || true
    
    print_info "Removing networks..."
    docker network rm network1 network2 2>/dev/null || true
    
    print_success "Cleanup complete"
}

# Create networks
create_networks() {
    print_header "Creating Custom Bridge Networks"
    
    docker network create network1
    print_success "Created network1"
    
    docker network create network2
    print_success "Created network2"
    
    echo -e "\n${BLUE}Networks created:${NC}"
    docker network ls | grep -E "network1|network2"
}

# Run containers
run_containers() {
    print_header "Running NGINX Containers"
    
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
    
    print_info "Starting nginx-net1 in network1..."
    docker run -d \
        --name nginx-net1 \
        --network network1 \
        -p 8081:80 \
        -v "$PROJECT_DIR/nginx-net1-index.html:/usr/share/nginx/html/index.html" \
        nginx:latest > /dev/null
    print_success "Started nginx-net1 (port 8081)"
    
    print_info "Starting nginx-net2 in network2..."
    docker run -d \
        --name nginx-net2 \
        --network network2 \
        -p 8082:80 \
        -v "$PROJECT_DIR/nginx-net2-index.html:/usr/share/nginx/html/index.html" \
        nginx:latest > /dev/null
    print_success "Started nginx-net2 (port 8082)"
    
    # Wait for containers to be ready
    print_info "Waiting for containers to be ready..."
    sleep 3
    
    echo -e "\n${BLUE}Running containers:${NC}"
    docker ps --filter "name=nginx-net"
}

# Test isolation
test_isolation() {
    print_header "Testing Network Isolation (Should FAIL)"
    
    CONTAINER_NET1=$(docker ps -q -f name=nginx-net1)
    
    print_warning "Attempting to ping nginx-net2 from nginx-net1 (should fail)..."
    if docker exec "$CONTAINER_NET1" ping -c 2 nginx-net2 2>/dev/null; then
        print_error "Containers can communicate! Networks are not isolated."
        return 1
    else
        print_success "Networks are properly isolated - ping failed as expected"
    fi
    
    print_warning "Attempting curl from nginx-net1 to nginx-net2 (should fail)..."
    if docker exec "$CONTAINER_NET1" timeout 2 curl -s http://nginx-net2 > /dev/null 2>&1; then
        print_error "Containers can communicate! Networks are not isolated."
        return 1
    else
        print_success "Networks are properly isolated - curl failed as expected"
    fi
}

# Connect networks
connect_networks() {
    print_header "Connecting nginx-net1 to network2"
    
    docker network connect network2 nginx-net1
    print_success "Connected nginx-net1 to network2"
    
    # Wait for DNS to update
    sleep 2
    
    echo -e "\n${BLUE}Network assignments:${NC}"
    docker inspect nginx-net1 | grep -A 15 '"Networks"'
}

# Test communication
test_communication() {
    print_header "Testing Communication After Network Connection (Should SUCCEED)"
    
    CONTAINER_NET1=$(docker ps -q -f name=nginx-net1)
    
    print_info "Attempting to ping nginx-net2 from nginx-net1 (should succeed)..."
    if docker exec "$CONTAINER_NET1" ping -c 2 nginx-net2; then
        print_success "Ping successful - containers can now communicate!"
    else
        print_error "Ping failed - check network connectivity"
        return 1
    fi
    
    print_info "Attempting curl from nginx-net1 to nginx-net2 (should succeed)..."
    if docker exec "$CONTAINER_NET1" curl -s http://nginx-net2 > /dev/null; then
        print_success "Curl successful - containers can communicate via HTTP!"
    else
        print_error "Curl failed - check container health"
        return 1
    fi
}

# Show summary
show_summary() {
    print_header "Setup Complete - Summary"
    
    echo -e "${GREEN}Networks:${NC}"
    docker network ls | grep -E "network1|network2" | awk '{printf "  • %s (%s)\n", $2, $3}'
    
    echo -e "\n${GREEN}Containers:${NC}"
    docker ps --filter "name=nginx-net" | tail -n +2 | awk '{printf "  • %s (port %s)\n", $NF, $9}'
    
    echo -e "\n${GREEN}Web Access:${NC}"
    echo -e "  • nginx-net1: ${BLUE}http://localhost:8081${NC}"
    echo -e "  • nginx-net2: ${BLUE}http://localhost:8082${NC}"
    
    echo -e "\n${GREEN}Network Details:${NC}"
    echo -e "  • nginx-net1 networks: $(docker inspect nginx-net1 | grep -o '"network[12]"' | tr '\n' ', ' | sed 's/,$//')"
    echo -e "  • nginx-net2 networks: $(docker inspect nginx-net2 | grep -o '"network[12]"' | tr '\n' ', ' | sed 's/,$//')"
    
    echo -e "\n${YELLOW}Useful Commands:${NC}"
    echo "  View logs:       docker-compose logs -f"
    echo "  Stop services:   docker-compose down"
    echo "  Exec into container: docker exec -it nginx-net1 sh"
    echo "  Inspect network: docker network inspect network1"
}

# Main execution
main() {
    print_header "Docker Networking Setup Script"
    print_info "This script will set up isolated Docker networks with nginx containers"
    
    check_docker
    check_docker_daemon
    
    read -p "Press Enter to continue or Ctrl+C to cancel..."
    
    cleanup
    create_networks
    run_containers
    test_isolation
    connect_networks
    test_communication
    show_summary
    
    print_header "All tests completed successfully!"
}

# Run main function
main "$@"
