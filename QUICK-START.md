# QUICK START GUIDE - Copy-Paste Commands

## Project Location
```
d:\sem 6\projects\devops\docker-networking\
```

---

## OPTION 1: DOCKER COMPOSE (Recommended - Easiest)

### Start Everything
```powershell
cd "d:\sem 6\projects\devops\docker-networking"
docker-compose up -d
docker-compose ps
```

### Logs
```powershell
docker-compose logs -f
```

### Stop Everything
```powershell
docker-compose down
```

---

## OPTION 2: MANUAL SETUP (Step-by-step)

### Step 1: Create Networks
```powershell
docker network create network1
docker network create network2
docker network ls
```

### Step 2: Run Container 1 (Network 1)
```powershell
cd "d:\sem 6\projects\devops\docker-networking"

docker run -d `
  --name nginx-net1 `
  --network network1 `
  -p 8081:80 `
  -v "$(pwd)/nginx-net1-index.html:/usr/share/nginx/html/index.html" `
  nginx:latest
```

### Step 3: Run Container 2 (Network 2)
```powershell
docker run -d `
  --name nginx-net2 `
  --network network2 `
  -p 8082:80 `
  -v "$(pwd)/nginx-net2-index.html:/usr/share/nginx/html/index.html" `
  nginx:latest
```

### Step 4: Verify Containers Running
```powershell
docker ps --filter "name=nginx-net"
```

---

## TESTING - PHASE 1: ISOLATION (Should Fail)

### Test Ping (Network 1 → Network 2) - WILL FAIL
```powershell
$CONTAINER_NET1=$(docker ps -q -f name=nginx-net1)
docker exec $CONTAINER_NET1 ping nginx-net2
```

**Expected Result:** Ping fails with "Name or service not known"

### Test Curl (Network 1 → Network 2) - WILL FAIL
```powershell
docker exec $CONTAINER_NET1 curl http://nginx-net2
```

**Expected Result:** Timeout or connection refused

---

## CONNECT NETWORKS - Bridge the Gap

### Connect Container 1 to Network 2
```powershell
docker network connect network2 nginx-net1
```

### Verify Connection
```powershell
docker inspect network2
```

---

## TESTING - PHASE 2: COMMUNICATION (Should Succeed)

### Test Ping (Network 1 → Network 2) - NOW WORKS
```powershell
$CONTAINER_NET1=$(docker ps -q -f name=nginx-net1)
docker exec $CONTAINER_NET1 ping nginx-net2
```

**Expected Result:** Ping succeeds with response times

### Test Curl (Network 1 → Network 2) - NOW WORKS
```powershell
docker exec $CONTAINER_NET1 curl http://nginx-net2
```

**Expected Result:** Returns HTML from nginx-net2

---

## WEB ACCESS

Open in browser:
- nginx-net1: **http://localhost:8081**
- nginx-net2: **http://localhost:8082**

---

## CLEANUP

### Stop and Remove Containers
```powershell
docker-compose down
```

### Or Remove Manually
```powershell
docker stop nginx-net1 nginx-net2
docker rm nginx-net1 nginx-net2
docker network rm network1 network2
```

### Full System Cleanup
```powershell
docker system prune -a --volumes
```

---

## WINDOWS POWERSHELL AUTOMATION SCRIPT

### Run Automated Setup
```powershell
cd "d:\sem 6\projects\devops\docker-networking\scripts"
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\setup.ps1
```

### With Options
```powershell
# Skip cleanup of previous setup
.\setup.ps1 -NoCleanup

# Skip tests
.\setup.ps1 -SkipTests
```

---

## ADVANCED TESTING - Inside Container Shell

### Enter Container 1
```powershell
docker exec -it nginx-net1 sh
```

### Inside Container - DNS Check
```bash
# Resolve nginx-net2 hostname (before connection: fails, after: works)
nslookup nginx-net2

# Ping test
ping -c 3 nginx-net2

# Curl test
curl http://nginx-net2

# Exit shell
exit
```

---

## TROUBLESHOOTING

### Check Network Details
```powershell
docker network inspect network1
docker network inspect network2
```

### Check Container Networks
```powershell
docker inspect nginx-net1 | findstr /A:2 "Networks"
docker inspect nginx-net2 | findstr /A:2 "Networks"
```

### View Container Logs
```powershell
docker logs nginx-net1
docker logs nginx-net2
```

### Container IP Addresses
```powershell
docker inspect -f '{{.Name}} = {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' nginx-net1
docker inspect -f '{{.Name}} = {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' nginx-net2
```

---

## FILE LOCATIONS
```
docker-networking/
├── docker-compose.yml          ← Full config (requires no setup)
├── nginx-net1-index.html       ← Custom page for container 1
├── nginx-net2-index.html       ← Custom page for container 2
├── README.md                   ← Full documentation
├── .dockerignore               ← Build exclusions
└── scripts/
    ├── setup.ps1               ← Windows automation script
    └── setup.sh                ← Linux/Mac automation script
```

---

## WHAT THIS DEMONSTRATES

✓ Custom bridge networks isolation
✓ DNS service discovery
✓ Container-to-container communication
✓ Network connectivity troubleshooting
✓ Real-world multi-network scenarios
✓ Container orchestration basics

---

## NEXT STEPS

1. **Install Docker Desktop** (if not already)
2. **Run docker-compose up -d**
3. **Follow testing phases above**
4. **Explore docker inspect commands**
5. **Review docker-compose.yml** for configuration details
