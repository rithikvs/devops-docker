# 🔒 Docker Security Best Practices Guide

## Overview

This guide documents security best practices for Docker networking projects, specifically for the docker-networking demonstration.

---

## 📋 Table of Contents

1. [Container Security](#container-security)
2. [Network Security](#network-security)
3. [Image Security](#image-security)
4. [Runtime Security](#runtime-security)
5. [Production Checklist](#production-checklist)

---

## Container Security

### 1. Run Containers as Non-Root User

**Why:** Reduces impact of container escape vulnerabilities

```yaml
# docker-compose.yml
services:
  nginx-net1:
    image: nginx:latest
    user: "101:101"  # nginx user/group
    # OR
    # user: nobody
```

### 2. Use Read-Only Root Filesystem

**Why:** Prevents unauthorized file modifications

```yaml
services:
  nginx-net1:
    image: nginx:latest
    read_only: true
    volumes:
      - /run
      - /var/run
```

### 3. Limit Container Capabilities

**Why:** Restricts dangerous system calls

```yaml
services:
  nginx-net1:
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
```

### 4. Set Resource Limits

**Why:** Prevents DoS attacks and runaway processes

```yaml
services:
  nginx-net1:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
        reservations:
          cpus: '0.25'
          memory: 128M
```

---

## Network Security

### 1. Use Custom Bridge Networks

**Why:** Default bridge network has DNS disabled and less isolation

```powershell
# ✓ GOOD - Custom bridge network
docker network create --driver bridge myapp-network
docker run --network myapp-network nginx

# ✗ BAD - Default bridge network
docker run nginx
```

### 2. Disable Inter-Container Communication (icc)

**Why:** Containers can only talk to explicitly connected containers

```powershell
docker network create \
  --driver bridge \
  --opt com.docker.network.bridge.enable_icc=false \
  isolated-network
```

### 3. Implement Network Segmentation

**Why:** Limits blast radius of compromised container

```powershell
# Frontend network
docker network create frontend-network

# Backend network  
docker network create backend-network

# Only connect frontend container to both networks
docker run --network backend-network app
docker run --network frontend-network nginx
docker network connect frontend-network app  # Selective connection
```

### 4. Use Network Policies

**For Kubernetes or Docker Swarm:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: allowed-app
```

---

## Image Security

### 1. Use Specific Image Tags (Never `latest`)

**Why:** Ensures reproducible builds and prevents breaking changes

```yaml
# ✓ GOOD
image: nginx:1.25.1-alpine

# ✗ BAD
image: nginx:latest
```

### 2. Use Minimal Base Images

**Why:** Reduces attack surface

```dockerfile
# ✓ GOOD - 7MB
FROM nginx:1.25.1-alpine

# ✗ BAD - 140MB
FROM nginx:1.25.1
```

### 3. Scan Images for Vulnerabilities

**Tools:**
- Docker Scout: `docker scout cves nginx:1.25.1`
- Trivy: `trivy image nginx:1.25.1`
- Snyk: `snyk container test nginx:1.25.1`

```bash
# Example using Trivy
trivy image --severity HIGH,CRITICAL nginx:latest
```

### 4. Use Private Registries

**Why:** Prevents unauthorized image access

```powershell
# Login to private registry
docker login myregistry.azurecr.io

# Pull from private registry
docker pull myregistry.azurecr.io/nginx:1.25.1
```

### 5. Sign Images

**Using Docker Content Trust:**

```bash
export DOCKER_CONTENT_TRUST=1
docker push myregistry.azurecr.io/app:1.0
```

---

## Runtime Security

### 1. Enable AppArmor/SELinux

**Why:** Provides mandatory access control

```bash
# Check if enabled
docker info | grep -i security

# Run with custom profile
docker run --security-opt apparmor=docker-default nginx
```

### 2. Use Seccomp Profiles

**Why:** Restricts system calls

```yaml
services:
  nginx-net1:
    image: nginx:latest
    security_opt:
      - seccomp:unconfined  # ⚠️ Only for debugging
    # OR use custom profile
    # security_opt:
    #   - seccomp:/path/to/profile.json
```

### 3. Mount /etc/passwd as Read-Only

**Why:** Prevents user enumeration attacks

```yaml
services:
  nginx-net1:
    volumes:
      - /etc/passwd:/etc/passwd:ro
      - /etc/group:/etc/group:ro
```

### 4. Disable Privileged Mode (Default)

**Why:** Reduces container capabilities

```yaml
# ✗ NEVER do this in production
services:
  app:
    privileged: true  # SECURITY RISK!

# ✓ Use capabilities instead
services:
  app:
    cap_add:
      - NET_ADMIN
```

---

## Logging & Monitoring

### 1. Enable Container Logging

```yaml
services:
  nginx-net1:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
        labels: "service=nginx-net1"
```

### 2. Monitor Container Behavior

```powershell
# View logs
docker logs nginx-net1

# Monitor stats
docker stats

# View security events
docker events --filter type=security
```

### 3. Centralized Logging (ELK/Splunk)

```yaml
services:
  nginx-net1:
    logging:
      driver: splunk
      options:
        splunk-token: ${SPLUNK_TOKEN}
        splunk-url: https://logs.company.com:8088
```

---

## Secret Management

### 1. Use Docker Secrets (Swarm)

```bash
echo "my-secret" | docker secret create my-secret -
docker service create \
  --secret my-secret \
  --secret-target-filename /run/secrets/my-secret \
  nginx
```

### 2. Use Environment Variables Carefully

**✗ DON'T expose secrets in Dockerfile:**

```dockerfile
ENV DATABASE_PASSWORD=supersecret  # ✗ BAD
```

**✓ DO use build arguments:**

```bash
docker build --build-arg DB_PASS --secret db_pass
```

### 3. Use External Secret Management

```yaml
version: '3.9'
services:
  app:
    image: myapp:1.0
    environment:
      - DB_PASSWORD_FILE=/run/secrets/db_password
    secrets:
      - db_password

secrets:
  db_password:
    external: true  # Managed by HashiCorp Vault, AWS Secrets Manager, etc.
```

---

## Production Checklist

- [ ] **Images signed** with Docker Content Trust
- [ ] **No `latest` tags** - use specific versions
- [ ] **Containers run as non-root** user
- [ ] **Resource limits** configured (CPU, memory)
- [ ] **Read-only filesystem** enabled where possible
- [ ] **Custom bridge networks** used
- [ ] **Secrets not in environment** variables
- [ ] **Security scanning** enabled (Trivy, Scout)
- [ ] **AppArmor/SELinux** configured
- [ ] **Logging** centralized and monitored
- [ ] **Health checks** configured
- [ ] **Update policy** established
- [ ] **Backup strategy** in place
- [ ] **Incident response** plan documented

---

## Common Vulnerabilities (CVEs)

### Monitor These Resources:

- **Docker Advisory:** https://www.docker.com/blog/topic/security/
- **CVE Database:** https://cve.mitre.org/
- **GitHub Security Advisories:** https://github.com/advisories
- **Grype:** `grype dir:.` (Find vulnerabilities in code)

### Example: Check for known vulnerabilities

```bash
# Using Trivy
trivy image --severity HIGH,CRITICAL nginx:latest

# Using Docker Scout  
docker scout cves nginx:latest

# Using Snyk
snyk container test nginx:latest
```

---

## Security Testing

### 1. Penetration Testing

```bash
# Network connectivity test
docker exec nginx-net1 curl http://nginx-net2

# Port scanning
nmap -p 8081-8082 localhost

# Vulnerability scanning
tlsscan localhost:443
```

### 2. Compliance Testing

- CIS Docker Benchmark: https://www.cisecurity.org/benchmark/docker/
- PCI DSS requirements for containers
- HIPAA compliance for healthcare apps

---

## References

- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [OWASP Container Security](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [Docker Security Advisory](https://www.docker.com/security/)

---

**Last Updated:** 2026-04-07  
**Version:** 1.0
