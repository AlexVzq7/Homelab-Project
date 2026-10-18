# Homelab

Infrastructure as Code for our homelab: VM provisioning on Proxmox with OpenTofu/Terraform, and service configuration (DNS, LDAP, PKI, OpenBao, PostgreSQL, VPN) with Ansible.

## Repository structure

```
homelab/
├── ansible/
│   ├── ansible.cfg
│   ├── homelab-ca.crt          # public root certificate of the step-ca (used by every role)
│   ├── inventory/
│   │   ├── hosts.yml           # single inventory, each machine declared once
│   │   └── group_vars/
│   │       ├── all/            # shared settings (domain, step-ca, OpenBao) + vaulted secrets
│   │       ├── ldap_servers.yml
│   │       └── openbao_server.yml
│   ├── roles/
│   │   ├── backup/             # daily local backups (pg_dump, slapcat, raft snapshot, step-ca)
│   │   ├── bind_zone/          # homelab.local zone on dns-1
│   │   ├── dns_client/         # points the VMs at dns-1
│   │   ├── openbao_base/       # OpenBao audit log, KV engine, "ansible" AppRole
│   │   ├── openbao_install/    # OpenBao + Caddy (docker compose) on vault
│   │   ├── openbao_ldap_auth/  # LDAP login, policies and group mapping on OpenBao
│   │   ├── openbao_approle/    # machine AppRoles (tofu, backup) and generated secrets
│   │   ├── openbao_login/      # logs in to OpenBao with the "ansible" AppRole
│   │   ├── openldap_installation/
│   │   ├── openldap_tls/       # LDAPS only (port 389 closed)
│   │   ├── pfsense_vpn/        # pfSense interfaces, OpenVPN server, .ovpn export
│   │   ├── postgresql/         # database holding the OpenTofu state
│   │   ├── qemu_guest_agent/
│   │   └── step_certificate/   # shared: step-ca certificate + automatic renewal
│   ├── outputs/                # generated .ovpn files (gitignored)
│   └── *.yml                   # one playbook per topic, site.yml imports them all
└── terraform/
    ├── proxmox/                # VMs (bpg/proxmox provider); data in homelab.auto.tfvars
    └── pfsense/                # pfSense VM with its config.xml ISO
```

## Requirements

- Ansible core 2.15+ (tested with 2.20) and `pip install -r ansible/requirements.txt`
- Collections: `ansible-galaxy collection install -r ansible/requirements.yml`
- OpenTofu 1.6+ or Terraform 1.6+
- A Proxmox API token

## First-time setup on a workstation

Run Ansible from the Linux side (WSL on Windows), not from a Windows-mounted folder for secrets.

1. **Vault password.** It lives outside the repository, in `~/.config/homelab/vault_pass` (mode 0600, or 0700 if it is a script that prints the password):

   ```bash
   mkdir -p ~/.config/homelab && chmod 700 ~/.config/homelab
   printf '%s' 'the-shared-password' > ~/.config/homelab/vault_pass
   chmod 600 ~/.config/homelab/vault_pass
   ```

2. **SSH host keys.** `host_key_checking` is on. Add the machines once, after checking the fingerprints on the Proxmox console:

   ```bash
   ssh-keyscan 192.168.1.103 192.168.1.104 192.168.1.105 192.168.1.106 192.168.1.107 192.168.1.108 >> ~/.ssh/known_hosts
   ```

   When a VM is rebuilt, remove its old key with `ssh-keygen -R <ip>`.

## Usage

### Provision the VMs

```bash
cd terraform/proxmox
tofu init && tofu plan && tofu apply
```

The VM list and the authorised SSH keys are in `homelab.auto.tfvars`. API tokens go in `secrets.auto.tfvars` (gitignored, see `terraform.tfvars.example`).

### OpenBao bootstrap (once)

OpenBao must be initialised and unsealed by hand first (`bao operator init`, `bao operator unseal`). Then create the AppRole that every playbook uses, with the root token, one time only:

```bash
cd ansible
ansible-playbook openbao-bootstrap.yml -e openbao_bootstrap_token=<root token>
```

This writes `inventory/group_vars/all/openbao.yml` (encrypted with ansible-vault). After that, revoke the root token (`bao token revoke <root token>`) and remove `openbao_root_token` from `openbao_server.yml`. A new root token can be generated later with the unseal keys (`bao operator generate-root`).

To rotate the AppRole secret: `ansible-playbook openbao-bootstrap.yml -e openbao_ansible_rotate=true`.

### Deploy everything

```bash
cd ansible
ansible-playbook site.yml --check --diff   # dry run first
ansible-playbook site.yml
```

Or one topic at a time: `dns.yml`, `openldap.yml`, `openbao.yml`, `openbao-ldap.yml`, `openbao-approle.yml`, `postgresql.yml`, `backup.yml`, `qemu-guest-agent.yml`.

### pfSense / OpenVPN

pfSense only accepts the `ansible-node` SSH key, so run this playbook from `ansible-node`:

```bash
ansible-playbook pfsense-vpn.yml -e vpn_public_endpoint=<public IP or DNS name>
```

The `.ovpn` files are written to `ansible/outputs/` with mode 0600. Changing `vpn_tls_crypt` means every client needs its new `.ovpn`.

### Backups

`backup.yml` installs a daily systemd timer on each server; dumps are kept 14 days in `/var/backups/homelab/` on the machine itself. They still need to be copied off the host (Proxmox Backup Server or similar).

## Linting

```bash
pip install pre-commit && pre-commit install
pre-commit run --all-files
```

The same checks (gitleaks, yamllint, ansible-lint, `tofu fmt`/`validate`) run in GitHub Actions (`.github/workflows/lint.yml`).

## Security

No secret is stored in plain text. Ansible secrets are encrypted with ansible-vault; the vault password, `*.tfvars` secrets, Terraform state, private keys and `.ovpn` files are gitignored. See [`.gitignore`](./.gitignore).

## Authors

Alex, Driss — personal homelab project.
