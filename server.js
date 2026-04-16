const express = require('express');
const { execSync } = require('child_process');
const path = require('path');

const app = express();
const PORT = 3000;

// Middleware
app.use(express.static(path.join(__dirname)));
app.use(express.json());

// Helper function to run Docker commands
function runCommand(command) {
  try {
    console.log(`[${new Date().toLocaleTimeString()}] Executing: ${command}`);
    const output = execSync(command, { 
      encoding: 'utf-8',
      shell: true,
      stdio: ['pipe', 'pipe', 'pipe']
    });
    console.log(`✅ Success`);
    return { success: true, output: output.trim() };
  } catch (error) {
    const errorMsg = error.stderr ? error.stderr.toString() : error.message;
    console.log(`❌ Error: ${errorMsg}`);
    return { success: false, output: errorMsg };
  }
}

// ===== NETWORK OPERATIONS =====

// Create Network
app.post('/api/create-network', (req, res) => {
  const { networkName } = req.body;
  console.log(`🌐 Creating network: ${networkName}...`);
  
  const result = runCommand(`docker network create ${networkName}`);
  res.json({
    action: 'Create Network',
    network: networkName,
    success: result.success,
    message: result.success ? `✅ Network "${networkName}" created!` : `❌ Failed to create network`,
    details: result.output
  });
});

// Delete Network
app.post('/api/delete-network', (req, res) => {
  const { networkName } = req.body;
  console.log(`🗑️ Deleting network: ${networkName}...`);
  
  const result = runCommand(`docker network rm ${networkName}`);
  res.json({
    action: 'Delete Network',
    network: networkName,
    success: result.success,
    message: result.success ? `✅ Network "${networkName}" deleted!` : `❌ Failed to delete network`,
    details: result.output
  });
});

// List Networks
app.get('/api/networks', (req, res) => {
  console.log('📋 Listing networks...');
  const result = runCommand('docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}"');
  res.json({
    action: 'List Networks',
    success: result.success,
    details: result.output
  });
});

// ===== CONTAINER OPERATIONS =====

// Create Container
app.post('/api/create-container', (req, res) => {
  const { containerName, networkName, image } = req.body;
  console.log(`📦 Creating container: ${containerName} on network: ${networkName}...`);
  
  // Create container without --rm so it persists in Docker Desktop
  const command = `docker run -d --name ${containerName} --network ${networkName} ${image} tail -f /dev/null`;
  const result = runCommand(command);
  
  if (result.success) {
    // Verify container is running
    const verifyCmd = `docker ps --filter "name=${containerName}" --format "table {{.Names}}\t{{.Status}}\t{{.Networks}}"`;
    const verify = runCommand(verifyCmd);
    console.log(`📌 Container "${containerName}" verification:\n${verify.output}`);
  }
  
  res.json({
    action: 'Create Container',
    container: containerName,
    network: networkName,
    success: result.success,
    message: result.success ? `✅ Container "${containerName}" created and running!` : `❌ Failed to create container`,
    details: result.output,
    containerId: result.success ? result.output.substring(0, 12) : null
  });
});

// Delete Container
app.post('/api/delete-container', (req, res) => {
  const { containerName } = req.body;
  console.log(`🗑️ Deleting container: ${containerName}...`);
  
  const result = runCommand(`docker rm -f ${containerName}`);
  res.json({
    action: 'Delete Container',
    container: containerName,
    success: result.success,
    message: result.success ? `✅ Container "${containerName}" deleted!` : `❌ Failed to delete container`,
    details: result.output
  });
});

// List Containers
app.get('/api/containers', (req, res) => {
  console.log('📋 Listing containers...');
  const result = runCommand('docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Networks}}"');
  res.json({
    action: 'List Containers',
    success: result.success,
    details: result.output
  });
});

// ===== NETWORK CONNECTION OPERATIONS =====

// Connect Container to Network
app.post('/api/connect-network', (req, res) => {
  const { containerName, networkName } = req.body;
  console.log(`🔗 Connecting ${containerName} to ${networkName}...`);
  
  const result = runCommand(`docker network connect ${networkName} ${containerName}`);
  res.json({
    action: 'Connect to Network',
    container: containerName,
    network: networkName,
    success: result.success,
    message: result.success ? `✅ Connected "${containerName}" to "${networkName}"!` : `❌ Failed to connect`,
    details: result.output
  });
});

// ===== COMMUNICATION TESTS =====

// Test Ping (Communication)
app.post('/api/test-ping', (req, res) => {
  const { sourceContainer, targetContainer } = req.body;
  console.log(`🔍 Testing ping from ${sourceContainer} to ${targetContainer}...`);
  
  const command = `docker exec ${sourceContainer} ping -c 2 ${targetContainer} 2>&1`;
  const result = runCommand(command);
  
  res.json({
    action: 'Test Ping',
    source: sourceContainer,
    target: targetContainer,
    success: result.success,
    message: result.success ? `✅ Ping successful - Containers can communicate!` : `❌ Ping failed - Containers isolated`,
    details: result.output
  });
});

// Test DNS Resolution
app.post('/api/test-dns', (req, res) => {
  const { sourceContainer, targetContainer } = req.body;
  console.log(`🔍 Testing DNS resolution from ${sourceContainer} to ${targetContainer}...`);
  
  const command = `docker exec ${sourceContainer} nslookup ${targetContainer} 2>&1`;
  const result = runCommand(command);
  
  res.json({
    action: 'Test DNS',
    source: sourceContainer,
    target: targetContainer,
    success: result.success,
    message: result.success ? `✅ DNS resolution successful!` : `❌ DNS resolution failed`,
    details: result.output
  });
});

// ===== CLEAN UP =====

// Cleanup All
app.post('/api/cleanup-all', (req, res) => {
  console.log('🧹 Cleaning up all containers and networks...');
  
  const containers = ['container1', 'container2'];
  const networks = ['network1', 'network2'];
  
  let output = '';
  let success = true;
  
  // Remove specific containers
  for (const container of containers) {
    console.log(`🗑️ Removing container: ${container}...`);
    const result = runCommand(`docker rm -f ${container}`);
    output += `Container ${container}: ${result.success ? '✅ Removed' : '⚠️ Not found'}\n`;
  }
  
  // Remove specific networks
  for (const network of networks) {
    console.log(`🗑️ Removing network: ${network}...`);
    const result = runCommand(`docker network rm ${network}`);
    output += `Network ${network}: ${result.success ? '✅ Removed' : '⚠️ Not found'}\n`;
  }
  
  // Also run prune to clean up any remaining unused resources
  console.log('🧹 Pruning unused resources...');
  const pruneContainers = runCommand('docker container prune -f');
  const pruneNetworks = runCommand('docker network prune -f');
  output += `\nPrune containers: ${pruneContainers.success ? '✅ Done' : '⚠️ Done'}\n`;
  output += `Prune networks: ${pruneNetworks.success ? '✅ Done' : '⚠️ Done'}\n`;
  
  res.json({
    action: 'Cleanup All',
    success: true,
    message: `✅ Cleanup completed! All containers and networks removed.`,
    details: output
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`\n🌐 Server running at http://localhost:${PORT}`);
  console.log(`📚 Docker Networking Lab ready!\n`);
});
