# Docker Networking Setup Script for Windows PowerShell
# This script automates the entire Docker networking demonstration

param(
    [switch]$NoCleanup = $false,
    [switch]$SkipTests = $false
)

# Color configuration
function Write-Header {
    param([string]$Message)
    Write-Host "`n" -NoNewline
    Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Cyan
}

# Check if Docker is installed
function Check-Docker {
    Write-Header "Checking Docker Installation"
    try {
        $dockerVersion = docker --version
        Write-Success "Docker is installed"
        Write-Host $dockerVersion
        return $true
    }
    catch {
        Write-Error-Custom "Docker is not installed. Please install Docker Desktop."
        exit 1
    }
}

# Check if Docker daemon is running
function Check-DockerDaemon {
    Write-Header "Checking Docker Daemon"
    try {
        docker ps | Out-Null
        Write-Success "Docker daemon is running"
        return $true
    }
    catch {
        Write-Error-Custom "Docker daemon is not running. Please start Docker Desktop."
        exit 1
    }
}

# Cleanup previous setup
function Cleanup-Setup {
    Write-Header "Cleaning Up Previous Setup"
    
    Write-Info "Stopping containers..."
    docker stop nginx-net1 nginx-net2 2>$null
    Start-Sleep -Milliseconds 500
    
    Write-Info "Removing containers..."
    docker rm nginx-net1 nginx-net2 2>$null
    Start-Sleep -Milliseconds 500
    
    Write-Info "Removing networks..."
    docker network rm network1 network2 2>$null
    Start-Sleep -Milliseconds 500
    
    Write-Success "Cleanup complete"
}

# Create networks
function Create-Networks {
    Write-Header "Creating Custom Bridge Networks"
    
    docker network create network1
    Write-Success "Created network1"
    
    docker network create network2
    Write-Success "Created network2"
    
    Write-Host "`nNetworks created:" -ForegroundColor Cyan
    docker network ls | Where-Object { $_ -match "network1|network2" }
}

# Run containers
function Run-Containers {
    Write-Header "Running NGINX Containers"
    
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectDir = Split-Path -Parent $scriptDir
    
    Write-Info "Starting nginx-net1 in network1..."
    docker run -d `
        --name nginx-net1 `
        --network network1 `
        -p 8081:80 `
        -v "$projectDir/nginx-net1-index.html:/usr/share/nginx/html/index.html" `
        nginx:latest | Out-Null
    Write-Success "Started nginx-net1 (port 8081)"
    
    Write-Info "Starting nginx-net2 in network2..."
    docker run -d `
        --name nginx-net2 `
        --network network2 `
        -p 8082:80 `
        -v "$projectDir/nginx-net2-index.html:/usr/share/nginx/html/index.html" `
        nginx:latest | Out-Null
    Write-Success "Started nginx-net2 (port 8082)"
    
    # Wait for containers
    Write-Info "Waiting for containers to be ready..."
    Start-Sleep -Seconds 3
    
    Write-Host "`nRunning containers:" -ForegroundColor Cyan
    docker ps --filter "name=nginx-net"
}

# Test isolation
function Test-Isolation {
    Write-Header "Testing Network Isolation (Should FAIL)"
    
    $containerId = docker ps -q -f name=nginx-net1
    
    Write-Warning-Custom "Attempting to ping nginx-net2 from nginx-net1 (should fail)..."
    try {
        $pingResult = docker exec $containerId ping -c 2 nginx-net2 2>&1
        Write-Error-Custom "Containers can communicate! Networks are not isolated."
        return $false
    }
    catch {
        Write-Success "Networks are properly isolated - ping failed as expected"
    }
    
    Write-Warning-Custom "Attempting curl from nginx-net1 to nginx-net2 (should fail)..."
    try {
        $curlResult = docker exec $containerId timeout 2 curl -s http://nginx-net2 2>&1
        if ($curlResult) {
            Write-Error-Custom "Containers can communicate! Networks are not isolated."
            return $false
        }
    }
    catch {
        Write-Success "Networks are properly isolated - curl failed as expected"
    }
    
    return $true
}

# Connect networks
function Connect-Networks {
    Write-Header "Connecting nginx-net1 to network2"
    
    docker network connect network2 nginx-net1
    Write-Success "Connected nginx-net1 to network2"
    
    Start-Sleep -Seconds 2
    
    Write-Host "`nNetwork assignments:" -ForegroundColor Cyan
    docker inspect nginx-net1 | ConvertFrom-Json | Select-Object -ExpandProperty NetworkSettings | 
        Select-Object -ExpandProperty Networks | Format-Table -AutoSize
}

# Test communication after connection
function Test-Communication {
    Write-Header "Testing Communication After Network Connection (Should SUCCEED)"
    
    $containerId = docker ps -q -f name=nginx-net1
    
    Write-Info "Attempting to ping nginx-net2 from nginx-net1 (should succeed)..."
    try {
        docker exec $containerId ping -c 2 nginx-net2
        Write-Success "Ping successful - containers can now communicate!"
    }
    catch {
        Write-Error-Custom "Ping failed - check network connectivity"
        return $false
    }
    
    Write-Info "Attempting curl from nginx-net1 to nginx-net2 (should succeed)..."
    try {
        $curlResult = docker exec $containerId curl -s http://nginx-net2
        if ($curlResult) {
            Write-Success "Curl successful - containers can communicate via HTTP!"
        }
        else {
            Write-Error-Custom "Curl failed - check container health"
            return $false
        }
    }
    catch {
        Write-Error-Custom "Curl failed - check container health"
        return $false
    }
    
    return $true
}

# Show summary
function Show-Summary {
    Write-Header "Setup Complete - Summary"
    
    Write-Host "Networks:" -ForegroundColor Green
    docker network ls | Where-Object { $_ -match "network1|network2" } | 
        ForEach-Object { "  • $_" }
    
    Write-Host "`nContainers:" -ForegroundColor Green
    docker ps --filter "name=nginx-net" | Select-Object -Skip 1 |
        ForEach-Object { "  • $_" }
    
    Write-Host "`nWeb Access:" -ForegroundColor Green
    Write-Host "  • nginx-net1: " -ForegroundColor White -NoNewline
    Write-Host "http://localhost:8081" -ForegroundColor Blue
    Write-Host "  • nginx-net2: " -ForegroundColor White -NoNewline
    Write-Host "http://localhost:8082" -ForegroundColor Blue
    
    Write-Host "`nUseful Commands:" -ForegroundColor Yellow
    Write-Host "  View logs:       docker logs -f nginx-net1"
    Write-Host "  Stop containers: docker-compose down"
    Write-Host "  Exec into container: docker exec -it nginx-net1 sh"
    Write-Host "  Inspect network: docker network inspect network1"
}

# Main execution
function Main {
    Write-Header "Docker Networking Setup Script for Windows"
    Write-Info "This script will set up isolated Docker networks with nginx containers"
    
    Check-Docker
    Check-DockerDaemon
    
    Read-Host "Press Enter to continue or Ctrl+C to cancel"
    
    if (-not $NoCleanup) {
        Cleanup-Setup
    }
    
    Create-Networks
    Run-Containers
    
    if (-not $SkipTests) {
        Test-Isolation
        Connect-Networks
        Test-Communication
    }
    
    Show-Summary
    
    Write-Header "All steps completed successfully!"
}

# Run main function
Main
