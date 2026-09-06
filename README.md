# Homelab

Infrastructure as Code for my personal homelab: VM provisioning on Proxmox and network/directory configuration via Ansible.

## Repository structure

```
homelab/
├── ansible/
│   ├── dns/            # Ansible project for BIND9 (zone homelab.local) - contains roles: bind_zone, dns_client
│   ├── openldap/       # Ansible project for OpenLDAP - contains roles: openldap_installation, openldap_content
│   └── pfsense-vpn/    # Git submodule -> github.com/MirDriss/pfsense-homelab-ansible - contains role: pfsense_vpn
└── terraform/
    ├── proxmox/         # VM provisioning (bpg/telmate provider) on the Proxmox cluster
    └── pfsense/         # Terraform deployment of the pfSense firewall
```

**Note on Ansible:** each subfolder under `ansible/` (`dns/`, `openldap/`, `pfsense-vpn/`) is a self-contained Ansible project — it has its own `ansible.cfg`, `inventory/`, and playbook — it is **not** a role itself. The actual Ansible roles live one level deeper, inside each project's own `roles/` subfolder (e.g. `ansible/dns/roles/bind_zone/`).

## Requirements

- Terraform
- Ansible
- API access (token) to the Proxmox cluster
- git with submodule support

## Installation

```bash
git clone --recurse-submodules <REPO_URL>
cd homelab
```

If the repo was already cloned without submodules:

```bash
git submodule update --init --recursive
```

## Usage

### Provision Proxmox infrastructure

```bash
cd terraform/proxmox
terraform init
terraform plan
terraform apply
```

### Deploy the pfSense firewall

```bash
cd terraform/pfsense
terraform init && terraform apply
```

Additional automation (VPN, users) lives in the `ansible/pfsense-vpn` submodule.

### Deploy DNS (BIND9)

```bash
cd ansible/dns
ansible-playbook -i inventory/hosts.yml playbook.yml
```

### Deploy OpenLDAP

```bash
cd ansible/openldap
ansible-playbook -i inventory/hosts.yml playbook.yml --vault-password-file .vault_pass
```

## Security

This repository contains no secrets in plain text. The following files/folders are excluded via `.gitignore` and must be provided or generated locally by anyone cloning the repo:

| File / folder                       | Content                                      |
|--------------------------------------|-----------------------------------------------|
| `*.tfvars`                           | Proxmox / pfSense API tokens                  |
| `*.tfstate`, `*.tfstate.*`           | Terraform state (may expose sensitive data)   |
| `.vault_pass`                        | Ansible vault password (OpenLDAP)             |
| `*.pem`, `*.key`, `*.crt`, `*.ovpn`  | Certificates and private keys                 |

See the [`.gitignore`](./.gitignore) file for the full list.

## Author

Alex, Driss — personal homelab project.
