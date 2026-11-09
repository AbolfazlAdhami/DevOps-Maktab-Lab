#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VM_NAME="${VM_NAME:-devops-ubuntu}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/devops_lab_ed25519}"
VM_CPUS="${VM_CPUS:-2}"
VM_MEMORY="${VM_MEMORY:-2G}"
VM_DISK="${VM_DISK:-12G}"
UBUNTU_RELEASE="${UBUNTU_RELEASE:-24.04}"

command -v multipass >/dev/null || { echo "Install Multipass first: brew install --cask multipass" >&2; exit 1; }

if ! multipass list >/dev/null 2>&1; then
  cat >&2 <<'EOF'
Multipass service is not ready. Open the Multipass app from Applications,
approve any macOS virtualization/network extension prompts, then retry.
Check readiness with: multipass list
EOF
  exit 1
fi

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
if [[ ! -f "$SSH_KEY" ]]; then
  ssh-keygen -q -t ed25519 -N '' -C "devops-lab-vm" -f "$SSH_KEY"
  chmod 600 "$SSH_KEY"
fi

if multipass info "$VM_NAME" >/dev/null 2>&1; then
  echo "VM '$VM_NAME' already exists; leaving it unchanged."
else
  CLOUD_INIT="$(mktemp)"
  trap 'rm -f "$CLOUD_INIT"' EXIT
  sed "s|PLACEHOLDER_SSH_PUBLIC_KEY|$(cat "$SSH_KEY.pub")|" "$ROOT_DIR/cloud-init.yaml" > "$CLOUD_INIT"
  multipass launch "release:$UBUNTU_RELEASE" \
    --name "$VM_NAME" --cpus "$VM_CPUS" --memory "$VM_MEMORY" \
    --disk "$VM_DISK" --cloud-init "$CLOUD_INIT"
fi

VM_IP="$(multipass info "$VM_NAME" --format json | python3 -c 'import json,sys; d=json.load(sys.stdin); info=d.get("info", d); vm=info.get(sys.argv[1]); assert vm, f"VM {sys.argv[1]} missing from Multipass info"; ips=vm.get("ipv4", []); assert ips, f"No IP address reported for {sys.argv[1]}"; print(ips[0])' "$VM_NAME")"
if [[ -z "$VM_IP" ]]; then echo "Could not determine VM IP" >&2; exit 1; fi

# This is a fresh, isolated lab VM created locally by Multipass. Remove only
# this VM's old known-host entry so a recreated VM with a new host key can connect.
ssh-keygen -R "$VM_IP" >/dev/null 2>&1 || true
ssh-keyscan -H -T 5 "$VM_IP" >> "$HOME/.ssh/known_hosts" 2>/dev/null || {
  echo "Could not retrieve SSH host key from $VM_IP" >&2
  exit 1
}

cat > "$ROOT_DIR/inventory/hosts.yml" <<EOF
all:
  children:
    ubuntu_lab:
      hosts:
        devops_ubuntu:
          ansible_host: $VM_IP
          ansible_user: lab
          ansible_ssh_private_key_file: $SSH_KEY
          ansible_python_interpreter: /usr/bin/python3
EOF

echo "VM ready: $VM_NAME at $VM_IP"
echo "Ansible inventory updated: $ROOT_DIR/inventory/hosts.yml"
echo "Next: cd '$ROOT_DIR' && ansible ubuntu_lab -m ping"