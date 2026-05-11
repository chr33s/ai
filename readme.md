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
