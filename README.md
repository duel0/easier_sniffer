# Remote Network Traffic Capture - Usage Guide

This script allows you to remotely capture network traffic from a virtual machine (VM) over SSH, and save the `.pcap` data directly to your local machine in real time. It also creates a FIFO pipe for live streaming of the capture data.

---

## 🔧 Requirements

### On your **local machine** (macOS):

- `bash`
- `ssh`
- `sshpass` (for password authentication)
- Optional: `tshark` (for viewing live stream data)

### On the remote VM:
- `tcpdump` installed
- SSH access with either:
  - SSH key authentication
  - or user/password access

⸻

## 📁 File Structure

```bash
.
├── capture.sh              # Main script
├── config.conf             # Configuration file
├── README.md               # This documentation
├── live_capture.pcap       # FIFO pipe for live streaming
├── capture.pid             # PID file to track running captures
└── captures/               # Output folder for .pcap files
```

⸻

## ⚙️ Setup
1. Make the script executable:

```bash
chmod +x capture.sh
```

2. Create or edit the config.conf file:

```bash
cp config.conf.example config.conf  # If example exists
```

Edit config.conf to match your environment:
```
REMOTE_HOST=192.168.1.50            # IP or hostname of the remote VM
REMOTE_USER=myuser                  # SSH username
INTERFACE=game                      # Network interface to capture on (e.g., eth0, enp0s3, game)
LOCAL_PCAP_PATH=./captures/traffic.pcap  # Local file path to save the .pcap
# Optional: uncomment and set if not using SSH keys
# SSH_PASSWORD=yourpassword
```

⸻

## 🚀 Usage

### Start the capture:

```bash
./capture.sh start
```

- The script will create a FIFO pipe for live streaming
- If SSH_PASSWORD is provided in config.conf, it will use sshpass
- If no password is provided but required, it will prompt for one
- Capture data is both saved to the local file and available through the FIFO pipe

### Stop the capture:

```bash
./capture.sh stop
```

- This stops the background SSH/tcpdump process and removes the PID file

⸻

## 📊 Viewing Capture Data

You have two options for viewing capture data:

1. View the saved file (after or during capture):

```bash
tcpdump -r ./captures/traffic.pcap
```

2. View the live stream in real-time (during capture):

```bash
tshark -r ./live_capture.pcap
```

⸻

## 📖 Notes

- To allow tcpdump without password on the remote machine, add this to /etc/sudoers:

```bash
myuser ALL=(ALL) NOPASSWD: /usr/sbin/tcpdump
```

⸻

## 🛡️ Security Tip

Use SSH keys for automation and security. Avoid storing plain-text passwords in config files unless absolutely necessary.