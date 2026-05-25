#!/bin/bash
# Bremspace Startup Script
# Jalankan ini untuk start semua service Bremspace di Termux
# Usage: bash ~/.hermes/scripts/bremspace-startup.sh

LOG="$HOME/.hermes/logs/bremspace-startup.log"
echo "========================================" >> "$LOG"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Bremspace..." >> "$LOG"

# 1. Pastikan PM2 running
if ! pm2 list > /dev/null 2>&1; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting PM2..." >> "$LOG"
    pm2 update
fi

# 2. Skip brem-ceo startup — agent udah jalan (ini process yang lagi kepake)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] brem-ceo already running (current agent session)" >> "$LOG"

# 3. Skip dashboard — usually runs in background already
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Dashboard check skipped (runs on-demand)" >> "$LOG"

# 4. Start Gateway Watchdog (auto-restart gateway)
if ! pgrep -f "gateway-watchdog" > /dev/null 2>&1; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting gateway watchdog..." >> "$LOG"
    nohup bash ~/.hermes/scripts/gateway-watchdog.sh > /dev/null 2>&1 &
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Watchdog started (PID $!)" >> "$LOG"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Watchdog already running" >> "$LOG"
fi

# 5. Start 9Router (manual, gak bisa PM2)
if ! pgrep -f "9router" > /dev/null 2>&1; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting 9router..." >> "$LOG"
    nohup 9router > "$HOME/.hermes/logs/9router.log" 2>&1 &
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 9router started (PID $!)" >> "$LOG"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 9router already running" >> "$LOG"
fi

sleep 3

echo "" >> "$LOG"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] === STATUS ===" >> "$LOG"
echo "--- PM2 ---" >> "$LOG"
pm2 list >> "$LOG" 2>&1
echo "--- Processes ---" >> "$LOG"
ps aux | grep -iE "hermes|gateway|watchdog|9router|dashboard" | grep -v grep >> "$LOG" 2>&1
echo "========================================" >> "$LOG"

echo ""
echo "Bremspace started! Check: cat $LOG"
