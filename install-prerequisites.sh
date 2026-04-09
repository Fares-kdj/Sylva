#!/bin/bash

# ============================================================
#  SYLVA-LAB – Prerequisites Installer
#  Docker, Kind, kubectl, Helm, Git, jq, curl
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║   SYLVA-LAB – Prerequisites Installer        ║"
echo "  ╚══════════════════════════════════════════════╝"
echo -e "${NC}"

install_if_missing() {
  local TOOL="$1"; local CMD="$2"
  if command -v "$TOOL" &>/dev/null; then
    echo -e "${GREEN}  ✓ $TOOL already installed${NC}"
  else
    echo -e "${YELLOW}  → Installing $TOOL...${NC}"
    eval "$CMD"
    echo -e "${GREEN}  ✓ $TOOL installed${NC}"
  fi
}

install_if_missing docker "
  sudo apt-get update -qq
  sudo apt-get install -y ca-certificates curl gnupg lsb-release
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -qq
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
  sudo usermod -aG docker \$USER
  echo -e '${YELLOW}  ⚠ Docker group added. Run: newgrp docker${NC}'
"

install_if_missing kind "
  KIND_VERSION=\$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest \
    | grep tag_name | cut -d'\"' -f4)
  curl -Lo /tmp/kind https://kind.sigs.k8s.io/dl/\${KIND_VERSION}/kind-linux-amd64
  chmod +x /tmp/kind && sudo mv /tmp/kind /usr/local/bin/kind
"

install_if_missing kubectl "
  KUBECTL_VERSION=\$(curl -s https://dl.k8s.io/release/stable.txt)
  curl -Lo /tmp/kubectl https://dl.k8s.io/release/\${KUBECTL_VERSION}/bin/linux/amd64/kubectl
  chmod +x /tmp/kubectl && sudo mv /tmp/kubectl /usr/local/bin/kubectl
"

install_if_missing helm "
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
"

install_if_missing git "sudo apt-get install -y git"
install_if_missing jq  "sudo apt-get install -y jq"
install_if_missing curl "sudo apt-get install -y curl"

echo ""
echo -e "${CYAN}  Verification:${NC}"
for tool in docker kind kubectl helm git jq curl; do
  command -v "$tool" &>/dev/null \
    && echo -e "${GREEN}  ✓ $tool OK${NC}" \
    || echo -e "${RED}  ✗ $tool FAILED${NC}"
done

echo ""
echo -e "${GREEN}  ✅  Prerequisites ready!${NC}"
echo -e "  Next: ${YELLOW}./start-cluster.sh${NC}"
echo ""
