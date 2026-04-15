// Docker Networking Controller - Frontend JavaScript

// ============ Configuration ============
const API_BASE = 'http://localhost:3000/api';
const OUTPUT_BOX = document.getElementById('output');
const SERVER_STATUS = document.getElementById('serverStatus');

// ============ Utility Functions ============

/**
 * Clear all output
 */
function clearOutput() {
    OUTPUT_BOX.innerHTML = '';
}

/**
 * Display output in the output box
 * @param {Object} response - API response object
 */
function displayOutput(response) {
    const entry = document.createElement('div');
    entry.className = `output-entry ${response.success ? 'success' : 'error'}`;

    // Title (Step name)
    const title = document.createElement('div');
    title.className = 'output-title';
    title.textContent = response.step;
    entry.appendChild(title);

    // Main message
    const message = document.createElement('div');
    message.className = 'output-message';
    message.textContent = response.message;
    entry.appendChild(message);

    // Details section
    if (response.details) {
        const details = document.createElement('div');
        details.className = 'output-details';

        if (Array.isArray(response.details)) {
            response.details.forEach((detail, index) => {
                const item = document.createElement('div');
                item.className = 'detail-item';
                item.innerHTML = `
                    <strong>Command ${index + 1}:</strong> 
                    ${detail.success ? '✅' : '❌'} 
                    ${detail.output.substring(0, 100)}${detail.output.length > 100 ? '...' : ''}
                `;
                details.appendChild(item);
            });
        } else if (typeof response.details === 'object') {
            // For test results with ping/curl info
            Object.entries(response.details).forEach(([key, value]) => {
                const item = document.createElement('div');
                item.className = 'detail-item';
                if (typeof value === 'object') {
                    item.innerHTML = `
                        <strong>${key.toUpperCase()}:</strong><br>
                        &nbsp;&nbsp;Attempted: ${value.attempted}<br>
                        &nbsp;&nbsp;Result: ${value.result}
                    `;
                } else {
                    item.textContent = `${key}: ${value}`;
                }
                details.appendChild(item);
            });
        } else {
            const item = document.createElement('div');
            item.className = 'detail-item';
            item.textContent = response.details;
            details.appendChild(item);
        }

        entry.appendChild(details);
    }

    // Scroll to bottom
    OUTPUT_BOX.appendChild(entry);
    OUTPUT_BOX.scrollTop = OUTPUT_BOX.scrollHeight;
}

/**
 * Make API call and handle response
 * @param {string} endpoint - API endpoint
 * @param {string} buttonText - Button text for feedback
 */
async function callAPI(endpoint, buttonText) {
    try {
        // Disable interactions
        disableAllButtons();

        // Show loading state
        addLoadingMessage(buttonText);

        // Make API call
        const response = await fetch(`${API_BASE}${endpoint}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            }
        });

        if (!response.ok) {
            throw new Error(`HTTP Error: ${response.status}`);
        }

        const data = await response.json();
        displayOutput(data);

    } catch (error) {
        console.error('API Error:', error);
        const errorEntry = document.createElement('div');
        errorEntry.className = 'output-entry error';
        errorEntry.innerHTML = `
            <div class="output-title">❌ Error</div>
            <div class="output-message">${error.message}</div>
            <div class="output-details">
                <strong>Troubleshooting:</strong><br>
                ✓ Make sure Docker Desktop is running<br>
                ✓ Check that the server is connected properly<br>
                ✓ Verify Docker is installed and available
            </div>
        `;
        OUTPUT_BOX.appendChild(errorEntry);
    } finally {
        // Re-enable buttons
        enableAllButtons();
    }
}

/**
 * Add loading message
 */
function addLoadingMessage(text) {
    const entry = document.createElement('div');
    entry.className = 'output-entry info';
    entry.innerHTML = `
        <div class="output-title">⏳ Executing: ${text}</div>
        <div class="output-message">Running Docker commands...</div>
    `;
    OUTPUT_BOX.appendChild(entry);
    OUTPUT_BOX.scrollTop = OUTPUT_BOX.scrollHeight;
}

/**
 * Disable all buttons
 */
function disableAllButtons() {
    document.querySelectorAll('.btn').forEach(btn => btn.disabled = true);
}

/**
 * Enable all buttons
 */
function enableAllButtons() {
    document.querySelectorAll('.btn').forEach(btn => btn.disabled = false);
}

/**
 * Check server health
 */
async function checkServerHealth() {
    try {
        const response = await fetch(`${API_BASE}/health`);
        if (response.ok) {
            SERVER_STATUS.className = 'status-badge online';
            SERVER_STATUS.textContent = '🟢 Online';
        } else {
            SERVER_STATUS.className = 'status-badge offline';
            SERVER_STATUS.textContent = '🔴 Offline';
        }
    } catch {
        SERVER_STATUS.className = 'status-badge offline';
        SERVER_STATUS.textContent = '🔴 Offline';
    }
}

// ============ API Functions ============

/**
 * Step 1a: Create Network1
 */
function createNetwork1() {
    callAPI('/create-network1', 'Creating Network1');
}

/**
 * Step 1b: Create Network2
 */
function createNetwork2() {
    callAPI('/create-network2', 'Creating Network2');
}

/**
 * Step 2: Start Containers
 */
function startContainers() {
    callAPI('/start-containers', 'Starting Containers');
}

/**
 * Step 3: Test Isolation (Before Connection)
 */
function testIsolation() {
    callAPI('/test-isolation', 'Testing Isolation');
}

/**
 * Step 4: Connect Networks
 */
function connectNetworks() {
    callAPI('/connect-networks', 'Connecting Networks');
}

/**
 * Step 5: Test Communication (After Connection)
 */
function testCommunication() {
    callAPI('/test-communication', 'Testing Communication');
}

/**
 * Cleanup: Remove all containers and networks
 */
function cleanup() {
    if (confirm('⚠️ Are you sure you want to cleanup all containers and networks?')) {
        callAPI('/cleanup', 'Cleanup');
    }
}

// ============ Initialization ============

/**
 * Initialize the page
 */
document.addEventListener('DOMContentLoaded', () => {
    console.log('🚀 Docker Networking Controller loaded');
    clearOutput();
    checkServerHealth();

    // Check server health every 5 seconds
    setInterval(checkServerHealth, 5000);
});
