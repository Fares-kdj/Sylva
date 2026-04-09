#!/bin/bash

# ============================================================
#  SYLVA-LAB – Start Shared Cluster
#  Kind cluster avec 1 control-plane + 2 workers (edge + core)
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

CLUSTER_NAME="sylva-lab"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}"
echo "  ███████╗██╗   ██╗██╗    ██╗   ██╗ █████╗      ██╗      █████╗ ██████╗ "
echo "  ██╔════╝╚██╗ ██╔╝██║    ██║   ██║██╔══██╗     ██║     ██╔══██╗██╔══██╗"
echo "  ███████╗ ╚████╔╝ ██║    ██║   ██║███████║     ██║     ███████║██████╔╝"
echo "  ╚════██║  ╚██╔╝  ██║    ╚██╗ ██╔╝██╔══██║     ██║     ██╔══██║██╔══██╗"
echo "  ███████║   ██║   ███████╗╚████╔╝ ██║  ██║     ███████╗██║  ██║██████╔╝"
echo "  ╚══════╝   ╚═╝   ╚══════╝ ╚═══╝  ╚═╝  ╚═╝     ╚══════╝╚═╝  ╚═╝╚═════╝ "
echo -e "${NC}"
echo -e "${BLUE}  SYLVA-LAB – Getting Started with Sylva (Telco Context – 5G Inspired)${NC}"
echo ""

# ─── PREREQUISITES ────────────────────────────────────────────────────────────
echo -e "${YELLOW}[1/4] Checking prerequisites...${NC}"
for tool in docker kind kubectl helm git; do
  if ! command -v "$tool" &>/dev/null; then
    echo -e "${RED}  ✗ '$tool' not found. Run ./install-prerequisites.sh${NC}"; exit 1
  fi
  echo -e "${GREEN}  ✓ $tool${NC}"
done

AVAILABLE_MEM=$(free -m | awk '/^Mem:/{print $7}')
if [ "$AVAILABLE_MEM" -lt 5000 ]; then
  echo -e "${YELLOW}  ⚠ Memory: ${AVAILABLE_MEM}MB available. 6GB recommended for full lab.${NC}"
else
  echo -e "${GREEN}  ✓ Memory OK: ${AVAILABLE_MEM}MB${NC}"
fi

# ─── CLUSTER ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[2/4] Kind cluster '${CLUSTER_NAME}' (1 control-plane + 2 workers)...${NC}"

if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo -e "${GREEN}  ✓ Cluster already exists – reusing it.${NC}"
else
  echo "  → Creating cluster (this may take 2–3 minutes)..."
  kind create cluster \
    --name "${CLUSTER_NAME}" \
    --config "${SCRIPT_DIR}/kind-config.yaml" \
    --wait 120s
  echo -e "${GREEN}  ✓ Cluster '${CLUSTER_NAME}' created.${NC}"
fi

kubectl cluster-info --context "kind-${CLUSTER_NAME}" >/dev/null 2>&1
echo -e "${GREEN}  ✓ kubectl context: kind-${CLUSTER_NAME}${NC}"

# ─── NODE LABELS ──────────────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[3/4] Verifying node labels (edge / core)...${NC}"
kubectl get nodes --show-labels | grep -E "NAME|sylva-site" || true
EDGE_NODE=$(kubectl get nodes -l sylva-site=edge --no-headers 2>/dev/null | awk '{print $1}' | head -1)
CORE_NODE=$(kubectl get nodes -l sylva-site=core --no-headers 2>/dev/null | awk '{print $1}' | head -1)

if [ -n "$EDGE_NODE" ] && [ -n "$CORE_NODE" ]; then
  echo -e "${GREEN}  ✓ Edge node  : ${EDGE_NODE}${NC}"
  echo -e "${GREEN}  ✓ Core node  : ${CORE_NODE}${NC}"
else
  echo -e "${YELLOW}  ⚠ Labels not found – applying manually...${NC}"
  WORKERS=$(kubectl get nodes --no-headers | grep -v "control-plane" | awk '{print $1}')
  WORKER_ARR=($WORKERS)
  if [ ${#WORKER_ARR[@]} -ge 2 ]; then
    kubectl label node "${WORKER_ARR[0]}" sylva-site=edge  --overwrite >/dev/null
    kubectl label node "${WORKER_ARR[1]}" sylva-site=core  --overwrite >/dev/null
    echo -e "${GREEN}  ✓ Edge node  : ${WORKER_ARR[0]}${NC}"
    echo -e "${GREEN}  ✓ Core node  : ${WORKER_ARR[1]}${NC}"
  fi
fi

# ─── CLONE SYLVA ──────────────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[4/4] Cloning Sylva repository...${NC}"

SYLVA_DIR="${SCRIPT_DIR}/sylva-core"
if [ -d "$SYLVA_DIR/.git" ]; then
  # Check if we are on the right branch
  CURRENT_BRANCH=$(git -C "$SYLVA_DIR" branch --show-current)
  if [ "$CURRENT_BRANCH" != "release-1.6" ]; then
    echo -e "${YELLOW}  ⚠ sylva-core is on branch '$CURRENT_BRANCH', but we need 'release-1.6'. Re-cloning...${NC}"
    rm -rf "$SYLVA_DIR"
  else
    echo -e "${GREEN}  ✓ sylva-core (branch release-1.6) already cloned – pulling latest...${NC}"
    git -C "$SYLVA_DIR" pull origin release-1.6 --ff-only 2>/dev/null || \
      echo -e "${YELLOW}  ⚠ Could not pull (local changes?) – skipping update.${NC}"
  fi
fi

if [ ! -d "$SYLVA_DIR/.git" ]; then
  echo "  → Cloning gitlab.com/sylva-projects/sylva-core (branch: release-1.6)..."
  git clone --depth=1 -b release-1.6 https://gitlab.com/sylva-projects/sylva-core.git "$SYLVA_DIR" 2>&1 | tail -3
  echo -e "${GREEN}  ✓ sylva-core (release-1.6) cloned.${NC}"
fi

echo ""
echo "  Sylva repo structure:"
ls "$SYLVA_DIR" | awk '{print "    " $0}' | head -20

# ─── DONE ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅  SYLVA-LAB cluster is ready!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  Cluster   : ${CYAN}sylva-lab${NC}  (1 control-plane + edge worker + core worker)"
echo -e "  Sylva repo: ${CYAN}./sylva-core/${NC}"
echo ""
echo -e "  Start a challenge:"
echo -e "    ${YELLOW}cd challenge01-intro      && ./start.sh${NC}"
echo -e "    ${YELLOW}cd challenge02-kubernetes && ./start.sh${NC}"
echo -e "    ${YELLOW}cd challenge03-cluster    && ./start.sh${NC}"
echo -e "    ${YELLOW}cd challenge04-gitops     && ./start.sh${NC}"
echo -e "    ${YELLOW}cd challenge05-observability && ./start.sh${NC}"
echo -e "    ${YELLOW}cd challenge06-networking && ./start.sh${NC}"
echo -e "    ${YELLOW}cd challenge07-security   && ./start.sh${NC}"
echo -e "    ${YELLOW}cd challenge08-e2e        && ./start.sh${NC}"
echo ""
echo -e "  Stop/cleanup: ${YELLOW}./stop-lab.sh${NC}"
echo ""
