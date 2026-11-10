# DevOps lab

Learning project for building and deploying a small, secure service environment.

## Current environment

- macOS on Apple Silicon (`arm64`)
- Git and Ansible installed
- Local machine is the Ansible controller and practice target for initial, read-only checks
- Ubuntu server and public domain are not yet available

## Learning path

1. Learn Ansible inventory and safe, read-only checks locally.
2. Prepare an Ubuntu VM/server and configure it with Ansible.
3. Add network security, VPN, private DNS, and access management.
4. Deploy applications and progressively add orchestration, monitoring, and backups.

## Create the local Ubuntu VM

Install/authorize Multipass if needed, then run `./scripts/create-vm.sh`.
Defaults: Ubuntu 24.04 ARM64, 2 CPUs, 2 GiB RAM, and 12 GiB disk.
Override defaults with `VM_CPUS`, `VM_MEMORY`, `VM_DISK`, or `VM_NAME`.
The script creates an SSH key at `~/.ssh/devops_lab_ed25519` if needed and
updates `inventory/hosts.yml` with the VM's private IP. Check connectivity:

```sh
ansible ubuntu_lab -m ping
```

Inspect the VM without changing it with `ansible-playbook playbooks/check-host.yml`.
Prepare it with `ansible-playbook playbooks/prepare-ubuntu.yml`. The preparation
playbook updates packages and installs basic tools; it does not enable UFW or
change network access.

Create the restricted viewer account with `ansible-playbook playbooks/create-viewer.yml`.
The account is password-locked and is not granted sudo membership. It is for
local account/permissions exercises, not remote login until SSH access is
deliberately configured in a later security step.

Inspect SSH and firewall status with `ansible-playbook playbooks/firewall-baseline.yml`.
This inspection does not enable UFW or modify firewall rules; review Multipass
network access before changing firewall policy.

Do not expose this lab VM directly to the public internet. Its initial lab user
has passwordless sudo and SSH-key-only access; use this only in the isolated
local Multipass environment.

Do not store passwords, private keys, or other secrets in this repository.