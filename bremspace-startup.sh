#!/bin/bash
# ============================================================
# Bremspace Sequential Startup Script v3
# Tanpa tmux — semua jalan di satu window
# Alur: 9Router → hermes dashboard → hermes gateway run
# ============================================================

LOG="$HOME/.hermes/logs/bremspace-startup.log"
mkdir -p "$HOME/.hermes/logs"

log() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG"
}

echo ""
echo "========================================" | tee -a "$LOG"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] BREMSPACE STARTUP v3" | tee -a "$LOG"
echo "========================================" | tee -a "$LOG"
echo ""

# --------------------------------------------------
# STEP 1: 9Router
# --------------------------------------------------
log "[1/3] Starting 9Router..."
if pgrep -f "9router" > /dev/null 2>&1; then
    log "[1/3] SKIP — 9Router already running (PID: $(pgrep -f '9router' | head -1))"
else
    if command -v 9router &> /dev/null; then
        nohup 9router > "$HOME/.hermes/logs/9router.log" 2>&1 &
        sleep 3
        if pgrep -f "9router" > /dev/null 2>&1; then
            log "[1/3] OK — 9Router started (PID: $(pgrep -f '9router' | head -1))"
            echo ">>> 9Router GUI loaded? Click 'Hide to Tray' now."
        else
            log "[1/3] WARN — 9Router may not have started, check $HOME/.hermes/logs/9router.log"
        fi
    else
        log "[1/3] SKIP — 9router not found in PATH"
    fi
fi

# --------------------------------------------------
# STEP 2: hermes dashboard (PM2 — brem-dashboard)
# --------------------------------------------------
log "[2/3] Starting hermes dashboard..."
if pm2 list 2>/dev/null | grep -q "brem-dashboard.*online"; then
    log "[2/3] SKIP — brem-dashboard already online"
else
    # Try PM2 restart first, then start
    pm2 restart brem-dashboard 2>/dev/null || pm2 start "hermes dashboard" --name brem-dashboard 2>/dev/null
    sleep 3
    if pm2 list 2>/dev/null | grep -q "brem-dashboard.*online"; then
        log "[2/3] OK — brem-dashboard online"
    else
        log "[2/3] WARN — brem-dashboard status unknown, check 'pm2 list'"
    fi
fi

# --------------------------------------------------
# STEP 3: hermes gateway run
# --------------------------------------------------
log "[3/3] Starting hermes gateway..."
if pgrep -f "hermes gateway" > /dev/null 2>&1; then
    log "[3/3] SKIP — gateway already running (PID: $(pgrep -f 'hermes gateway' | head -1))"
else
    nohup hermes gateway run --verbose > "$HOME/.hermes/logs/gateway.log" 2>&1 &
    sleep 5
    if pgrep -f "hermes gateway" > /dev/null 2>&1; then
        log "[3/3] OK — gateway started (PID: $(pgrep -f 'hermes gateway' | head -1))"
    else
        log "[3/3] WARN — gateway may not have started, check $HOME/.hermes/logs/gateway.log"
    fi
fi

# --------------------------------------------------
# FINAL: Summary
# --------------------------------------------------
sleep 2
echo ""
echo "========================================" | tee -a "$LOG"
log "STARTUP COMPLETE"
echo "========================================" | tee -a "$LOG"
echo ""

# Status overview
echo "--- Service Status ---"
echo ""
echo "9Router:"
if pgrep -f "9router" > /dev/null 2>&1; then
    echo "  RUNNING (PID: $(pgrep -f '9router' | head -1))"
else
    echo "  NOT RUNNING"
fi

echo ""
echo "PM2 Services:"
pm2 list 2>/dev/null | grep -E "brem-" || echo "  (none found)"

echo ""
echo "Gateway:"
if pgrep -f "hermes gateway" > /dev/null 2>&1; then
    echo "  RUNNING (PID: $(pgrep -f 'hermes gateway' | head -1))"
else
    echo "  NOT RUNNING"
fi

echo ""
echo "Logs: $HOME/.hermes/logs/"
echo "  9router.log  |  gateway.log  |  bremspace-startup.log"
echo ""
