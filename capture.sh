#!/bin/bash

CONFIG_FILE="./config.conf"
PID_FILE="./capture.pid"
FIFO_PATH="./live_capture.pcap"

check_ssh_access() {
    if ssh -o BatchMode=yes "$REMOTE_USER@$REMOTE_HOST" 'echo 2>&1' && [[ $? -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

setup_ssh_key() {
    USE_SSHPASS=true
}

start_capture() {
    source "$CONFIG_FILE"
    mkdir -p "$(dirname "$LOCAL_PCAP_PATH")"

    if [[ -f "$PID_FILE" ]]; then
        echo "⚠️ Capture already running with PID $(cat $PID_FILE)"
        exit 1
    fi

    # Create FIFO if it doesn't exist
    if [[ ! -p "$FIFO_PATH" ]]; then
        echo "🌀 Creating FIFO at $FIFO_PATH"
        mkfifo "$FIFO_PATH"
    fi

    setup_ssh_key

    echo "🚀 Starting capture on $REMOTE_HOST ($INTERFACE)..."

    if [[ "$USE_SSHPASS" == true ]]; then
        if [[ -z "$SSH_PASSWORD" ]]; then
            echo "Enter SSH password for $REMOTE_USER@$REMOTE_HOST:"
            read -rs SSH_PASSWORD
        fi
        sshpass -p "$SSH_PASSWORD" ssh "$REMOTE_USER@$REMOTE_HOST" \
            "sudo tcpdump -i $INTERFACE -w - -U" > >(tee "$LOCAL_PCAP_PATH" > "$FIFO_PATH") 2>/dev/null &
    else
        ssh "$REMOTE_USER@$REMOTE_HOST" \
            "sudo tcpdump -i $INTERFACE -w - -U" > >(tee "$LOCAL_PCAP_PATH" > "$FIFO_PATH") 2>/dev/null &
    fi

    PID=$!
    echo "$PID" > "$PID_FILE"
    echo "✅ Capture started (PID $PID)"
    echo "📦 Output file: $LOCAL_PCAP_PATH"
    echo "👁️  Live stream: $FIFO_PATH (use with: tshark -r $FIFO_PATH)"
}

stop_capture() {
    if [[ -f "$PID_FILE" ]]; then
        PID=$(cat "$PID_FILE")
        echo "🛑 Stopping capture (PID $PID)..."
        kill -2 "$PID"  # SIGINT, so tcpdump closes cleanly
        wait "$PID"
        rm "$PID_FILE"
        echo "✅ Capture stopped."
    else
        echo "❌ No capture is currently running."
    fi
}

case "$1" in
    start)
        start_capture
        ;;
    stop)
        stop_capture
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        ;;
esac
