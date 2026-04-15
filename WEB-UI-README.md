# Docker Networking Web Controller

A simple web UI to control and demonstrate Docker networking with isolated containers.

## 📋 Quick Start

### Prerequisites
- **Node.js** installed (v14 or higher)
- **Docker Desktop** running
- Windows 10/11 or Linux/Mac with Docker support

### Installation & Run

```bash
# Navigate to the project directory
cd docker-networking

# Install dependencies
npm install

# Start the server
npm start
```

The server will start at: **http://localhost:3000**

## 🎯 How to Use

1. **Open your browser** → `http://localhost:3000`
2. **Click buttons in order:**
   - ✅ Click "Create Networks" - Creates network1 and network2
   - ✅ Click "Start Containers" - Starts c1 in network1, c2 in network2
   - ⚠️ Click "Test Isolation (Before)" - Should show ❌ (cannot communicate)
   - 🔗 Click "Connect Networks" - Connects c1 to network2
   - ✅ Click "Test Communication (After)" - Should show ✅ (can communicate)
   - 🗑️ Click "Cleanup All" when done

## 📁 File Structure

```
docker-networking/
├── package.json              # Node.js dependencies
├── server.js                 # Express backend (API endpoints)
├── public/
│   ├── index.html           # Web UI (HTML)
│   ├── style.css            # Styling (CSS)
│   └── script.js            # Frontend logic (JavaScript)
├── docker-compose.yml       # (Existing Docker config)
├── scripts/                 # (Existing setup scripts)
└── *.html                   # (Existing HTML files)
```

## 🚀 API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/create-networks` | POST | Create network1 and network2 |
| `/api/start-containers` | POST | Start c1 and c2 containers |
| `/api/test-isolation` | POST | Test if containers are isolated |
| `/api/connect-networks` | POST | Connect c1 to network2 |
| `/api/test-communication` | POST | Test if containers can communicate |
| `/api/cleanup` | POST | Remove all containers and networks |
| `/api/health` | GET | Server health check |

## 🎨 Frontend Features

- **Beautiful UI** - Modern, responsive design
- **Real-time Feedback** - Instant command results
- **Color-coded Output** - Green for success, red for errors
- **Step-by-step Workflow** - Follow numbered buttons
- **Server Status** - Live connectivity indicator
- **Mobile Friendly** - Works on phones and tablets

## 🔧 How It Works

### Backend (Node.js + Express)
- Receives button clicks from frontend
- Executes Docker commands using `child_process.execSync()`
- Sends results back as JSON

### Frontend (HTML + CSS + JavaScript)
- Beautiful web interface
- Makes API calls when buttons are clicked
- Displays output in real-time

### Docker Commands
```bash
# Create networks
docker network create network1
docker network create network2

# Start containers
docker run -dit --name c1 --network network1 nginx:latest
docker run -dit --name c2 --network network2 nginx:latest

# Test isolation (should fail)
docker exec c1 ping -c 1 c2

# Connect networks
docker network connect network2 c1

# Test communication (should succeed)
docker exec c1 ping -c 1 c2
```

## ⚠️ Troubleshooting

### "Connection refused" error?
- Make sure Docker Desktop is running
- Check if port 3000 is available
- Try: `netstat -ano | findstr :3000` (Windows PowerShell)

### "Docker command not found"?
- Ensure Docker is installed
- Add Docker to your system PATH
- Restart your terminal/PowerShell

### Containers won't start?
- Check if containers c1, c2 already exist
- Click "Cleanup All" first to remove old containers

### Server won't start?
```bash
# Kill process on port 3000 (Windows PowerShell)
Get-Process -Id (Get-NetTCPConnection -LocalPort 3000).OwningProcess | Stop-Process

# Try again
npm start
```

## 📚 Educational Output

The web UI shows:
- ✅ **Success**: When operations complete correctly
- ❌ **Failure**: When operations fail or cannot communicate
- ℹ️ **Information**: Helpful messages and next steps
- 📊 **Details**: Command outputs and results

## 🎓 Learning Outcomes

After using this controller, you'll understand:
- How to create Docker networks
- How Docker networking isolates containers
- How to enable communication between isolated containers
- Bridge networks and network drivers
- Container connectivity and DNS resolution

## 🛑 Stop the Server

Press `Ctrl+C` in your terminal to stop the server.

## 📝 Notes

- The web UI doesn't modify existing files/containers
- All containers and networks are created fresh each time
- Safe to run multiple times - cleanup between runs
- No data is persisted between sessions

## ✨ Features Highlights

✓ **Simple & Intuitive** - One-click Docker commands  
✓ **Visual Feedback** - Clear success/failure indicators  
✓ **Full Workflow** - Complete demonstration included  
✓ **Error Handling** - Graceful error messages  
✓ **Responsive Design** - Works on all screen sizes  
✓ **Cross-platform** - Windows, Linux, Mac support  
✓ **Educational** - Learn Docker networking visually  

---

**Happy dockering! 🐳**
