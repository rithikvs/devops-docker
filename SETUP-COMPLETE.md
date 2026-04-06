# 🐳 DOCKER NETWORKING PROJECT - COMPLETE GUIDE

## 📁 Project Location
```
d:\sem 6\projects\devops\docker-networking\
```

---

## 📋 PROJECT CONTENTS

```
docker-networking/
├── docker-compose.yml          ← Complete Docker Compose config
├── nginx-net1-index.html       ← Custom page for container in network1
├── nginx-net2-index.html       ← Custom page for container in network2
├── .dockerignore               ← Docker build exclusions
├── README.md                   ← Full documentation
├── QUICK-START.md              ← Quick reference guide
├── COMMANDS-REFERENCE.md       ← Detailed command reference
├── SETUP-COMPLETE.md           ← This file
└── scripts/
    ├── setup.ps1               ← Windows PowerShell automation
    └── setup.sh                ← Linux/Mac bash automation
```

---

## ⚡ FASTEST START (3 Commands)

```powershell
cd "d:\sem 6\projects\devops\docker-networking"
docker-compose up -d
docker-compose ps
```

Then browse:
- http://localhost:8081 (nginx in network1)
- http://localhost:8082 (nginx in network2)

---

## 🚀 FULL DEMONSTRATION (Copy & Paste)

### 1. Navigate to Project
```powershell
cd "d:\sem 6\projects\devops\docker-networking"
```

### 2. Start Services with Compose
```powershell
docker-compose up -d
```

Output:
```
Creating network "network1" with driver "bridge"
Creating network "network2" with driver "bridge"
Creating nginx-net1 ... done
Creating nginx-net2 ... done
```

### 3. Verify Services Running
```powershell
docker-compose ps
```

Output:
```
NAME        IMAGE         COMMAND                 STATUS
nginx-net1  nginx:latest  nginx -g daemon off;    Up (healthy)
nginx-net2  nginx:latest  nginx -g daemon off;    Up (healthy)
```

### 4. View Networks Created
```powershell
docker network ls | findstr network
```

Output:
```
network1  bridge  3f7c4a...
network2  bridge  8d2e1b...
```

### 5. View Network Details
```powershell
docker network inspect network1
docker network inspect network2
```

---

## 🔴 PHASE 1: TEST ISOLATION (Should FAIL)

### Test 1A: Ping (network1 → network2)
```powershell
docker exec nginx-net1 ping nginx-net2
```

**Expected Output:**
```
unknown host
Name or service not known
```

✓ **SUCCESS**: Containers CANNOT communicate (networks properly isolated)

---

### Test 1B: Curl (network1 → network2)
```powershell
docker exec nginx-net1 curl http://nginx-net2
```

**Expected Output:**
```
curl: (7) Failed to connect to nginx-net2 port 80
```

✓ **SUCCESS**: HTTP request fails (isolation confirmed)

---

### Test 1C: Connection Details (Show Why)
```powershell
docker inspect network1 | findstr -A 10 "Containers"
```

Output shows only `nginx-net1` container on network1

---

## 🟢 PHASE 2: CONNECT NETWORKS

### Connect Container to Second Network
```powershell
docker network connect network2 nginx-net1
```

Output:
```
(no output = success)
```

### Verify Connection Was Successful
```powershell
docker inspect network2
```

Output now shows BOTH containers:
- nginx-net1 (newly added, IP: 172.18.0.3)
- nginx-net2 (original, IP: 172.18.0.2)

### View Container's Multiple Networks
```powershell
docker inspect nginx-net1 | findstr -A 2 "NetworkSettings"
```

Output shows:
```
"network1": {IP: 172.17.0.2}
"network2": {IP: 172.18.0.3}
```

✓ **SUCCESS**: Container now connected to both networks

---

## 🟢 PHASE 3: TEST COMMUNICATION (Should SUCCEED)

### Test 3A: Ping (network1 → network2) - NOW WORKS
```powershell
docker exec nginx-net1 ping -c 3 nginx-net2
```

**Expected Output:**
```
PING nginx-net2 (172.18.0.2): 56 data bytes
64 bytes: seq=0 ttl=64 time=0.123 ms
64 bytes: seq=1 ttl=64 time=0.098 ms
64 bytes: seq=2 ttl=64 time=0.087 ms
```

✓ **SUCCESS**: Ping works! Containers communicate.

---

### Test 3B: Curl (network1 → network2) - NOW WORKS
```powershell
docker exec nginx-net1 curl http://nginx-net2
```

**Expected Output:**
```html
<!DOCTYPE html>
<html>
<head>
    <title>nginx-net2</title>
    <style>
        body { font-family: Arial; background: #f3e5f5; padding: 40px; }
```

✓ **SUCCESS**: HTTP request succeeds! Full communication restored.

---

### Test 3C: Full HTML Retrieved
```powershell
docker exec nginx-net1 curl -s http://nginx-net2 | findstr "nginx-net2"
```

Output:
```
<title>nginx-net2</title>
<h1>✓ NGINX Container - Network 2</h1>
```

✓ **SUCCESS**: Full HTML page retrieved

---

## 🔧 INTERACTIVE TESTING IN CONTAINER SHELL

### Enter Container Shell
```powershell
docker exec -it nginx-net1 sh
```

### Inside Container - DNS Test (Shows Service Discovery)
```bash
# Before connection to network2:
nslookup nginx-net2
# Result: nslookup: command not found or <ip-addr> (after connection)

# After connection to network2:
nslookup nginx-net2  
# Result: returns 172.18.0.2

# Or with busybox:
ping nginx-net2 -c 3
# Works after connection!

# HTTP test
curl http://nginx-net2:80
# Returns HTML from nginx-net2

# Check hostname
hostname

# View network interfaces
ip addr show
# Shows eth0 (network1) and eth1 (network2 after connection)

# View routing
ip route show
# Shows routes to both networks

# Exit container
exit
```

---

## 🌐 WEB INTERFACE ACCESS

Once running, open in web browser:

**Network 1 Container:**
```
http://localhost:8081
```
Shows: "nginx Container - Network 1"

**Network 2 Container:**
```
http://localhost:8082
```
Shows: "nginx Container - Network 2"

---

## 📊 NETWORK TOPOLOGY AFTER CONNECTION

```
┌──────────────────────────────────────┐
│         Docker Host                  │
├──────────────────────────────────────┤
│                                      │
│  ┌─────────────────┐ ┌──────────┐  │
│  │   network1      │ │network2  │  │
│  │ (172.17.0.0/16)│ │(172.18..)│  │
│  │                 │ │          │  │
│  │  nginx-net1     │ │nginx-net2│  │
│  │ 172.17.0.2      │ │172.18.0.2│  │
│  │ 172.18.0.3◄─────┼─┤(connected)  │
│  └─────────────────┘ └──────────┘  │
│        :8081              :8082     │
│         ↓                  ↓        │
│    localhost:8081  localhost:8082   │
└──────────────────────────────────────┘

✓ Both HTTP endpoints accessible
✓ Container-to-container communication enabled
✓ Cross-network connectivity established
```

---

## 🛑 CLEANUP & STOP

### Stop All Services
```powershell
docker-compose stop
```

### Stop and Remove (Complete Cleanup)
```powershell
docker-compose down
```

Output:
```
Stopping nginx-net1 ... done
Stopping nginx-net2 ... done
Removing nginx-net1 ... done
Removing nginx-net2 ... done
Removing network network1 ... done
Removing network network2 ... done
```

### Complete System Cleanup
```powershell
docker system prune -a --volumes
```

⚠️ This removes all unused images, networks, and volumes

---

## 🕹️ ALTERNATIVE: AUTOMATED SETUP SCRIPT

### Run Windows PowerShell Automation
```powershell
cd "d:\sem 6\projects\devops\docker-networking\scripts"
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\setup.ps1
```

The script automatically:
- ✓ Cleans previous setup
- ✓ Creates networks
- ✓ Runs containers
- ✓ Tests isolation (shows failure)
- ✓ Connects networks
- ✓ Tests communication (shows success)
- ✓ Displays summary

---

## 📋 TROUBLESHOOTING

### Issue: "docker: command not found"
**Solution:** Install Docker Desktop from https://www.docker.com/products/docker-desktop

### Issue: Port 8081 or 8082 already in use
**Edit docker-compose.yml:**
```yaml
ports:
  - "8083:80"    # Change 8081 to 8083 (or any unused port)
```

### Issue: Containers can't find each other
**Check 1:** Verify networks exist
```powershell
docker network ls
```

**Check 2:** Verify containers connected
```powershell
docker inspect nginx-net1 | findstr Networks
```

**Check 3:** Restart Docker daemon
```powershell
# Windows: Restart Docker Desktop from taskbar
```

### Issue: DNS not resolving
**Test:** 
```powershell
docker exec -it nginx-net1 sh
# Inside container:
nslookup nginx-net2
```

Docker's embedded DNS server (127.0.0.11:53) should resolve it.

---

## 🧠 KEY CONCEPTS DEMONSTRATED

| Concept | What Happens |
|---------|--------------|
| **Isolation** | Default behavior - containers on different networks can't communicate |
| **Bridge Networks** | Custom networks isolate traffic between containers |
| **Service Discovery** | Docker DNS allows container names to resolve within a network |
| **Network Connection** | `docker network connect` adds a container to additional networks |
| **Multi-Network Containers** | One container can belong to multiple networks simultaneously |
| **Port Mapping** | Maps container ports to host for external access (8081→80) |
| **Volume Mounting** | Custom HTML files shown to demonstrate container identification |

---

## 📚 DOCUMENTATION FILES

| File | Purpose |
|------|---------|
| **README.md** | Complete project documentation |
| **QUICK-START.md** | Quick reference with copy-paste commands |
| **COMMANDS-REFERENCE.md** | Detailed all Docker commands with output examples |
| **docker-compose.yml** | Docker Compose configuration (main setup file) |
| **scripts/setup.ps1** | Automated setup for Windows |
| **scripts/setup.sh** | Automated setup for Linux/Mac |

---

## ✅ VERIFICATION CHECKLIST

After running all commands, verify:

- [ ] Two docker networks created (network1, network2)
- [ ] Two containers running (nginx-net1, nginx-net2)
- [ ] Port 8081 accessible in browser (shows network1 container)
- [ ] Port 8082 accessible in browser (shows network2 container)
- [ ] Ping fails initially (isolation confirmed)
- [ ] After docker network connect, ping succeeds
- [ ] Curl works after connection (HTTP response)
- [ ] docker inspect shows container on both networks
- [ ] Container shell works (docker exec -it)
- [ ] DNS resolution works after network connection

---

## 🎓 LEARNING OUTCOMES

After completing this project, you understand:

✓ How Docker custom bridge networks work
✓ How container isolation is enforced
✓ What DNS service discovery is
✓ How to connect containers across networks
✓ How multi-network containers function
✓ Basic Docker debugging techniques
✓ docker-compose configuration
✓ Container networking troubleshooting

---

## 🔗 USEFUL COMMANDS QUICK REFERENCE

```powershell
# Start services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Test network interaction
docker exec nginx-net1 ping nginx-net2

# Connect container to network
docker network connect network2 nginx-net1

# Stop services
docker-compose down

# Full cleanup
docker system prune -a --volumes
```

---

## 🎯 NEXT STEPS

1. **Install Docker Desktop** (if not already installed)
2. **Run docker-compose up -d** in the project directory
3. **Follow the Phase 1, 2, and 3 tests** above
4. **Review COMMANDS-REFERENCE.md** for advanced commands
5. **Explore docker inspect** output to understand network details
6. **Modify docker-compose.yml** to add more containers/networks
7. **Create custom bridge networks** manually with `docker network create`
8. **Experiment with different network drivers** (overlay, host, none)

---

## 📞 SUPPORT RESOURCES

- Docker Networking Docs: https://docs.docker.com/network/
- Docker Compose Docs: https://docs.docker.com/compose/
- Docker CLI Reference: https://docs.docker.com/engine/reference/commandline/
- Troubleshooting: https://docs.docker.com/config/containers/container-networking/

---

**Created:** April 6, 2026
**Project Type:** Docker Networking Demonstration
**Status:** ✅ Ready to Deploy
