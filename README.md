# Homelab

Infrastructure as Code for my personal homelab: VM provisioning on Proxmox and network/directory configuration via Ansible.

## Repository structure

```
homelab/
├── ansible/
│   ├── ansible.cfg
│   ├── .vault_pass       # Ansible Vault password (gitignored, not in this repo)
│   ├── inventory/
│   │   ├── hosts.yml      # single inventory for the whole homelab
│   │   └── group_vars/
│   ├── roles/             # every role lives here
│   │   ├── bind_zone/
│   │   ├── dns_client/
│   │   ├── openldap_installation/
│   │   ├── openldap_content/
│   │   ├── openbao/
│   │   └── pfsense_vpn/
│   ├── outputs/            # generated OpenVPN client configs (.ovpn), gitignored
│   ├── dns.yml             # per-topic playbooks
│   ├── openldap.yml
│   ├── openbao.yml
│   ├── pfsense-vpn.yml
│   └── site.yml             # imports all of the above
└── terraform/
    ├── proxmox/         # VM provisioning (bpg/telmate provider) on the Proxmox cluster
    └── pfsense/         # Terraform deployment of the pfSense firewall
```

**Note on Ansible:** all roles now live under one shared `ansible/roles/` directory with a single `ansible.cfg` and inventory, following the [official Ansible sample layout](https://docs.ansible.com/ansible/latest/tips_tricks/sample_setup.html). Each topic (dns, openldap, openbao, pfsense-vpn) still has its own playbook at the root of `ansible/`, so each can be deployed independently. `pfsense_vpn` used to be a separate git submodule (`github.com/MirDriss/pfsense-homelab-ansible`); it is now a regular role in this repo.

## Requirements

- Terraform
- Ansible
- API access (token) to the Proxmox cluster

## Installation

```bash
git clone <REPO_URL>
cd homelab
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

### Deploy DNS (BIND9)

```bash
cd ansible
ansible-playbook dns.yml
```

### Deploy OpenLDAP

```bash
cd ansible
ansible-playbook openldap.yml
```

(the Ansible Vault password is read automatically from `ansible/.vault_pass`, per `ansible.cfg`)

### Deploy OpenBao (secrets management, replaces Vaultwarden on `vault`)

```bash
cd ansible
ansible-playbook openbao.yml
```

Role details and variables: `ansible/roles/openbao/README.md` (still being filled in).

### Deploy the pfSense / OpenVPN role

```bash
cd ansible
ansible-playbook pfsense-vpn.yml
```

### Deploy everything

```bash
cd ansible
ansible-playbook site.yml
```

## Security

This repository contains no secrets in plain text. The following files/folders are excluded via `.gitignore` and must be provided or generated locally by anyone cloning the repo:

| File / folder                       | Content                                      |
|--------------------------------------|-----------------------------------------------|
| `*.tfvars`                           | Proxmox / pfSense API tokens                  |
| `*.tfstate`, `*.tfstate.*`           | Terraform state (may expose sensitive data)   |
| `ansible/.vault_pass`                | Ansible vault password (OpenLDAP)             |
| `*.pem`, `*.key`, `*.crt`, `*.ovpn`  | Certificates and private keys                 |
| `ansible/outputs/`                   | Generated OpenVPN client configs              |

See the [`.gitignore`](./.gitignore) file for the full list.

## Author

Alex, Driss — personal homelab project.
