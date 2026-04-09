#!/bin/bash

# ============================================================
#  SYLVA-LAB – Stop / Cleanup Script
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

CLUSTER_NAME="sylva-lab"

echo -e "${CYAN}"
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║   SYLVA-LAB – Stop & Cleanup                     ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}Current state:${NC}"
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo -e "  ${GREEN}✓ Cluster '${CLUSTER_NAME}' is running${NC}"
  echo ""
  declare -A NS_LABELS=(
    [nf-5g]="CH02 – 5G NF mock"
    [argocd]="CH04 – Argo CD GitOps"
    [monitoring]="CH05 – Prometheus + Grafana"
    [nf-network]="CH06 – NF Networking"
    [nf-security]="CH07 – RBAC Security"
    [nf-e2e]="CH08 – End-to-End 5G Core"
  )
  for NS in nf-5g argocd monitoring nf-network nf-security nf-e2e; do
    if kubectl get namespace "$NS" >/dev/null 2>&1; then
      PODS=$(kubectl get pods -n "$NS" --no-headers 2>/dev/null | grep -c "Running" || echo 0)
      echo -e "    ${GREEN}●${NC} ${NS_LABELS[$NS]}  (${PODS} pods running)"
    fi
  done
else
  echo -e "  ${RED}✗ Cluster '${CLUSTER_NAME}' is not running${NC}"
  exit 0
fi

echo ""
echo -e "${YELLOW}What do you want to stop?${NC}"
echo ""
echo -e "  ${GREEN}1)${NC} Stop Challenge 02 only     (nf-5g)"
echo -e "  ${GREEN}2)${NC} Stop Challenge 04 only     (argocd)"
echo -e "  ${GREEN}3)${NC} Stop Challenge 05 only     (monitoring)"
echo -e "  ${GREEN}4)${NC} Stop Challenge 06 only     (nf-network)"
echo -e "  ${GREEN}5)${NC} Stop Challenge 07 only     (nf-security)"
echo -e "  ${GREEN}6)${NC} Stop Challenge 08 only     (nf-e2e)"
echo -e "  ${GREEN}7)${NC} Stop all challenges        (all namespaces)"
echo -e "  ${RED}8)${NC} Delete entire cluster      (full cleanup)"
echo ""
read -rp "  Your choice [1-8]: " CHOICE

case "$CHOICE" in
  1) kubectl delete namespace nf-5g       --ignore-not-found=true ;;
  2) kubectl delete namespace argocd      --ignore-not-found=true ;;
  3) kubectl delete namespace monitoring  --ignore-not-found=true ;;
  4) kubectl delete namespace nf-network  --ignore-not-found=true ;;
  5) kubectl delete namespace nf-security --ignore-not-found=true ;;
  6) kubectl delete namespace nf-e2e      --ignore-not-found=true ;;
  7)
    kubectl delete namespace nf-5g argocd monitoring nf-network nf-security nf-e2e \
      --ignore-not-found=true
    echo -e "${GREEN}  ✓ All namespaces removed. Cluster still running.${NC}"
    ;;
  8)
    kind delete cluster --name "${CLUSTER_NAME}" 2>/dev/null && \
      echo -e "${GREEN}  ✓ Cluster deleted.${NC}" || \
      echo -e "${YELLOW}  ⚠ Cluster not found.${NC}"
    docker system prune -f >/dev/null
    echo -e "${GREEN}  ✓ Docker pruned.${NC}"
    echo -e "  Fresh start: ${YELLOW}./start-cluster.sh${NC}"
    ;;
  *) echo -e "${RED}Invalid choice.${NC}"; exit 1 ;;
esac
echo ""
