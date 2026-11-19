#!/usr/bin/env bash
set -Eeuo pipefail

mkdir -p /run/sshd /workspace/hf-cache/hub /workspace/students
chmod 755 /workspace/students

# Only use public keys supplied at Pod startup. Never store private keys in GitHub.
if [[ -n "${PUBLIC_KEY:-}" || -n "${SSH_PUBLIC_KEY:-}" ]]; then
  install -d -m 700 /root/.ssh
  { [[ -z "${PUBLIC_KEY:-}" ]] || printf '%s\n' "$PUBLIC_KEY"; \
    [[ -z "${SSH_PUBLIC_KEY:-}" ]] || printf '%s\n' "$SSH_PUBLIC_KEY"; } > /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
fi

for n in 01 02 03 04; do
  account="student${n}"
  home="/workspace/students/${account}"
  install -d -m 700 -o "$account" -g llmstudents "$home"
  install -d -m 700 -o "$account" -g llmstudents "$home/.ssh"

  # Set a different student public key in each Pod's environment settings.
  var="STUDENT${n}_PUBKEY"
  if [[ -n "${!var:-}" ]]; then
    printf '%s\n' "${!var}" > "$home/.ssh/authorized_keys"
    chown "$account":llmstudents "$home/.ssh/authorized_keys"
    chmod 600 "$home/.ssh/authorized_keys"
  fi
  # Students own their work in /workspace/students/... (persistent Pod storage).
  chown "$account":llmstudents "$home"
done

# Model weights are downloaded to /workspace/hf-cache/hub by the instructor.
# Do not set HF_HOME globally; students' Hugging Face tokens remain private.
chmod 755 /workspace/hf-cache /workspace/hf-cache/hub

ssh-keygen -A
/usr/sbin/sshd -t
exec /usr/sbin/sshd -D -e
