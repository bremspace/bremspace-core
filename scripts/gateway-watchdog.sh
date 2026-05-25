#!/bin/bash
# Gateway Watchdog Script v2
# Cek setiap 30 detik apakah hermes gateway run jalan
# Kalau mati, auto-restart

LOG="/tmp/gateway-watchdog.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Watchdog v2 started (PID $$)" >> "$LOG"

while true; do
    # Cek gateway process (pattern lebih spesifik)
    GATEWAY_PID=$(pgrep -f "hermes gateway run" 2>/dev/null | head -1)
    
    if [ -z "$GATEWAY_PID" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Gateway DOWN. Starting..." >> "$LOG"
        nohup hermes gateway run >> /tmp/gateway-stdout.log 2>&1 &
        NEW_PID=$!
        sleep 5
        
        # Verifikasi udah jalan
        CHECK_PID=$(pgrep -f "hermes gateway run" 2>/dev/null | head -1)
        if [ -n "$CHECK_PID" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Gateway UP (PID $CHECK_PID)" >> "$LOG"
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] FAILED to start!" >> "$LOG"
        fi
    fi
    
    sleep 30
done
