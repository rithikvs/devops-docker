# Docker Networking Project - Interview Guide

## Fresh Start: Complete Commands & Explanations

---

## **SECTION 1: VERIFY DOCKER & PROJECT**

### Command 1: Check Docker is Installed and Running
```powershell
docker --version
```

**Explanation:**
- Verifies Docker is properly installed
- Shows the Docker version running

**Expected Output:**
```
Docker version 27.x.x, build xxxxxxx
```

✅ **What it means:** Docker is installed and ready to use

---

### Command 2: Navigate to Project Directory
```powershell
cd "d:\sem 6\projects\devops\docker-networking"
```

**Explanation:**
- Changes to the project folder
- docker-compose.yml file is located here

**Why:** Docker Compose needs to find the configuration file in the current directory

---

### Command 3: View Project Structure
```powershell
ls -la
```

**Explanation:**
- Lists all files in the project
- Shows project configuration and documentation

**Expected Output:**
```
docker-compose.yml          ← Main configuration file
nginx-net1-index.html       ← Custom page for container 1
nginx-net2-index.html       ← Custom page for container 2
README.md                   ← Documentation
QUICK-START.md              ← Quick reference
scripts/                    ← Setup scripts folder
```

✅ **What it means:** Project is properly structured and ready

---

## **SECTION 2: START THE PROJECT**

### Command 4: Start All Containers Using Docker Compose
```powershell
docker-compose up -d
```

**Explanation:**
- `-d` flag runs containers in background (detached mode)
- docker-compose reads `docker-compose.yml`
- Automatically creates networks and containers

**What happens:**
1. Pulls nginx:latest image (if not present)
2. Creates network1 (bridge network)
3. Creates network2 (bridge network)
4. Starts nginx-net1 container on network1
5. Starts nginx-net2 container on network2

**Expected Output:**
```
[+] Building 0.0s (0/0)
[+] Running 5/5
  ✔ Network network1 Created
  ✔ Network network2 Created
  ✔ Container nginx-net1 Started
  ✔ Container nginx-net2 Started
```

✅ **What it means:** All services are running and networks are isolated

---

### Command 5: Verify Containers Are Running
```powershell
docker-compose ps
```

**Explanation:**
- Shows status of all containers defined in docker-compose.yml
- Displays port mappings and health status

**Expected Output:**
```
NAME         IMAGE          STATUS              PORTS
nginx-net1   nginx:latest   Up (healthy)        0.0.0.0:8081->80/tcp
nginx-net2   nginx:latest   Up (healthy)        0.0.0.0:8082->80/tcp
```

✅ **What it means:**
- Both containers are healthy and running
- Port 8081 → nginx-net1 (network1)
- Port 8082 → nginx-net2 (network2)

---

### Command 6: View Created Networks
```powershell
docker network ls
```

**Explanation:**
- Lists all Docker networks on the system
- Shows network driver type (bridge in our case)

**Expected Output:**
```
NETWORK ID    NAME      DRIVER  SCOPE
xxx           network1  bridge  local
yyy           network2  bridge  local
```

✅ **What it means:** Two custom bridge networks have been successfully created

---

## **SECTION 3: DEMONSTRATE NETWORK ISOLATION**

### Command 7: Test If Containers Can See Each Other (BEFORE Connection)
```powershell
docker exec nginx-net1 curl http://nginx-net2
```

**Explanation:**
- `docker exec` - Execute command inside container
- `nginx-net1` - Container to execute command in
- `curl http://nginx-net2` - Try to access nginx-net2 by hostname

**What's happening:**
1. Container tries to resolve "nginx-net2" hostname using DNS
2. DNS lookup fails because containers are on different networks
3. No network route exists between network1 and network2

**Expected Output (First Time - FAILURE):**
```
curl: (6) Could not resolve host: nginx-net2
```

✅ **What it means:** 
- Networks ARE properly isolated
- DNS doesn't resolve across network boundaries
- Containers CANNOT communicate (isolation working!)

---

## **SECTION 4: BRIDGE THE NETWORKS**

### Command 8: Connect Container to Second Network
```powershell
docker network connect network2 nginx-net1
```

**Explanation:**
- Connects nginx-net1 container to network2
- Now container has interfaces on BOTH networks
- Enables cross-network communication

**What happens:**
1. Container gets a new IP on network2 (172.18.0.3)
2. Container retains old IP on network1 (172.17.0.2)
3. Docker's embedded DNS now resolves both network hostnames

**Expected Output:**
```
(no output = success)
```

✅ **What it means:** Container is now multi-homed (connected to 2 networks)

---

### Command 9: Verify Container Has Multiple Network Connections
```powershell
docker inspect nginx-net1 --format='{{json .NetworkSettings.Networks}}' | findstr -i ipaddress
```

**Explanation:**
- Inspects container configuration
- Shows all networks container is connected to
- Displays IP addresses on each network

**Expected Output:**
```
Shows IPs on both network1 AND network2
```

✅ **What it means:** Container successfully connected to both networks

---

## **SECTION 5: DEMONSTRATE NETWORK CONNECTIVITY**

### Command 10: Test If Containers Can Communicate (AFTER Connection)
```powershell
docker exec nginx-net1 curl http://nginx-net2
```

**Explanation:**
- Same command as before (Command 7)
- But now container CAN access network2
- DNS resolves nginx-net2 hostname to IP on network2

**What's happening:**
1. Container resolves "nginx-net2" to 172.18.0.2 (network2 IP)
2. Network route exists between networks (via container)
3. HTTP request sent and received successfully

**Expected Output (SUCCESS):**
```
<!DOCTYPE html>
<html>
<head>
    <title>nginx-net2</title>
    ...
    <h1>✓ NGINX Container - Network 2</h1>
    <p><strong>Container Name:</strong> nginx-net2</p>
    <p><strong>Network:</strong> network2</p>
    <p><strong>Port:</strong> 8082</p>
    <p><strong>Status:</strong> Running Successfully</p>
    ...
</html>
100   633  100   633    0     0   162k      0 --:--:--
```

✅ **What it means:**
- HTTP 200 OK - Request successful
- Full HTML page retrieved (633 bytes)
- Cross-network communication established!

---

## **SECTION 6: VERIFY WEB INTERFACE**

### Command 11: Test Container 1 from Host
```powershell
curl http://localhost:8081
```

**Explanation:**
- Access nginx-net1 from host machine
- Port 8081 mapped to port 80 inside container

**Expected Output:**
```html
<!DOCTYPE html>
...
<h1>✓ NGINX Container - Network 1</h1>
...
```

✅ **What it means:** nginx-net1 is accessible from host via port 8081

---

### Command 12: Test Container 2 from Host
```powershell
curl http://localhost:8082
```

**Explanation:**
- Access nginx-net2 from host machine
- Port 8082 mapped to port 80 inside container

**Expected Output:**
```html
<!DOCTYPE html>
...
<h1>✓ NGINX Container - Network 2</h1>
...
```

✅ **What it means:** nginx-net2 is accessible from host via port 8082

---

## **SECTION 7: INSPECT NETWORKS & CONTAINERS**

### Command 13: View All Containers on Network 1
```powershell
docker network inspect network1
```

**Explanation:**
- Shows detailed information about network1
- Lists all containers connected to this network
- Displays IP addresses and network configuration

**Key Information:**
```
"Containers": {
  "container_id": {
    "Name": "nginx-net1",
    "IPAddress": "172.17.0.2"
  }
}
```

✅ **What it means:** Only nginx-net1 is on network1

---

### Command 14: View All Containers on Network 2
```powershell
docker network inspect network2
```

**Explanation:**
- Shows detailed information about network2
- Lists all containers connected to this network
- Shows IP addresses

**Key Information:**
```
"Containers": {
  "id1": {
    "Name": "nginx-net1",
    "IPAddress": "172.18.0.3"
  },
  "id2": {
    "Name": "nginx-net2",
    "IPAddress": "172.18.0.2"
  }
}
```

✅ **What it means:** 
- nginx-net2 (always on network2)
- nginx-net1 (connected to network2 via docker network connect)

---

### Command 15: View Container Logs
```powershell
docker-compose logs -f
```

**Explanation:**
- Shows all logs from both containers
- `-f` flag follows logs in real-time
- Press `Ctrl+C` to exit

**What you'll see:**
```
nginx-net1 | 2026/04/06 16:41:49 [notice] 1#1: nginx/1.29.7
nginx-net2 | 2026/04/06 16:41:49 [notice] 1#1: nginx/1.29.7
nginx-net1 | GET / HTTP/1.1" 200 633
nginx-net2 | GET / HTTP/1.1" 200 633
```

✅ **What it means:** Both containers are running and serving requests

---

## **SECTION 8: CLEANUP (Optional)**

### Command 16: Stop All Containers
```powershell
docker-compose stop
```

**Explanation:**
- Gracefully stops all containers
- Containers are paused but not removed
- Can be restarted with `docker-compose start`

**Expected Output:**
```
Stopping nginx-net1 ... done
Stopping nginx-net2 ... done
```

---

### Command 17: Stop and Remove Everything
```powershell
docker-compose down
```

**Explanation:**
- Stops all containers
- Removes containers
- **Keeps networks for reuse**

**Expected Output:**
```
Stopping nginx-net1 ... done
Stopping nginx-net2 ... done
Removing nginx-net1 ... done
Removing nginx-net2 ... done
```

---

## **INTERVIEW NARRATIVE**

### What to Say:

> "I've built a Docker networking project that demonstrates network isolation and cross-network communication.
>
> **The Architecture:**
> - Two isolated bridge networks: network1 and network2
> - Two nginx containers: nginx-net1 (on network1) and nginx-net2 (on network2)
> - Containers are isolated by default and cannot communicate
>
> **The Demonstration:**
> - First, I show that nginx-net1 cannot reach nginx-net2 (DNS resolution fails)
> - Then, I use `docker network connect` to add nginx-net1 to network2
> - Finally, I prove communication works by having nginx-net1 successfully curl nginx-net2
>
> **Key Concepts:**
> - Docker's embedded DNS server enables service discovery
> - Bridge networks isolate traffic by default
> - Containers can be multi-homed (connected to multiple networks)
> - docker-compose automates container orchestration
>
> **Technologies Used:**
> - Docker & Docker Compose
> - Custom bridge networks
> - Port mapping
> - Volume mounting (custom HTML)
> - Health checks

---

## **QUICK REFERENCE - ALL COMMANDS IN ORDER**

```powershell
# 1. Verify Docker
docker --version

# 2. Navigate to project
cd "d:\sem 6\projects\devops\docker-networking"

# 3. View project files
ls -la

# 4. Start project
docker-compose up -d

# 5. Verify containers running
docker-compose ps

# 6. View networks
docker network ls

# 7. TEST ISOLATION (Should Fail)
docker exec nginx-net1 curl http://nginx-net2
# Expected: "Could not resolve host: nginx-net2"

# 8. Connect networks
docker network connect network2 nginx-net1

# 9. Verify connection
docker inspect nginx-net1 --format='{{json .NetworkSettings.Networks}}'

# 10. TEST COMMUNICATION (Should Succeed)
docker exec nginx-net1 curl http://nginx-net2
# Expected: HTTP 200 + HTML

# 11. Access from host
curl http://localhost:8081
curl http://localhost:8082

# 12. Inspect networks
docker network inspect network1
docker network inspect network2

# 13. View logs
docker-compose logs -f

# 14. Stop (optional)
docker-compose down
```

---

## **INTERVIEW TIPS**

✅ **What to Emphasize:**
- Understanding of Docker networking fundamentals
- Hands-on experience with custom networks
- Knowledge of DNS resolution in Docker
- Practical use of docker-compose
- Troubleshooting and verification skills

✅ **Expected Questions:**
- "Why can't containers communicate initially?" → Different networks, no DNS resolution
- "How did you enable communication?" → Used `docker network connect`
- "What's the difference between bridge and host networks?" → Isolation vs host namespace
- "Can containers be on multiple networks?" → Yes, multi-homed containers

✅ **Demo Confidence:**
- Everything is automated and repeatable
- All commands have expected outputs
- Easy to troubleshoot if something fails
- Project files are on GitHub for reference

---

**Your project is interview-ready!** 🚀
