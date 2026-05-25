#!/bin/bash
# Bremspace Startup Script
# Jalankan ini untuk start semua service Bremspace di Termux
# Usage: bash ~/.hermes/scripts/bremspace-startup.sh

LOG="/tmp/bremspace-startup.log"
echo "========================================" >> "$LOG"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Bremspace..." >> "$LOG"

# 1. Pastikan PM2 running
if ! pm2 list > /dev/null 2>&1; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting PM2..." >> "$LOG"
    pm2 update
fi

# 2. Start Hermes Agent (brem-ceo) via PM2
if ! pm2 describe brem-ceo > /dev/null 2>&1; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting brem-ceo..." >> "$LOG"
    pm2 start "hermes" --name brem-ceo --interpreter python3 2>> "$LOG"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] brem-ceo already registered in PM2" >> "$LOG"
fi

# 3. Start Hermes Dashboard via PM2
if ! pm2 describe brem-dashboard > /dev/null 2>&1; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting brem-dashboard..." >> "$LOG"
    pm2 start "hermes dashboard" --name brem-dashboard 2>> "$LOG"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] brem-dashboard already registered in PM2" >> "$LOG"
fi

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
    nohup 9router > /tmp/9router.log 2>&1 &
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
