# Docker Networking with Isolated Containers

This project demonstrates Docker networking concepts with two isolated NGINX containers running in separate custom bridge networks.

## Project Structure

```
docker-networking/
├── docker-compose.yml          # Docker Compose configuration
├── nginx-net1-index.html       # HTML for network1 container
├── nginx-net2-index.html       # HTML for network2 container
├── .dockerignore               # Docker build exclusions
├── scripts/
│   ├── setup.sh                # Automated setup script (Linux/Mac)
│   └── setup.ps1               # Automated setup script (Windows PowerShell)
└── README.md                   # This file
```

## Quick Start

### Option 1: Using Docker Compose (Recommended)

```bash
cd docker-networking

# Start both containers
docker-compose up -d

# Check running containers
docker-compose ps

# View logs
docker-compose logs -f

# Stop everything
docker-compose down
```

### Option 2: Manual Commands

See **Manual Setup Commands** section below.

## Manual Setup Commands

### Step 1: Create Custom Networks

```bash
# Create network1
docker network create network1

# Create network2
docker network create network2

# Verify networks created
docker network ls
```

### Step 2: Run Containers in Isolated Networks

```bash
# Run nginx in network1
docker run -d \
  --name nginx-net1 \
  --network network1 \
  -p 8081:80 \
  -v ./nginx-net1-index.html:/usr/share/nginx/html/index.html \
  nginx:latest

# Run nginx in network2
docker run -d \
  --name nginx-net2 \
  --network network2 \
  -p 8082:80 \
  -v ./nginx-net2-index.html:/usr/share/nginx/html/index.html \
  nginx:latest

# Verify containers running
docker ps
```

### Step 3: Test Isolation (Should Fail)

```bash
# Get container IDs
CONTAINER_NET1=$(docker ps -q -f name=nginx-net1)
CONTAINER_NET2=$(docker ps -q -f name=nginx-net2)

# Try to ping from net1 to net2 (WILL FAIL - Isolated)
docker exec $CONTAINER_NET1 ping -c 3 nginx-net2
# Expected: "Name or service not known" or "Command not found"

# Try to curl from net1 to net2 (WILL FAIL - Isolated)
docker exec $CONTAINER_NET1 curl http://nginx-net2
# Expected: timeout or connection refused
```

### Step 4: Connect Containers (Bridge Networks)

```bash
# Connect nginx-net1 to network2
docker network connect network2 nginx-net1

# Verify connection
docker inspect network2 | grep -A 20 "Containers"
```

### Step 5: Test Communication (Should Succeed)

```bash
# Get container ID again
CONTAINER_NET1=$(docker ps -q -f name=nginx-net1)

# Ping from net1 to net2 (NOW WORKS)
docker exec $CONTAINER_NET1 ping -c 3 nginx-net2
# Expected: responses with round trip times

# Curl from net1 to net2 (NOW WORKS)
docker exec $CONTAINER_NET1 curl http://nginx-net2

# Check container network details
docker inspect nginx-net1 | grep -A 5 "Networks"
```

## Test Commands Reference

### View Network Details

```bash
# List all networks
docker network ls

# Inspect specific network
docker network inspect network1
docker network inspect network2

# See which containers are on a network
docker network inspect network1 | jq '.Containers'
```

### Test Container Connectivity

```bash
# Shell into a container
docker exec -it nginx-net1 sh

# Inside container - test DNS resolution
nslookup nginx-net2  # Should work after connection

# Inside container - ping test
ping nginx-net2      # Should work after connection

# Inside container - curl test
curl http://nginx-net2  # Should return HTML
```

### View Logs

```bash
# All logs
docker-compose logs -f

# Specific service
docker-compose logs -f nginx-network1
docker-compose logs -f nginx-network2
```

## Web Access

Once running:
- **nginx-net1:** http://localhost:8081
- **nginx-net2:** http://localhost:8082

## Cleanup

```bash
# Stop and remove containers
docker-compose down

# Remove networks manually (if not using compose)
docker network rm network1 network2

# Remove ALL containers and networks (careful!)
docker system prune -a --volumes
```

## Network Diagram

```
┌─────────────────────────────────────────────┐
│           Docker Host (localhost)           │
├─────────────────────────────────────────────┤
│                                             │
│  ┌──────────────┐      ┌──────────────┐   │
│  │   network1   │      │   network2   │   │
│  │(bridge)      │      │(bridge)      │   │
│  │              │      │              │   │
│  │ ┌──────────┐ │      │ ┌──────────┐ │   │
│  │ │nginx-net1│ │      │ │nginx-net2│ │   │
│  │ │:80       │ │      │ │:80       │ │   │
│  │ └──────┬───┘ │      │ └──────┬───┘ │   │
│  │ :8081  │     │      │ :8082  │     │   │
│  └────────┼─────┘      └────────┼─────┘   │
│           │                     │         │
│           ☓ ISOLATED ☓ (default)│         │
│                                 │         │
│           ✓ CONNECTED ✓ (after  │         │
│             docker network      │         │
│             connect)            │         │
└─────────────────────────────────────────────┘
```

## Key Concepts Demonstrated

1. **Custom Bridge Networks:** Created with `docker network create`
2. **Container Isolation:** Containers in different networks cannot communicate by default
3. **DNS Resolution:** Docker embedded DNS for service discovery within networks
4. **Network Connectivity:** Connecting containers to multiple networks for inter-network communication
5. **Port Mapping:** Publishing container ports to host machine
6. **Volume Mounting:** Custom HTML for container identification

## Troubleshooting

### Containers can't ping each other
- Verify both are running: `docker ps`
- Check network assignments: `docker inspect nginx-net1 | grep -A 5 "Networks"`
- Ensure curl is installed in container

### Port conflicts
- Change `8081` or `8082` if already in use
- Update ports in `docker-compose.yml` or `docker run` commands

### DNS not resolving
- Ensure Docker daemon is running
- Check network is created: `docker network ls`
- Containers must share same network for DNS resolution

## References

- [Docker Networking Documentation](https://docs.docker.com/network/)
- [Bridge Networks](https://docs.docker.com/network/bridge/)
- [Docker Compose Networking](https://docs.docker.com/compose/networking/)
