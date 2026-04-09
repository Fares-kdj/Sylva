#!/bin/bash

# ============================================================
#  SYLVA-LAB – Challenge 3: Setting Up a Sylva-Compatible Cluster
#  Label nodes, validate cluster, explore Sylva cluster-templates
# ============================================================

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'

CLUSTER_NAME="sylva-lab"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYLVA_DIR="${SCRIPT_DIR}/../sylva-core"

echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  SYLVA-LAB – Challenge 03: Setting Up a Sylva Cluster${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}[1/4] Checking cluster...${NC}"
kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$" || \
  { echo -e "${RED}  ✗ Cluster not found. Run ../start-cluster.sh${NC}"; exit 1; }
echo -e "${GREEN}  ✓ Cluster '${CLUSTER_NAME}' running${NC}"
kubectl get nodes -o wide

echo ""
echo -e "${YELLOW}[2/4] Applying Sylva-compatible node labels...${NC}"

WORKERS=$(kubectl get nodes --no-headers | grep -v "control-plane" | awk '{print $1}')
WORKER_ARR=($WORKERS)

if [ ${#WORKER_ARR[@]} -ge 2 ]; then
  # Edge node
  kubectl label node "${WORKER_ARR[0]}" \
    sylva-site=edge \
    sylva-role=worker \
    topology.kubernetes.io/zone=edge-zone-1 \
    node-type=nf-worker \
    --overwrite >/dev/null
  echo -e "${GREEN}  ✓ Edge node: ${WORKER_ARR[0]}${NC}"

  # Core node
  kubectl label node "${WORKER_ARR[1]}" \
    sylva-site=core \
    sylva-role=worker \
    topology.kubernetes.io/zone=core-zone-1 \
    node-type=nf-worker \
    --overwrite >/dev/null
  echo -e "${GREEN}  ✓ Core node: ${WORKER_ARR[1]}${NC}"
fi

# Control plane labels
CP=$(kubectl get nodes --no-headers | grep "control-plane" | awk '{print $1}')
kubectl label node "$CP" \
  sylva-site=management \
  sylva-role=control-plane \
  --overwrite >/dev/null
echo -e "${GREEN}  ✓ Control-plane node: ${CP}${NC}"

echo ""
echo -e "${YELLOW}[3/4] Applying namespace structure (Sylva-inspired)...${NC}"

for NS_DEF in \
  "sylva-system|Sylva framework components" \
  "nf-core|5G Core Network Functions" \
  "nf-edge|5G Edge Network Functions" \
  "nf-ran|RAN-adjacent workloads"; do
  NS="${NS_DEF%%|*}"
  DESC="${NS_DEF##*|}"
  kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
  kubectl label namespace "$NS" sylva-managed=true description="$DESC" --overwrite >/dev/null
  echo -e "${GREEN}  ✓ Namespace: $NS${NC}"
done

echo ""
echo -e "${YELLOW}[4/4] Exploring Sylva cluster-templates...${NC}"

if [ -d "$SYLVA_DIR/cluster-templates" ]; then
  echo "  Available cluster templates:"
  ls "$SYLVA_DIR/cluster-templates" | awk '{print "    " $0}'
else
  echo -e "${YELLOW}  ⚠ sylva-core not found. Run ../start-cluster.sh first.${NC}"
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅  Sylva-compatible cluster configured!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  📋 Run ${YELLOW}./test.sh${NC} to validate"
echo -e "  📚 Open ${YELLOW}README.md${NC} for the challenge guide"
echo ""
