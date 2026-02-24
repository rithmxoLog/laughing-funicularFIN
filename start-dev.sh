#!/bin/bash

# =============================================================================
# RithmXO Template - Start Everything (Development)
# Starts Docker, Backend, and Frontend in one command.
# Auto-creates Docker containers and installs dependencies if missing.
#
# Usage: double-click start-dev.bat  (or run: bash start-dev.sh)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_PID=""
FRONTEND_PID=""

# On any error, show what failed and pause so the user can read it
die() {
    echo ""
    echo "=========================================="
    echo " ERROR: $1"
    echo "=========================================="
    echo ""
    echo "Press Enter to exit..."
    read -r
    exit 1
}

cleanup() {
    echo ""
    echo "[shutdown] Stopping all services..."
    [ -n "$BACKEND_PID" ]  && kill "$BACKEND_PID"  2>/dev/null || true
    [ -n "$FRONTEND_PID" ] && kill "$FRONTEND_PID" 2>/dev/null || true
    [ -n "$BACKEND_PID" ]  && wait "$BACKEND_PID"  2>/dev/null || true
    [ -n "$FRONTEND_PID" ] && wait "$FRONTEND_PID" 2>/dev/null || true
    echo "[shutdown] All services stopped."
}
trap cleanup EXIT INT TERM

echo "=========================================="
echo " RithmXO Template - Development Startup"
echo "=========================================="
echo ""

# =============================================================================
# 0. Kill anything on our ports (3000, 5000)
# =============================================================================
echo "[0/4] Clearing ports 3000, 5000..."

for PORT in 3000 5000; do
    PIDS=$(netstat -ano 2>/dev/null | grep ":${PORT} " | grep LISTENING | awk '{print $5}' | sort -u)
    for PID in $PIDS; do
        if [ -n "$PID" ] && [ "$PID" != "0" ]; then
            echo "       Killing PID $PID on port $PORT"
            taskkill //F //PID "$PID" 2>/dev/null || true
        fi
    done
done

# Kill any lingering dotnet/RithmTemplateApi processes
taskkill //F //IM dotnet.exe 2>/dev/null || true
taskkill //F //IM RithmTemplateApi.exe 2>/dev/null || true

sleep 1
echo "[0/4] Ports cleared."

# =============================================================================
# 1. Docker Containers (auto-create if missing)
# =============================================================================
echo ""
echo "[1/4] Starting Docker containers..."

# Check Docker is running
if ! docker info > /dev/null 2>&1; then
    die "Docker is not running. Please start Docker Desktop and try again."
fi

# PostgreSQL — create if missing, start if stopped
if ! docker ps -a --format '{{.Names}}' | grep -q '^rithm-postgres$'; then
    echo "       Creating rithm-postgres container..."
    docker run -d \
        --name rithm-postgres \
        -p 5432:5432 \
        -e POSTGRES_USER=sa \
        -e POSTGRES_PASSWORD=Adminroot01 \
        -e POSTGRES_DB=rithmtemplate_db \
        postgres:16
elif ! docker ps --format '{{.Names}}' | grep -q '^rithm-postgres$'; then
    docker start rithm-postgres
fi

# Valkey — create if missing, start if stopped
if ! docker ps -a --format '{{.Names}}' | grep -q '^valkey$'; then
    echo "       Creating valkey container..."
    docker run -d \
        --name valkey \
        -p 6379:6379 \
        valkey/valkey:latest
elif ! docker ps --format '{{.Names}}' | grep -q '^valkey$'; then
    docker start valkey
fi

# Wait for PostgreSQL to accept connections
echo "[1/4] Waiting for PostgreSQL..."
for i in $(seq 1 20); do
    if docker exec rithm-postgres pg_isready -U sa -q 2>/dev/null; then
        echo "[1/4] Docker containers ready."
        break
    fi
    if [ "$i" -eq 20 ]; then
        die "PostgreSQL not ready after 20s. Check: docker logs rithm-postgres"
    fi
    sleep 1
done

# =============================================================================
# 2. Install Dependencies (if needed)
# =============================================================================
echo ""
echo "[2/4] Checking dependencies..."

# Backend: dotnet restore
echo "       Restoring .NET packages..."
dotnet restore "${SCRIPT_DIR}/backend/RithmTemplate.sln" --verbosity quiet || die "dotnet restore failed. Is .NET 9 SDK installed? (dotnet --version)"

# Frontend: npm install (only if node_modules missing or package-lock changed)
if [ ! -d "${SCRIPT_DIR}/frontend/node_modules" ]; then
    echo "       Installing frontend dependencies (npm install)..."
    cd "${SCRIPT_DIR}/frontend"
    npm install || die "npm install failed. Is Node.js installed? (node --version)"
    cd "${SCRIPT_DIR}"
else
    echo "       Frontend node_modules found — skipping npm install."
fi

echo "[2/4] Dependencies ready."

# =============================================================================
# 3. Backend (.NET)
# =============================================================================
echo ""
echo "[3/4] Starting Backend (.NET) on port 5000..."

cd "${SCRIPT_DIR}/backend/src/RithmTemplateApi"
ASPNETCORE_ENVIRONMENT=Development dotnet run --no-launch-profile &
BACKEND_PID=$!
cd "${SCRIPT_DIR}"

# Wait for backend health check
echo "[3/4] Waiting for backend..."
for i in $(seq 1 45); do
    if curl -s -o /dev/null -w "" http://localhost:5000/health 2>/dev/null; then
        echo "[3/4] Backend ready at http://localhost:5000"
        echo "       Swagger: http://localhost:5000/swagger"
        break
    fi
    if [ "$i" -eq 45 ]; then
        echo "[warn] Backend not responding after 45s (may still be starting)"
    fi
    sleep 1
done

# =============================================================================
# 4. Frontend (Next.js)
# =============================================================================
echo ""
echo "[4/4] Starting Frontend (Next.js) on port 3000..."

cd "${SCRIPT_DIR}/frontend"
npm run dev &
FRONTEND_PID=$!
cd "${SCRIPT_DIR}"

sleep 3

echo ""
echo "=========================================="
echo " All Services Running"
echo "=========================================="
echo ""
echo "  Frontend: http://localhost:3000"
echo "  Backend:  http://localhost:5000"
echo "  Swagger:  http://localhost:5000/swagger"
echo ""
echo "  Press Ctrl+C to stop everything"
echo "=========================================="
echo ""

# Keep script alive until Ctrl+C
wait
