# FRESH COMMANDS - CLEAN WORKFLOW FOR INTERVIEW

Copy and paste these commands in order for a perfect demo.

---

## **SECTION 1: START (2 minutes)**

```powershell
# Step 1: Navigate to project
cd "d:\sem 6\projects\devops\docker-networking"

# Step 2: Start all containers
docker-compose up -d

# Step 3: Verify running
docker-compose ps

# Step 4: Show networks created
docker network ls | findstr network
```

**What you should see:**
- 2 containers: nginx-net1 and nginx-net2 (status: healthy, running)
- 2 networks: network1 and network2 (driver: bridge)

---

## **SECTION 2: TEST ISOLATION - FAILURE (1 minute)**

```powershell
# Try to access nginx-net2 from nginx-net1
docker exec nginx-net1 curl http://nginx-net2
```

**Expected Output:**
```
curl: (6) Could not resolve host: nginx-net2
```

**Explanation for Interviewer:**
"As you can see, nginx-net1 cannot reach nginx-net2 because they are on separate, isolated networks. The DNS lookup fails because Docker's embedded DNS doesn't resolve hostnames across network boundaries."

---

## **SECTION 3: BRIDGE NETWORKS - CONNECTION (1 minute)**

```powershell
# Connect nginx-net1 to network2
docker network connect network2 nginx-net1

# Verify the connection
docker inspect nginx-net1 --format='{{json .NetworkSettings.Networks}}'
```

**Expected to See:**
- nginx-net1 now has 2 network entries (network1 + network2)
- Each network has a different IP address

**Explanation for Interviewer:**
"Now I've connected the container to the second network using `docker network connect`. The container is now multi-homed - it has interfaces on both networks. Docker's DNS will now resolve nginx-net2."

---

## **SECTION 4: TEST COMMUNICATION - SUCCESS (1 minute)**

```powershell
# Try to access nginx-net2 from nginx-net1 (NOW IT WORKS)
docker exec nginx-net1 curl http://nginx-net2
```

**Expected Output:**
```html
<!DOCTYPE html>
<html>
<head>
    <title>nginx-net2</title>
    ...
    <h1>✓ NGINX Container - Network 2</h1>
    <p><strong>Container Name:</strong> nginx-net2</p>
    <p><strong>Network:</strong> network2</p>
    <p><strong>Port:</strong> 8082 (mapped to 80)</p>
    <p><strong>Status:</strong> Running Successfully</p>
    ...
</html>
100   633  100   633    0     0
```

**Explanation for Interviewer:**
"Perfect! Now communication works. We got HTTP 200 response with the full HTML from nginx-net2. This proves that:
1. DNS resolution now works across networks
2. Network routes exist between the networks
3. Container-to-container communication is established
4. Multi-homed containers can communicate across their networks"

---

## **SECTION 5: VERIFY FROM HOST (2 minutes)**

```powershell
# Access containers from host machine
curl http://localhost:8081

curl http://localhost:8082
```

**Expected:** Both return HTML pages with container identification

**Explanation for Interviewer:**
"These show that the containers are accessible from the host machine via port mapping (8081→nginx-net1, 8082→nginx-net2)."

---

## **SECTION 6: INSPECT NETWORKS (1 minute)**

```powershell
# View details of network1
docker network inspect network1

# View details of network2
docker network inspect network2
```

**Key Info to Point Out:**
- network1: Only contains nginx-net1
- network2: Contains both nginx-net1 and nginx-net2

**Explanation for Interviewer:**
"These details show the network topology. Notice how nginx-net1 has different IP addresses on each network (172.17.0.2 on network1, 172.18.0.3 on network2). This multi-homing is what enables cross-network communication."

---

## **INTERVIEW TALKING POINTS**

When demonstrating, explain:

1. **Initial State (Isolation):**
   "We have two isolated networks with containers running on each. By default, they cannot communicate because Docker's bridge driver isolates traffic."

2. **DNS Resolution:**
   "Docker provides an embedded DNS server that resolves container names to IPs, but only within the same network. That's why the first curl failed."

3. **Network Connection:**
   "Using `docker network connect`, we can dynamically add a container to another network without restarting it."

4. **Multi-Homing:**
   "The container now has 2 IP addresses - one on each network - allowing it to communicate across networks."

5. **Practical Use Cases:**
   - Microservices on different networks with selective connectivity
   - Security isolation with controlled access points
   - Legacy systems integration
   - Multi-tenant applications

---

## **WHAT TO EMPHASIZE**

✅ Docker networking fundamentals (bridge networks, isolation)
✅ Docker DNS and service discovery
✅ Practical container orchestration with compose
✅ Network troubleshooting and inspection
✅ Real-world application (selective connectivity)

**Turn Key Statements:**
- "We demonstrated network isolation by default"
- "We enabled communication through dynamic network connection"
- "We proved multi-way communication works"
- "This is how Docker enables microservices to communicate selectively"

---

## **IF SOMETHING GOES WRONG**

```powershell
# Check container logs
docker-compose logs -f

# Restart containers
docker-compose down
docker-compose up -d

# Reset everything
docker-compose down
docker system prune -a
docker-compose up -d
```

---

## **GITHUB REFERENCE**

Repository: https://github.com/rithikvs/devops-docker

All code and documentation are version-controlled and reproducible.

---

**Ready for your interview!** This workflow takes about 5-10 minutes and demonstrates solid Docker networking knowledge. 🚀
