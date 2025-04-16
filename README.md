# Remote Network Traffic Capture - Usage Guide

This script allows you to remotely capture network traffic from a virtual machine (VM) over SSH, and save the `.pcap` data directly to your local machine in real time.

---

## 🔧 Requirements

### On your **local machine** (macOS):

- `bash`
- `ssh`
- `sshpass`


On the remote VM:
	•	tcpdump installed
	•	SSH access with either:
	•	SSH key authentication
	•	or user/password access

⸻

📁 File Structure

```bash
.
├── capture.sh              # Main script
├── config.conf.example     # Example config file
├── README.md                # This documentation
└── captures/               # Output folder for .pcap files
```


⸻

⚙️ Setup
1.	Make the script executable:

```bash
chmod +x capture.sh
```

2.	Copy the example config and edit it:

```bash
cp config.conf.example config.conf
```

Edit config.conf to match your environment:
```
REMOTE_HOST=192.168.1.50            # IP or hostname of the remote VM
REMOTE_USER=myuser                  # SSH username
INTERFACE=game                      # Network interface to capture on (e.g., eth0, enp0s3, game)
LOCAL_PCAP_PATH=./captures/traffic.pcap  # Local file path to save the .pcap
# Optional: only if not using SSH keys
# SSH_PASSWORD=yourpassword
```


⸻

🚀 Usage

Start the capture:

```bash
./capture.sh start
```

•	The script checks if an SSH key exists.
•	If no key is found, you’ll be prompted to generate one.
•	If your key isn’t yet authorized on the remote host, you’ll be asked to copy it.
•	If not using keys, it will prompt for your SSH password or use sshpass.

Stop the capture:

```bash
./capture.sh stop
```

•	This stops the background SSH/tcpdump process and removes the PID file.

⸻

📖 Notes
	•	You can open or live-read the .pcap file with:

```bash
tcpdump -r ./captures/traffic.pcap
```


•	To allow tcpdump without password on the remote machine, add this to /etc/sudoers:

```bash
myuser ALL=(ALL) NOPASSWD: /usr/sbin/tcpdump
```



⸻

🛡️ Security Tip

Use SSH keys for automation and security. Avoid storing plain-text passwords in config files unless absolutely necessary.