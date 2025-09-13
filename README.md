# Metasploit RC Generator

`msf_gen.sh` is a Bash wrapper that dynamically generates and runs Metasploit resource scripts (`.rc`).  
It makes setting up repeatable labs and engagements faster by prompting you once for a few key values and then building a tailored `.rc` script on the fly.

---

## ✨ Features

- 🔹 Prompts for **workspace name** up front  
- 🔹 Auto-detects your local IP (`LHOST`), with manual override  
- 🔹 Lets you specify target(s) (`RHOSTS`) and listener port  
- 🔹 Quick payload selection (Windows/Linux Meterpreter, or Unix reverse shell)  
- 🔹 Optional recon phase (TCP port scan + HTTP title grabber)  
- 🔹 Background handler with chosen payload  
- 🔹 Logs output to `/tmp/<workspace>_<timestamp>.log`  
- 🔹 Leaves the generated RC file in `/tmp/` for reuse  

---

## 🚀 Installation

Clone the repo and make the script executable:

```bash
git clone https://github.com/yourusername/metasploit-rc-gen.git
cd metasploit-rc-gen
chmod +x msf_gen.sh
