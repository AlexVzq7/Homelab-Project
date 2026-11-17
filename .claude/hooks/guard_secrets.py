#!/usr/bin/env python3
"""PreToolUse : empêche Claude de lire ou d'écrire les secrets du homelab.

Bloque (code de sortie 2, la raison est renvoyée à Claude) :
  - Read/Edit/Write/MultiEdit/NotebookEdit/Grep sur un fichier sensible ;
  - toute modification directe d'un fichier chiffré par ansible-vault ;
  - les commandes Bash/PowerShell qui citent un fichier sensible ou qui
    déchiffrent/affichent des secrets (ansible-vault view, tofu state pull...).
"""
import fnmatch
import json
import os
import re
import sys

# Noms de fichiers sensibles (comparés au nom de base, sans tenir compte de la casse)
BLOCKED_NAMES = [
    "*.tfstate", "*.tfstate.*", "*.tfvars", "*.tfvars.json", "*.tfplan",
    "*vault_pass*", "*.ovpn", "*.key", "*.pem", "*.p12", "*.pfx",
    "id_rsa", "id_ed25519", "id_ecdsa", ".env", ".env.*",
    "kubeconfig*", "*.kubeconfig",
]
# Exceptions : modèles sans secret et données publiques du homelab
ALLOWED_NAMES = ["*.example", "homelab.auto.tfvars"]
# Dossiers dont tout le contenu est sensible
BLOCKED_DIRS = ["vw-data", ".config/homelab"]

# Même logique pour le texte d'une commande shell
ALLOWED_TOKENS = re.compile(r"\S*(?:\.example|homelab\.auto\.tfvars)\b", re.I)
BLOCKED_COMMAND_PATTERNS = [
    (r"\.tfstate", "fichier de state OpenTofu"),
    (r"\.tfvars(?:\.json)?(?![\w.])", "fichier .tfvars (secrets)"),
    (r"\.tfplan\b", "plan OpenTofu sauvegardé"),
    (r"vault_pass", "mot de passe ansible-vault"),
    (r"\.config[/\\]homelab", "dossier des secrets ~/.config/homelab"),
    (r"\.ovpn\b", "profil OpenVPN"),
    (r"\bid_(?:rsa|ed25519|ecdsa)\b(?!\.pub)", "clé SSH privée"),
    (r"[\w-]\.(?:key|pem|p12|pfx)\b", "clé privée / certificat"),
    (r"\bkubeconfig", "kubeconfig"),
    (r"(?:^|[\s/\\\"'=])\.env(?:\.\w+)?(?=$|[\s\"';|&)])", "fichier .env"),
    (r"vw-data", "données Vaultwarden"),
    (r"\bansible-vault\s+(?:view|decrypt|edit)\b", "déchiffrement ansible-vault"),
    (r"\b(?:tofu|terraform|tofu-homelab)\b[^|;&]*\bstate\s+(?:pull|show)\b", "lecture brute du state"),
    (r"\b(?:tofu|terraform|tofu-homelab)\b[^|;&]*\bshow\b[^|;&]*-json", "state/plan en JSON (valeurs sensibles en clair)"),
]

FILE_TOOLS = {"Read", "Edit", "Write", "MultiEdit", "NotebookEdit"}
WRITE_TOOLS = {"Edit", "Write", "MultiEdit", "NotebookEdit"}
SHELL_TOOLS = {"Bash", "PowerShell"}


def block(reason: str) -> None:
    print(
        f"Bloqué par .claude/hooks/guard_secrets.py : {reason}. "
        "Ne pas contourner ce blocage. Pour connaître la forme d'un fichier secret, "
        "lire son .example ; si la valeur est vraiment nécessaire, demander à Alex.",
        file=sys.stderr,
    )
    sys.exit(2)


def sensitive_path(path: str) -> str | None:
    norm = path.replace("\\", "/").lower()
    base = norm.rstrip("/").rsplit("/", 1)[-1]
    for d in BLOCKED_DIRS:
        if f"/{d}/" in f"/{norm}/":
            return f"dossier sensible ({d})"
    if any(fnmatch.fnmatch(base, p) for p in ALLOWED_NAMES):
        return None
    for p in BLOCKED_NAMES:
        if fnmatch.fnmatch(base, p):
            return f"fichier sensible ({p})"
    return None


def is_vault_encrypted(path: str) -> bool:
    try:
        with open(path, "rb") as f:
            return f.read(14) == b"$ANSIBLE_VAULT"
    except OSError:
        return False


def check_command(command: str) -> str | None:
    cleaned = ALLOWED_TOKENS.sub(" ", command)
    for pattern, label in BLOCKED_COMMAND_PATTERNS:
        if re.search(pattern, cleaned, re.I):
            return f"la commande touche un élément sensible ({label})"
    return None


def main() -> None:
    for stream in (sys.stdin, sys.stdout, sys.stderr):
        stream.reconfigure(encoding="utf-8")
    data = json.load(sys.stdin)
    tool = data.get("tool_name", "")
    params = data.get("tool_input") or {}

    if tool in FILE_TOOLS:
        path = params.get("file_path") or params.get("notebook_path") or ""
        reason = sensitive_path(path)
        if reason:
            block(f"{tool} sur {path} : {reason}")
        if tool in WRITE_TOOLS and is_vault_encrypted(path):
            block(
                f"{path} est chiffré par ansible-vault ; une modification directe le corromprait. "
                "Indiquer à Alex de lancer `ansible-vault edit` depuis WSL"
            )
    elif tool == "Grep":
        for key in ("path", "glob"):
            value = params.get(key) or ""
            reason = sensitive_path(value) or (check_command(value) if key == "glob" else None)
            if value and reason:
                block(f"Grep ({key}={value}) : {reason}")
    elif tool in SHELL_TOOLS:
        reason = check_command(params.get("command") or "")
        if reason:
            block(reason)


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as exc:  # en cas de doute, on bloque plutôt que de laisser fuiter
        print(f"guard_secrets.py a échoué ({exc!r}) ; action bloquée par précaution.", file=sys.stderr)
        sys.exit(2)
