#!/usr/bin/env python3
"""PostToolUse : vérifie le fichier que Claude vient de modifier.

  - *.tf / *.tfvars : `tofu fmt` (ou `terraform fmt` à défaut) reformate le fichier ;
  - *.yml / *.yaml  : yamllint avec la config du dépôt, lancé dans WSL depuis le
    cache pre-commit (même version que le pre-commit et que la CI).

Si un problème est trouvé, le code de sortie 2 renvoie le détail à Claude pour
qu'il corrige tout de suite. Si un outil manque, le hook ne bloque rien.
"""
import json
import os
import shutil
import subprocess
import sys

PROJECT_DIR = os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()
WSL_DISTRO = os.environ.get("HOMELAB_WSL_DISTRO", "Ubuntu")
TIMEOUT = 60


def report(message: str) -> None:
    print(message, file=sys.stderr)
    sys.exit(2)


def context(message: str) -> None:
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PostToolUse", "additionalContext": message}}))
    sys.exit(0)


def to_wsl(path: str) -> str:
    path = os.path.abspath(path).replace("\\", "/")
    if len(path) > 1 and path[1] == ":":
        return f"/mnt/{path[0].lower()}{path[2:]}"
    return path


def find_fmt() -> list[str] | None:
    for exe in ("tofu", "terraform"):
        found = shutil.which(exe)
        if found:
            return [found]
    if os.path.exists(r"C:\terraform\terraform.exe"):
        return [r"C:\terraform\terraform.exe"]
    return None


def lint_tf(path: str) -> None:
    fmt = find_fmt()
    if not fmt:
        return
    before = open(path, "rb").read()
    r = subprocess.run(fmt + ["fmt", "-no-color", path], capture_output=True, text=True, timeout=TIMEOUT)
    if r.returncode != 0:
        report(f"`{os.path.basename(fmt[0])} fmt` a échoué sur {path} (syntaxe HCL ?) :\n{r.stderr or r.stdout}")
    if open(path, "rb").read() != before:
        context(f"{path} a été reformaté par `fmt` après ta modification ; relis-le avant de le modifier à nouveau.")


def lint_yaml(path: str) -> None:
    if open(path, "rb").read(14) == b"$ANSIBLE_VAULT":
        return
    if os.name == "nt":
        if not shutil.which("wsl.exe"):
            return
        script = (
            'Y=$(ls ~/.cache/pre-commit/repo*/py_env-*/bin/yamllint 2>/dev/null | head -1); '
            '[ -n "$Y" ] || exit 99; '
            'cd "$1" && "$Y" -f parsable -c .yamllint "$2"'
        )
        # --exec : pas de shell intermédiaire qui casserait les guillemets du script
        cmd = ["wsl.exe", "-d", WSL_DISTRO, "--exec", "bash", "-c", script, "_",
               to_wsl(PROJECT_DIR), to_wsl(path)]
    else:
        yl = shutil.which("yamllint")
        if not yl:
            return
        cmd = [yl, "-f", "parsable", "-c", os.path.join(PROJECT_DIR, ".yamllint"), path]
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=TIMEOUT)
    except (OSError, subprocess.TimeoutExpired):
        return
    if r.returncode == 99 or r.returncode not in (0, 1):
        return  # yamllint introuvable ou WSL indisponible : on ne bloque pas
    if r.returncode == 1 or "[error]" in r.stdout:
        report(f"yamllint signale des problèmes dans {path} ; corrige-les :\n{r.stdout.strip()}")


def main() -> None:
    for stream in (sys.stdin, sys.stdout, sys.stderr):
        stream.reconfigure(encoding="utf-8")
    data = json.load(sys.stdin)
    params = data.get("tool_input") or {}
    path = params.get("file_path") or ""
    if not path or not os.path.isfile(path):
        return
    rel = os.path.relpath(path, PROJECT_DIR).replace("\\", "/")
    if rel.startswith("..") or "/.terraform/" in f"/{rel}" or rel.startswith("_archive/"):
        return
    lower = path.lower()
    if lower.endswith((".tf", ".tfvars")):
        lint_tf(path)
    elif lower.endswith((".yml", ".yaml")):
        lint_yaml(path)


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as exc:
        print(f"lint_on_edit.py : erreur interne ignorée ({exc!r})", file=sys.stderr)
        sys.exit(0)
