#!/usr/bin/env bash
# Run this after starting one RunPod A100 Pod from victoriouscha/yu-a100-llm:1.0.
# This script does not download model weights, access SSH secrets, or modify data.
set -Eeuo pipefail

echo "=== 1. GPU hardware / driver ==="
command -v nvidia-smi >/dev/null || { echo "ERROR: nvidia-smi missing"; exit 1; }
nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader

echo "=== 2. Python, CUDA and AI libraries ==="
python - <<'PY'
import sys
import torch
import transformers
import accelerate
import bitsandbytes
import ipykernel
print("Python:", sys.version.split()[0])
print("PyTorch:", torch.__version__)
print("PyTorch CUDA:", torch.version.cuda)
print("Transformers:", transformers.__version__)
print("Accelerate:", accelerate.__version__)
print("bitsandbytes:", bitsandbytes.__version__)
print("ipykernel:", ipykernel.__version__)
assert torch.cuda.is_available(), "CUDA GPU is unavailable in PyTorch"
gpu = torch.cuda.get_device_name(0)
print("GPU:", gpu)
a = torch.ones((64, 64), device="cuda")
b = a @ a
assert float(b[0, 0].item()) == 64.0
print("GPU tensor operation: PASS")
PY

echo "=== 3. SSH server and student accounts ==="
/usr/sbin/sshd -t
for n in 01 02 03 04; do
  account="student${n}"
  id "$account" >/dev/null
  test -d "/workspace/students/$account"
  test -L "/home/$account"
  echo "$account: PASS"
done

echo "=== 4. Hugging Face cache location ==="
test -d /workspace/hf-cache/hub
echo "/workspace/hf-cache/hub: PASS"

echo "=== ALL BASIC CHECKS PASSED ==="
echo "NEXT: test public-key SSH for each student, model access, Qwen3 NF4 and Gemma 3 on the actual Pod."
