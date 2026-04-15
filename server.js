// Simple Express server to control Docker networking
const express = require('express');
const { execSync } = require('child_process');
const path = require('path');

const app = express();
const PORT = 3000;

// Middleware
app.use(express.static(path.join(__dirname, 'public')));
app.use(express.json());

// Logging helper
function log(message) {
  console.log(`[${new Date().toLocaleTimeString()}] ${message}`);
}

// Helper function to run Docker commands
function runCommand(command) {
  try {
    log(`Executing: ${command}`);
    const output = execSync(command, { 
      encoding: 'utf-8',
      shell: true,
      stdio: ['pipe', 'pipe', 'pipe']
    });
    log(`✅ Success`);
    return { success: true, output: output.trim() };
  } catch (error) {
    const errorMsg = error.stderr ? error.stderr.toString() : error.message;
    log(`❌ Error: ${errorMsg}`);
    return { success: false, output: errorMsg };
  }
}

// API Endpoint: Create Networks
app.post('/api/create-networks', (req, res) => {
  log('Creating networks...');
  
  const result1 = runCommand('docker network create network1');
  const result2 = runCommand('docker network create network2');
  
  const success = result1.success && result2.success;
  res.json({
    step: 'Create Networks',
    success: success,
    message: success ? '✅ Networks created successfully!' : '❌ Failed to create networks',
    details: [result1, result2]
  });
});

// API Endpoint: Start Containers
app.post('/api/start-containers', (req, res) => {
  log('Starting containers...');
  
  const result1 = runCommand('docker run -dit --name c1 --network network1 nginx:latest');
  const result2 = runCommand('docker run -dit --name c2 --network network2 nginx:latest');
  
  const success = result1.success && result2.success;
  res.json({
    step: 'Start Containers',
    success: success,
    message: success ? '✅ Containers started successfully!' : '❌ Failed to start containers',
    details: [result1, result2]
  });
});

// API Endpoint: Test Isolation (before connection - should fail)
app.post('/api/test-isolation', (req, res) => {
  log('Testing network isolation...');
  
  // Only use curl to test isolation (should fail)
  const curlResult = runCommand('docker exec c1 curl -s -m 2 http://c2');
  
  // Isolation is working if curl failed (cannot reach each other)
  const isolated = !curlResult.success;
  
  res.json({
    step: 'Test Isolation (Before Connection)',
    success: isolated,
    message: isolated 
      ? '✅ SUCCESS: Networks are properly isolated (curl blocked)' 
      : '❌ FAILED: Networks are not isolated (curl succeeded)',
    details: {
      test: { attempted: 'curl c1 to http://c2', result: !curlResult.success ? '❌ BLOCKED (Isolated)' : '✅ REACHED (Not Isolated)' }
    }
  });
});

// API Endpoint: Connect Networks
app.post('/api/connect-networks', (req, res) => {
  log('Connecting networks...');
  
  // Connect container c1 to network2
  const result = runCommand('docker network connect network2 c1');
  
  res.json({
    step: 'Connect Networks',
    success: result.success,
    message: result.success 
      ? '✅ Container c1 successfully connected to network2!' 
      : '❌ Failed to connect networks',
    details: [result]
  });
});

// API Endpoint: Test Communication (after connection - should succeed)
app.post('/api/test-communication', (req, res) => {
  log('Testing communication after connection...');
  
  // Only use curl to test communication (should succeed now)
  const curlResult = runCommand('docker exec c1 curl -s -m 2 http://c2');
  
  // Communication working if curl succeeded
  const communicating = curlResult.success;
  
  res.json({
    step: 'Test Communication (After Connection)',
    success: communicating,
    message: communicating 
      ? '✅ SUCCESS: Containers can now communicate (curl succeeded)!' 
      : '❌ FAILED: Containers still cannot communicate (curl blocked)',
    details: {
      test: { attempted: 'curl c1 to http://c2', result: curlResult.success ? '✅ REACHED (Success)' : '❌ BLOCKED (Failed)' }
    }
  });
});

// API Endpoint: Cleanup
app.post('/api/cleanup', (req, res) => {
  log('Cleaning up containers and networks...');
  
  // Stop and remove containers
  runCommand('docker stop c1 c2 2>nul || echo "Containers not running"');
  runCommand('docker rm c1 c2 2>nul || echo "Containers not found"');
  
  // Remove networks
  runCommand('docker network rm network1 2>nul || echo "network1 not found"');
  runCommand('docker network rm network2 2>nul || echo "network2 not found"');
  
  res.json({
    step: 'Cleanup',
    success: true,
    message: '✅ Cleanup completed successfully!',
    details: 'All containers and networks have been removed'
  });
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Server is running' });
});

// Start server
app.listen(PORT, () => {
  console.log('\n╔════════════════════════════════════════════╗');
  console.log('║  Docker Networking Web Controller          ║');
  console.log('╠════════════════════════════════════════════╣');
  console.log(`║  🚀 Server running at:                     ║`);
  console.log(`║     http://localhost:${PORT}                       ║`);
  console.log('║                                            ║');
  console.log('║  ⚠️  Make sure Docker is installed and:      ║');
  console.log('║     - Docker Desktop is running             ║');
  console.log('║     - Docker daemon is active               ║');
  console.log('╚════════════════════════════════════════════╝\n');
});
