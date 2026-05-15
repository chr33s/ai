# @chr33s/ai

## macOS Setup

```sh
sudo sysadminctl -addUser mlx -fullName "MLX Guest User" -home /Users/Shared/mlx -password - -adminUser "$USER" -adminPassword - # add -shell /usr/bin/false if this account should never be used interactively
sysadminctl -secureTokenStatus mlx
sudo dscl . create /Users/mlx IsHidden 1

sudo -u mlx mkdir -p /Users/Shared/mlx/{code,data,machines,models,.cache/hf}
sudo chmod +t /Users/Shared/mlx/models

sudo -u mlx python3 -m venv /Users/Shared/mlx/.venv
sudo -u mlx /Users/Shared/mlx/.venv/bin/pip install --upgrade pip
sudo -u mlx /Users/Shared/mlx/.venv/bin/pip install mlx-lm mlx

sudo -u mlx tee /Users/Shared/mlx/.zprofile >/dev/null <<'EOF'
alias mlx_on="source /Users/Shared/mlx/.venv/bin/activate"
export MLX_MODEL_PATH="/Users/Shared/mlx/models"
export HF_HOME="/Users/Shared/mlx/.cache/hf"
EOF

top -o mem # Activity monitor (gpu tab)
```

### Sandbox

`sandbox-exec` is deprecated on modern macOS, so this repo treats it as defense in depth rather than a primary isolation boundary. The real boundary should still be the dedicated `mlx` account and, when practical, the container workflow below.

This repo includes two seatbelt profiles:

- `sandbox/runtime.sb`: offline, read-only access to code and models, write access only to data, cache, and temp directories.
- `sandbox/bootstrap.sb`: broader profile for one-time model or package downloads.

The launcher script runs an explicit executable under the `mlx` account with the shared paths from this README:

```sh
chmod +x scripts/sandbox.sh

# Offline runtime profile (no network — use for inference jobs that read a local model).
scripts/sandbox.sh runtime -- /Users/Shared/mlx/.venv/bin/python -m mlx_lm.generate \
  --model mlx-community/Llama-3.2-3B-Instruct-4bit \
  --prompt "Hello"

# One-time bootstrap profile for downloads (network allowed).
scripts/sandbox.sh bootstrap -- /Users/Shared/mlx/.venv/bin/pip install --upgrade mlx-lm
```

You can override the shared paths if you need a different layout:

```sh
APP_ROOT="$PWD" \
DATA_ROOT=/Users/Shared/mlx/data \
MODEL_ROOT=/Users/Shared/mlx/models \
CACHE_ROOT=/Users/Shared/mlx/.cache/hf \
TMP_ROOT=/private/tmp/chr33s-ai \
scripts/sandbox.sh runtime -- /Users/Shared/mlx/.venv/bin/python /Users/Shared/mlx/code/generate.py
```

Operational rules:

- Keep `MODEL_ROOT` read-only during normal runtime.
- Download or update models with the `bootstrap` profile, then switch back to `runtime`.
- Do not grant access to your normal home directory, SSH keys, or Keychain-backed material.
- Wrap only the inference or app process, not your editor or shell session.

```py
import mlx.core as mx

# 1. Set the Wired Limit (Prevents the OS from swapping this RAM to disk)
# Example: Wire 48GB on a 64GB Unified Memory system
mx.set_wired_limit(48 * 1024**3)

# 2. Set the Metal Memory Limit (Caps the GPU allocation)
# This prevents the LLM from crashing the entire OS if the KV cache grows too large
mx.set_memory_limit(40 * 1024**3)
```

### TODO

- [ ] https://github.com/antirez/ds4
- [ ] https://github.com/mitsuhiko/pi-ds4

### DevContainer

```sh
brew install container
container system start
container system kernel set --recommended --arch arm64

container run --rm --name devcontainer --env-file .devcontainer/devcontainer.env -v "$HOME/Developer:/workspace/developer" --user node mcr.microsoft.com/devcontainers/typescript-node:24 sleep infinity

# Enable Apple container support in the host VS Code: open the Command Palette
# (Cmd+Shift+P) → "Preferences: Open User Settings (JSON)" and add:
#   "dev.containers.experimentalAppleContainerSupport": true

# > Dev Containers: Attach to Running Apple Container
# When prompted for a folder, pick /workspace/developer/code/chr33s/ai
# Then in the integrated terminal (cwd = repo root):

./.devcontainer/devcontainer.sh all
# later, after attaching in VS Code:
./.devcontainer/devcontainer.sh attach
```
