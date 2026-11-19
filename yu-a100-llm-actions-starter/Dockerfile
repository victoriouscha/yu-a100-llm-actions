# RunPod A100 x10, 4 students/Pod. GPU validation must be performed on RunPod.
FROM nvidia/cuda:12.9.1-cudnn-runtime-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    VIRTUAL_ENV=/opt/venv \
    HF_HUB_CACHE=/workspace/hf-cache/hub \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility
ENV PATH="/opt/venv/bin:${PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-venv python3-pip python3-dev \
    ca-certificates openssh-server git git-lfs curl tini \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/venv \
    && /opt/venv/bin/python -m pip install --no-cache-dir --upgrade pip setuptools wheel

# Match the known-good teaching environment: PyTorch 2.8 with CUDA 12.9.
RUN /opt/venv/bin/python -m pip install --no-cache-dir \
    'torch==2.8.0' --index-url https://download.pytorch.org/whl/cu129

COPY requirements.txt /tmp/requirements.txt
RUN /opt/venv/bin/python -m pip install --no-cache-dir -r /tmp/requirements.txt \
    && /opt/venv/bin/python -c 'import torch, transformers, accelerate, bitsandbytes; print("torch", torch.__version__, "CUDA", torch.version.cuda, "transformers", transformers.__version__)' \
    && rm -f /tmp/requirements.txt

# Only public-key SSH authentication is permitted; no keys are baked into the image.
RUN groupadd --system llmstudents \
    && for n in 01 02 03 04; do \
         useradd -M -d "/home/student${n}" -s /bin/bash -g llmstudents "student${n}"; \
         ln -s "/workspace/students/student${n}" "/home/student${n}"; \
       done \
    && mkdir -p /run/sshd \
    && printf '\nPasswordAuthentication no\nKbdInteractiveAuthentication no\nPubkeyAuthentication yes\nPermitRootLogin prohibit-password\nAllowUsers root student01 student02 student03 student04\n' > /etc/ssh/sshd_config.d/99-runpod-llm.conf

COPY start.sh /usr/local/bin/start.sh
RUN chmod 755 /usr/local/bin/start.sh

EXPOSE 22
WORKDIR /workspace
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/start.sh"]
