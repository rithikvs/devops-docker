# Docker Networking Architecture & Commands Reference

## NETWORK TOPOLOGY DIAGRAM

### Initial State (Isolated Networks)
```
┌─────────────────────────────────────────────────────┐
│                    Docker Host                      │
│               (localhost / 127.0.0.1)               │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌────────────────────┐   ┌────────────────────┐  │
│  │    NETWORK 1       │   │    NETWORK 2       │  │
│  │ (bridge driver)    │   │ (bridge driver)    │  │
│  │                    │   │                    │  │
│  │  ┌──────────────┐  │   │  ┌──────────────┐  │  │
│  │  │  nginx-net1  │  │   │  │  nginx-net2  │  │  │
│  │  │   :80        │  │   │  │   :80        │  │  │
│  │  │ 172.17.0.2   │  │   │  │ 172.18.0.2   │  │  │
│  │  └──────┬───────┘  │   │  └──────┬───────┘  │  │
│  │         │          │   │         │          │  │
│  │    :8081┌──────────────────────┘:8082       │  │
│  │  localhost   │           │   localhost       │  │
│  └────────────────────┘   └────────────────────┘  │
│        ✗ ISOLATED ✗            └─ NO ROUTE      │
└─────────────────────────────────────────────────────┘
```

### After Connection (Bridged)
```
┌─────────────────────────────────────────────────────┐
│                    Docker Host                      │
│               (localhost / 127.0.0.1)               │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌────────────────────┐   ┌────────────────────┐  │
│  │    NETWORK 1       │   │    NETWORK 2       │  │
│  │                    │   │                    │  │
│  │  ┌──────────────┐  │   │  ┌──────────────┐  │  │
│  │  │  nginx-net1  │  │   │  │  nginx-net2  │  │  │
│  │  │ 172.17.0.2   │  │   │  │ 172.18.0.2   │  │  │
│  │  │ 172.18.0.3   │◄─┼───┤◄─│              │  │  │
│  │  │ (connected)  │  │   │  │              │  │  │
│  │  └──────────────┘  │   │  └──────────────┘  │  │
│  │        :8081       │   │        :8082       │  │
│  └────────────────────┘   └────────────────────┘  │
│      ✓ CONNECTED ✓                                 │
└─────────────────────────────────────────────────────┘
```

---

## DETAILED COMMAND REFERENCE

### 1️⃣ CREATE NETWORKS

**Create network1:**
```bash
docker network create network1
```

**Create network2:**
```bash
docker network create network2
```

**Verify networks:**
```bash
docker network ls
```

**Inspect specific network:**
```bash
docker network inspect network1
docker network inspect network2
```

**Output shows:**
- Network driver (bridge)
- Subnet/Gateway
- Connected containers

---

### 2️⃣ RUN CONTAINERS IN ISOLATED NETWORKS

**Run nginx-net1 in network1:**
```bash
docker run -d \
  --name nginx-net1 \
  --network network1 \
  -p 8081:80 \
  -v ./nginx-net1-index.html:/usr/share/nginx/html/index.html \
  nginx:latest
```

**Run nginx-net2 in network2:**
```bash
docker run -d \
  --name nginx-net2 \
  --network network2 \
  -p 8082:80 \
  -v ./nginx-net2-index.html:/usr/share/nginx/html/index.html \
  nginx:latest
```

**Verify containers:**
```bash
docker ps
```

---

### 3️⃣ TEST ISOLATION (Phase 1 - Should FAIL)

**Ping test (nginx-net1 → nginx-net2):**
```bash
docker exec nginx-net1 ping -c 3 nginx-net2
```

**Expected failure:**
```
ping: unknown host
Name or service not known
```

**Curl test (nginx-net1 → nginx-net2):**
```bash
docker exec nginx-net1 curl http://nginx-net2
```

**Expected failure:**
```
curl: (7) Failed to connect to nginx-net2 port 80
Connection refused / Timeout
```

**Why it fails:**
- Both containers are on different networks
- Docker DNS doesn't resolve across network boundaries
- No route exists between network1 and network2

---

### 4️⃣ CONNECT CONTAINERS ACROSS NETWORKS

**Connect nginx-net1 to network2:**
```bash
docker network connect network2 nginx-net1
```

**Verify connection:**
```bash
docker inspect network2 | grep -A 15 "Containers"
```

**Output will show:**
```json
"Containers": {
  "< container_id >": {
    "Name": "nginx-net1",
    "IPv4Address": "172.18.0.3/16"
  },
  "< container_id >": {
    "Name": "nginx-net2",
    "IPv4Address": "172.18.0.2/16"
  }
}
```

---

### 5️⃣ TEST COMMUNICATION (Phase 2 - Should SUCCEED)

**Ping test (nginx-net1 → nginx-net2):**
```bash
docker exec nginx-net1 ping -c 3 nginx-net2
```

**Expected success:**
```
PING nginx-net2 (172.18.0.2): 56 data bytes
64 bytes from 172.18.0.3: icmp_seq=0 ttl=64 time=0.123 ms
64 bytes from 172.18.0.3: icmp_seq=1 ttl=64 time=0.098 ms
```

**Curl test (nginx-net1 → nginx-net2):**
```bash
docker exec nginx-net1 curl http://nginx-net2
```

**Expected success (HTML response):**
```html
<!DOCTYPE html>
<html>
<head>
    <title>nginx-net2</title>
    ...
```

**Why it works now:**
- nginx-net1 is connected to BOTH networks
- Docker Embedded DNS resolves nginx-net2
- Network route exists (172.18.0.0/16)

---

## DOCKER-COMPOSE REFERENCE

**File: docker-compose.yml**

### Service: nginx-network1
```yaml
services:
  nginx-network1:
    image: nginx:latest
    container_name: nginx-net1
    networks:
      - network1                    # Connected to network1 only
    ports:
      - "8081:80"                   # Maps container:80 → localhost:8081
    volumes:
      - ./nginx-net1-index.html:/usr/share/nginx/html/index.html
```

### Service: nginx-network2
```yaml
  nginx-network2:
    image: nginx:latest
    container_name: nginx-net2
    networks:
      - network2                    # Connected to network2 only
    ports:
      - "8082:80"                   # Maps container:80 → localhost:8082
    volumes:
      - ./nginx-net2-index.html:/usr/share/nginx/html/index.html
```

### Networks Definition
```yaml
networks:
  network1:
    driver: bridge                  # Bridge driver (default for custom networks)
    name: network1
  network2:
    driver: bridge                  # Bridge driver (default for custom networks)
    name: network2
```

---

## DOCKER-COMPOSE QUICK COMMANDS

**Start all services:**
```bash
docker-compose up -d
```

**View running services:**
```bash
docker-compose ps
```

**View logs:**
```bash
docker-compose logs -f
```

**View logs for specific service:**
```bash
docker-compose logs -f nginx-network1
```

**Execute command in service:**
```bash
docker-compose exec nginx-network1 ping nginx-network2
```

**Stop services:**
```bash
docker-compose stop
```

**Stop and remove:**
```bash
docker-compose down
```

**Restart services:**
```bash
docker-compose restart
```

---

## INTERACTIVE TESTING IN CONTAINER SHELL

**Enter container shell:**
```bash
docker exec -it nginx-net1 sh
```

**Inside the container:**

Check DNS resolution:
```bash
nslookup nginx-net2
# Returns IP only after network connection
```

Test connectivity:
```bash
ping nginx-net2 -c 3
curl http://nginx-net2
```

Check network interfaces:
```bash
ip addr show
# Shows all network connections
```

View routing table:
```bash
ip route show
# Shows available routes
```

Exit shell:
```bash
exit
```

---

## INSPECTION & DEBUGGING COMMANDS

**View attached networks for container:**
```bash
docker inspect nginx-net1 | jq '.NetworkSettings.Networks'

# Output:
# {
#   "network1": {
#     "Gateway": "172.17.0.1",
#     "IPAddress": "172.17.0.2",
#     "IPPrefixLen": 16
#   },
#   "network2": {               # After docker network connect
#     "Gateway": "172.18.0.1",
#     "IPAddress": "172.18.0.3",
#     "IPPrefixLen": 16
#   }
# }
```

**View all containers on network:**
```bash
docker network inspect network1 | jq '.Containers'
```

**Get container IP address:**
```bash
docker inspect -f '{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' nginx-net1
```

**View network settings:**
```bash
docker inspect -f '{{json .NetworkSettings}}' nginx-net1 | jq .
```

**Check port mappings:**
```bash
docker inspect -f '{{.Name}} - {{json .NetworkSettings.Ports}}' nginx-net1 | jq .
```

---

## TROUBLESHOOTING CHECKLIST

| Issue | Command | Fix |
|-------|---------|-----|
| Containers won't ping | `docker exec container1 ping container2` | Check if connected to same network |
| DNS not resolving | `docker exec container1 nslookup container2` | Restart Docker daemon |
| Port already in use | `docker ps -a` | Change port mapping or stop conflicting container |
| Container won't start | `docker logs container-name` | Check error logs |
| Networks not visible | `docker network ls` | Docker daemon not running |

---

## KEY CONCEPTS SUMMARY

| Concept | Description |
|---------|-------------|
| **Bridge Network** | Default Docker driver, creates isolated L2 networks with DNS |
| **Docker Embedded DNS** | Resolves container names to IPs within the same network (127.0.0.11:53) |
| **Container Isolation** | By default, containers on different networks cannot communicate |
| **Network Connection** | `docker network connect` allows a container to join additional networks |
| **Multi-Network Containers** | Containers can connect to multiple networks simultaneously |
| **Port Mapping** | Maps container ports to host ports (only for accessibility from host) |
| **Service Discovery** | Container name resolution enabled via embedded DNS server |

---

## ADVANCED SCENARIOS

### Scenario 1: Three Networks, Partial Connectivity

```bash
# Create 3 networks
docker network create net-a
docker network create net-b
docker network create net-c

# Container can access net-a and net-b only
docker network connect net-a container1
docker network connect net-b container1

# Container2 on net-c cannot reach container1
```

### Scenario 2: Container in Host Network

```bash
docker run -d \
  --name host-container \
  --network host \
  nginx:latest

# Direct access to host network stack
# Uses host IP and ports directly
```

### Scenario 3: No Network Access (none driver)

```bash
docker run -d \
  --name isolated-container \
  --network none \
  nginx:latest

# Only loopback interface, no external network
```

---

## REFERENCES

- Docker Network Documentation: https://docs.docker.com/network/
- Bridge Networks: https://docs.docker.com/network/bridge/
- Container Networking: https://docs.docker.com/config/containers/container-networking/
- Docker-Compose Networking: https://docs.docker.com/compose/networking/
