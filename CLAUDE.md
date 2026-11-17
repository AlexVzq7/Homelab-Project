# Homelab : consignes pour Claude

Infra as code du homelab d'Alex et Driss : VM Proxmox et pfSense avec OpenTofu (`terraform/`), configuration des services avec Ansible (`ansible/`). Voir `README.md` pour l'architecture et les commandes.

## Règles non négociables

- **Git : aucune action d'écriture sans demander.** Pas de commit, branche, checkout, stash, reset, push, ni suppression de `.git/index.lock`. `status`, `diff`, `log` sont libres. Alex gère git lui-même.
- **Jamais de `tofu apply` / `destroy` / `import` / `state ...`**, ni d'`ansible-playbook` sans `--check`, sans accord explicite d'Alex pour cette exécution précise. Un dry-run (`tofu plan`, `ansible-playbook --check --diff`) peut être proposé librement.
- **Ne jamais lire de secrets** : `*.tfstate*`, `*.tfvars` (sauf `*.example` et `homelab.auto.tfvars`), `vault_pass`, `~/.config/homelab/`, `*.ovpn`, clés privées, `.env`. Un hook (`.claude/hooks/guard_secrets.py`) les bloque ; ne pas chercher à le contourner (`cat` via PowerShell, WSL, copie, etc.). Pour connaître la forme d'un fichier secret, lire son `.example`.
- **Fichiers ansible-vault** (`ansible/inventory/group_vars/all/*.yml` commençant par `$ANSIBLE_VAULT`) : ne jamais les modifier directement. Indiquer à Alex la commande `ansible-vault edit <fichier>` à lancer depuis WSL.

## Où s'exécute quoi

- **Ansible** tourne dans **WSL (Ubuntu)**, pas sous Windows : `wsl.exe -d Ubuntu -- bash -lc 'cd /mnt/c/Users/alex/Documents/homelab/ansible && ansible-playbook ...'`. Mot de passe Vault : `~/.config/homelab/vault_pass` côté WSL.
- **OpenTofu** tourne sur le runner `opentofu` (192.168.1.107, utilisateur `debian`) via `tofu-homelab` dans `/opt/homelab/terraform/<stack>` : il lit les secrets dans OpenBao et seul cet hôte peut joindre la base PostgreSQL du state. Les `terraform.tfstate` locaux sont d'anciens restes, ils ne font pas foi. Utiliser `/tofu-plan`.
- **pfSense / OpenVPN** : le PC n'atteint le LAN 192.168.1.0/24 que par le tunnel OpenVPN de pfSense. `pfsense-vpn.yml` se lance depuis **ansible-node** (192.168.1.102), seule clé acceptée par pfSense ; le lancer depuis le PC coupe la session.
- `gh` est installé et authentifié **dans WSL** (compte AlexVzq7) : `MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu --cd /mnt/c/Users/alex/Documents/homelab --exec gh run list` (lecture de la CI : `gh run view <id> --log-failed`). Lecture seule sans accord d'Alex : pas de `gh pr create`, `gh pr merge`, `gh release`, etc.
- `tofu`, `yamllint` et `ansible-lint` ne sont pas sur le PATH Windows (les linters existent dans le cache pre-commit de WSL).

## Conventions du code

- Noms de tâches Ansible **en français**, modules en FQCN (`ansible.builtin.*`), variables préfixées par le nom du rôle.
- `meta/main.yml` : `author: Alex & Driss`, `license: MIT`, `min_ansible_version: "2.15"`, plateforme Debian bookworm.
- Un playbook par sujet à la racine de `ansible/`, importé dans `site.yml` dans l'ordre des dépendances (sauf `openbao-bootstrap.yml` et `pfsense-vpn.yml`).
- Secrets applicatifs : lus dans OpenBao (`community.hashi_vault`, rôle `openbao_login` en premier, `module_defaults` du groupe `community.hashi_vault.vault`), avec `no_log: true` sur les tâches qui les manipulent. Jamais en clair dans le dépôt.
- TLS : certificats step-ca via `include_role: step_certificate`.
- OpenTofu : versions de providers épinglées, chiffrement du state `enforced = true`, `tofu fmt` respecté.
- Nouveau rôle : `/new-role`. Revue sécurité avant commit : agent `iac-security-reviewer`.

## Vérifications

Un hook vérifie `yamllint` et `tofu fmt` après chaque modification. La CI (`.github/workflows/lint.yml`) lance aussi gitleaks, `ansible-lint --offline` et `tofu validate`. Pour ansible-lint en local :
`wsl.exe -d Ubuntu -- bash -lc 'cd /mnt/c/Users/alex/Documents/homelab/ansible && ANSIBLE_DEPRECATION_WARNINGS=false $(ls ~/.cache/pre-commit/repo*/py_env-*/bin/ansible-lint | head -1) --offline'`
