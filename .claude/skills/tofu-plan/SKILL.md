---
name: tofu-plan
description: Lance un `tofu plan` (jamais d'apply) d'un stack OpenTofu du homelab (proxmox ou pfsense) sur le runner opentofu, puis résume les changements. Usage /tofu-plan <proxmox|pfsense>.
argument-hint: "<proxmox|pfsense>"
disable-model-invocation: true
---

# /tofu-plan

Objectif : montrer à Alex ce qu'un `apply` changerait sur le stack `$ARGUMENTS`, **sans rien appliquer**.

## Contexte (pourquoi on ne lance pas tofu en local)

- Le state est dans PostgreSQL (`postgres`, 192.168.1.108), joignable **uniquement** depuis le runner `opentofu` (192.168.1.107).
- Sur le runner, `tofu-homelab` lit dans OpenBao (AppRole `tofu`) le mot de passe de la base, la passphrase de chiffrement du state et le token Proxmox, puis lance `tofu`. Aucun secret ne transite par le PC.
- Le runner travaille sur son propre clone : `/opt/homelab`. **Le plan reflète ce qui est poussé sur GitHub, pas les modifications locales non poussées.**
- Les `terraform.tfstate` locaux sont d'anciens restes : ne pas les utiliser (ils sont bloqués de toute façon).

## Étapes

1. **Stack** : `$ARGUMENTS` doit valoir `proxmox` ou `pfsense`. Sinon, demander lequel.

2. **Joignabilité** (le LAN passe par le VPN pfSense). Depuis Git Bash, préfixer par `MSYS_NO_PATHCONV=1` pour que les chemins Linux ne soient pas réécrits :
   ```bash
   MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu -- ssh -o BatchMode=yes -o ConnectTimeout=5 debian@192.168.1.107 true
   ```
   En cas d'échec : dire à Alex de vérifier que le tunnel OpenVPN est connecté, puis s'arrêter.

3. **Version du code planifié** (lecture seule) :
   ```bash
   MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu -- ssh debian@192.168.1.107 'git -C /opt/homelab log -1 --format="%h %s (%cr)"; git -C /opt/homelab status -sb | head -1'
   ```
   Comparer avec `git log -1 --oneline origin/master` et `git status` en local. Si le runner est en retard ou si des changements locaux dans `terraform/$ARGUMENTS` ne sont pas poussés, **le signaler et demander à Alex** avant tout `git pull` sur le runner. Ne jamais faire de pull, push ou commit de sa propre initiative.

4. **Plan** :
   ```bash
   MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu -- ssh debian@192.168.1.107 'cd /opt/homelab/terraform/STACK && tofu-homelab plan -input=false -no-color -lock-timeout=60s'
   ```
   (remplacer `STACK`). Lancer cette commande en arrière-plan si elle risque de dépasser 2 minutes.
   - Si tofu demande un `init` (providers ou backend) : lancer `tofu-homelab init -input=false -no-color`, puis relancer le plan.
   - Ne jamais ajouter `-out=` ni utiliser `show -json`, `state pull` ou `output` : ces commandes exposent des valeurs sensibles.
   - Un verrou du state (`Error acquiring the state lock`) veut dire que quelqu'un (Driss ?) travaille dessus : le signaler, **ne jamais** faire de `force-unlock`.

5. **Résumé pour Alex** (en français, court) :
   - la ligne `Plan: X to add, Y to change, Z to destroy` ;
   - **en premier et en gras**, toute ressource détruite ou remplacée (`-/+`, `destroy`), avec l'attribut qui force le remplacement ;
   - les changements sensibles : VM pfSense, interfaces réseau ou bridges, disques, `node_name`, cloud-init/SSH ;
   - le « drift » (changements faits à la main dans Proxmox que tofu veut annuler) ;
   - ne jamais recopier de valeur marquée `(sensitive value)`.

6. **Ne pas appliquer.** Terminer en donnant la commande à Alex s'il souhaite appliquer :
   `ssh debian@192.168.1.107 'cd /opt/homelab/terraform/STACK && tofu-homelab apply'`
   Pour le stack pfsense, rappeler qu'un remplacement de la VM coupe le VPN, donc la session du PC.
