#!/bin/bash

CONFIG_FILE="./config.conf"
PID_FILE="./capture.pid"

check_ssh_access() {
    if ssh -o BatchMode=yes "$REMOTE_USER@$REMOTE_HOST" 'echo 2>&1' && [[ $? -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

setup_ssh_key() {
    if [[ ! -f "$HOME/.ssh/id_rsa" ]]; then
        echo "No SSH key found. Do you want to generate one? (y/n)"
        read -r answer
        if [[ "$answer" == "y" ]]; then
            ssh-keygen -t rsa -b 4096 -N "" -f "$HOME/.ssh/id_rsa"
        else
            echo "You chose not to generate an SSH key. Password will be required for each connection."
            USE_SSHPASS=true
        fi
    fi

    if ! check_ssh_access; then
        echo "SSH access is not yet configured. Do you want to copy your public key to the remote machine? (y/n)"
        read -r copy_answer
        if [[ "$copy_answer" == "y" ]]; then
            ssh-copy-id "$REMOTE_USER@$REMOTE_HOST"
        else
            echo "You chose not to copy the key. Password will be required for each connection."
            USE_SSHPASS=true
        fi
    fi
}

start_capture() {
    source "$CONFIG_FILE"
    mkdir -p "$(dirname "$LOCAL_PCAP_PATH")"

    if [[ -f "$PID_FILE" ]]; then
        echo "⚠️ Capture already running with PID $(cat $PID_FILE)"
        exit 1
    fi

    setup_ssh_key

    echo "🚀 Starting capture on $REMOTE_HOST ($INTERFACE)..."

    if [[ "$USE_SSHPASS" == true ]]; then
        if [[ -z "$SSH_PASSWORD" ]]; then
            echo "Enter SSH password for $REMOTE_USER@$REMOTE_HOST:"
            read -rs SSH_PASSWORD
        fi
        sshpass -p "$SSH_PASSWORD" ssh "$REMOTE_USER@$REMOTE_HOST" "sudo tcpdump -i $INTERFACE -w - -U" > "$LOCAL_PCAP_PATH" &
    else
        ssh "$REMOTE_USER@$REMOTE_HOST" "sudo tcpdump -i $INTERFACE -w - -U" > "$LOCAL_PCAP_PATH" &
    fi

    PID=$!
    echo "$PID" > "$PID_FILE"
    echo "✅ Capture started (PID $PID), output file: $LOCAL_PCAP_PATH"
}

stop_capture() {
    if [[ -f "$PID_FILE" ]]; then
        PID=$(cat "$PID_FILE")
        echo "🛑 Stopping capture (PID $PID)..."
        kill "$PID"
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
