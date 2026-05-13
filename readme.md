# @chr33s/ai

## macOS Setup

```sh
sudo sysadminctl -addUser mlx -fullName "MLX Guest User" -home /Users/Shared/mlx -password - -adminUser "$USER" -adminPassword - # add -shell /usr/bin/false if this account should never be used interactively
sysadminctl -secureTokenStatus mlx
sudo dscl . create /Users/mlx IsHidden 1

sudo mkdir -p /Users/shared/mlx/{code,data,machines,models}
sudo chown mlx:staff /Users/Shared/mlx
sudo chmod -R 775 /Users/shared/mlx/{code,data,machines,models}
sudo chmod +t /Users/shared/mlx/models

python3 -m venv /Users/Shared/mlx/.venv
source /Users/Shared/mlx/.venv/bin/activate
pip install --upgrade pip
pip install mlx-lm mlx

cat > /Users/Shared/mlx/.zprofile <<'EOF'
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

# Offline runtime profile.
scripts/sandbox.sh runtime -- /opt/homebrew/bin/node ./server.js

# One-time bootstrap profile for downloads.
scripts/sandbox.sh bootstrap -- /Users/Shared/mlx/.venv/bin/python -m mlx_lm.server
```

You can override the shared paths if you need a different layout:

```sh
APP_ROOT="$PWD" \
DATA_ROOT=/Users/Shared/mlx/data \
MODEL_ROOT=/Users/Shared/mlx/models \
CACHE_ROOT=/Users/Shared/mlx/.cache/hf \
TMP_ROOT=/private/tmp/chr33s-ai \
scripts/sandbox.sh runtime -- /opt/homebrew/bin/node ./server.js
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
mx.set_wired_limit(96 * 1024**3) 

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
brew services start container
container system kernel set --recommended --arch arm64

container run --rm --name devcontainer --env-file .devcontainer/devcontainer.env -v "$HOME/Developer:/workspace/developer" --user node mcr.microsoft.com/devcontainers/typescript-node:24 sleep infinity

echo '{"dev.containers.experimentalAppleContainerSupport": true}' >> ~/Library/Application Support/Code/User/settings.json

# > Dev Containers: Attach to Running Apple Container

./.devcontainer/devcontainer.sh all
# later, after attaching in VS Code:
./.devcontainer/devcontainer.sh attach
```
