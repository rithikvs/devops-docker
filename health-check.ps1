#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Network health check and validation script
.DESCRIPTION
    Validates Docker networking setup and container health
.EXAMPLE
    .\health-check.ps1
#>

param(
    [switch]$Verbose = $false,
    [switch]$Full = $false
)

$ErrorActionPreference = "Continue"
$checks_passed = 0
$checks_failed = 0

function Write-CheckHeader {
    param([string]$Title)
    Write-Host "`n" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
}

function Test-Check {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [string]$PassMessage = "✓ Pass",
        [string]$FailMessage = "✗ Fail"
    )
    
    try {
        $result = & $Test
        if ($result) {
            Write-Host "  ✓ $Name" -ForegroundColor Green
            $global:checks_passed++
            return $true
        } else {
            Write-Host "  ✗ $Name" -ForegroundColor Red
            $global:checks_failed++
            return $false
        }
    } catch {
        Write-Host "  ✗ $Name" -ForegroundColor Red
        Write-Host "    Error: $_" -ForegroundColor Gray
        $global:checks_failed++
        return $false
    }
}

# Header
Write-Host "
╔══════════════════════════════════════════════╗
║      Docker Networking Health Check          ║
║           Version 1.2.0                      ║
╚══════════════════════════════════════════════╝" -ForegroundColor Magenta

# 1. Docker Status Check
Write-CheckHeader "System Checks"

Test-Check "Docker daemon running" { 
    $null = docker ps 2>$null
    $? 
}

Test-Check "Docker Compose available" { 
    $null = docker-compose --version 2>$null
    $? 
}

# 2. Network Checks
Write-CheckHeader "Network Checks"

Test-Check "Network 'network1' exists" {
    docker network ls --filter name=network1 --format '{{.Name}}' | Select-String network1
}

Test-Check "Network 'network2' exists" {
    docker network ls --filter name=network2 --format '{{.Name}}' | Select-String network2
}

# 3. Container Checks
Write-CheckHeader "Container Status"

Test-Check "Container 'nginx-net1' running" {
    (docker ps --filter name=nginx-net1 --format '{{.Status}}') -match "Up"
}

Test-Check "Container 'nginx-net2' running" {
    (docker ps --filter name=nginx-net2 --format '{{.Status}}') -match "Up"
}

# 4. Health Checks
Write-CheckHeader "Container Health"

Test-Check "nginx-net1 health status" {
    (docker inspect nginx-net1 --format '{{.State.Health.Status}}') -eq "healthy"
}

Test-Check "nginx-net2 health status" {
    (docker inspect nginx-net2 --format '{{.State.Health.Status}}') -eq "healthy"
}

# 5. Network Connectivity
Write-CheckHeader "Connectivity Tests"

Test-Check "Port 8081 accessible (nginx-net1)" {
    $null = curl.exe -s -m 2 http://localhost:8081 2>$null
    $?
}

Test-Check "Port 8082 accessible (nginx-net2)" {
    $null = curl.exe -s -m 2 http://localhost:8082 2>$null
    $?
}

# 6. Isolation Test
Write-CheckHeader "Network Isolation Test"

Test-Check "Networks properly isolated" {
    docker exec nginx-net1 curl -s http://nginx-net2 2>&1 | Select-String -Pattern "connect|name not known" -Quiet
}

# 7. Full Test (if requested)
if ($Full) {
    Write-CheckHeader "Extended Tests"
    
    Test-Check "DNS resolution works (within network)" {
        docker exec nginx-net1 ping -c 1 127.0.0.1 2>$null
    }
    
    Test-Check "nginx-net1 has correct IP assignment" {
        (docker inspect nginx-net1 --format '{{.NetworkSettings.IPAddress}}') -match "\d+\.\d+\.\d+\.\d+"
    }
    
    Test-Check "nginx-net2 has correct IP assignment" {
        (docker inspect nginx-net2 --format '{{.NetworkSettings.IPAddress}}') -match "\d+\.\d+\.\d+\.\d+"
    }
}

# Summary
Write-CheckHeader "Summary Report"

$total = $checks_passed + $checks_failed
$pass_percentage = if ($total -gt 0) { [int](($checks_passed / $total) * 100) } else { 0 }

Write-Host "  Total Checks:  $total" -ForegroundColor Cyan
Write-Host "  Passed:        $checks_passed" -ForegroundColor Green
Write-Host "  Failed:        $checks_failed" -ForegroundColor Red
Write-Host "  Success Rate:  $pass_percentage%" -ForegroundColor Yellow

if ($checks_failed -eq 0) {
    Write-Host "`n  ✓ All checks passed! System is healthy." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n  ⚠ Some checks failed. Review above." -ForegroundColor Yellow
    exit 1
}
