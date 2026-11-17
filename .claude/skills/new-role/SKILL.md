---
name: new-role
description: Crée un nouveau rôle Ansible du homelab selon les conventions du dépôt (arborescence, meta, playbook, inventaire, site.yml). Usage /new-role <nom_du_role> [groupe d'hôtes] [description].
argument-hint: "<nom_du_role> [groupe] [description]"
disable-model-invocation: true
---

# /new-role

Créer le rôle décrit par : `$ARGUMENTS`

Avant d'écrire quoi que ce soit, lire un rôle existant proche pour copier son style : `ansible/roles/postgresql/` (service + TLS + OpenBao) est la meilleure référence. Si le nom, le groupe d'hôtes ou le rôle du service ne sont pas clairs, demander à Alex.

## Fichiers à créer

Nom du rôle en `snake_case`. **Ne pas** utiliser `ansible-galaxy init` : on ne veut pas de README type ni de dossiers vides (`vars/`, `tests/`, `files/`).

- `ansible/roles/<role>/tasks/main.yml`
  - `---` en tête ; tâches nommées **en français**, à l'infinitif (« Installer… », « Déployer… ») ;
  - modules en FQCN (`ansible.builtin.apt`, `community.general.*`…) ;
  - `apt` : `update_cache: true` et `cache_valid_time: 3600` ;
  - `mode:` explicite et entre guillemets (`"0644"`) sur tout fichier ou dossier ;
  - `changed_when` / `failed_when` sur les tâches `command`/`shell` ;
  - TLS : `ansible.builtin.include_role: name: step_certificate` avec les variables `step_cert_*` (voir `postgresql`).
- `ansible/roles/<role>/defaults/main.yml` : toutes les variables, préfixées `<role>_`, commentées en français.
- `ansible/roles/<role>/handlers/main.yml` : seulement s'il y a des services à redémarrer ou recharger.
- `ansible/roles/<role>/templates/*.j2` : en-tête `# Géré par Ansible`.
- `ansible/roles/<role>/meta/main.yml` :
  ```yaml
  ---
  galaxy_info:
    author: Alex & Driss
    description: <description en français>
    license: MIT
    min_ansible_version: "2.15"
    platforms:
      - name: Debian
        versions: [bookworm]
  dependencies: []
  ```

## Secrets

Jamais de secret en clair ni de valeur par défaut contenant un mot de passe. Les lire dans OpenBao avec `community.hashi_vault.vault_read` ou `vault_kv2_get`, sur le chemin `{{ openbao_kv_mount }}/data/...`, avec `no_log: true` sur toute tâche qui manipule la valeur. Si le service a besoin d'un nouveau secret ou d'une AppRole, l'indiquer : il faudra le déclarer dans `openbao_approle`, à valider avec Alex.

## Raccordement

1. **Playbook** `ansible/<role-avec-tirets>.yml`, sur le modèle de `postgresql.yml` :
   ```yaml
   ---
   - name: <Titre>
     hosts: <groupe>
     become: true
     # Seulement si le rôle lit OpenBao :
     module_defaults:
       group/community.hashi_vault.vault:
         url: "{{ openbao_api_url }}"
         ca_cert: "{{ homelab_ca_cert }}"
         auth_method: token
         token: "{{ openbao_token | default(omit) }}"
     roles:
       - openbao_login   # seulement si le rôle lit OpenBao
       - <role>
   ```
2. **Inventaire** `ansible/inventory/hosts.yml` : si le groupe n'existe pas, le créer avec `ansible_host`. Demander l'IP à Alex : la plage .101 à .109 est déjà utilisée, et la VM doit exister dans `terraform/proxmox/homelab.auto.tfvars`. L'ajouter aussi à `dns_clients` si l'hôte utilise dns-1.
3. **`ansible/site.yml`** : ajouter un `import_playbook` à la bonne place dans l'ordre des dépendances (après DNS, la PKI et OpenBao si le rôle en dépend), avec un nom `Homelab - …`.
4. **README.md** : ajouter une ligne dans l'arborescence des rôles et dans la liste « one topic at a time ».

## Vérification

- yamllint passe automatiquement par le hook après chaque fichier.
- Lancer ansible-lint comme la CI (voir la section « Vérifications » de `CLAUDE.md`) et corriger.
- Proposer à Alex le dry-run, **sans le lancer** : `ansible-playbook <playbook>.yml --check --diff` depuis WSL.
- Aucune action git.
