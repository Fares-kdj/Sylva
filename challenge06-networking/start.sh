#!/bin/bash

# ============================================================
#  SYLVA-LAB – Challenge 6: Networking Between 5G Functions
#  AMF ↔ SMF communication via Kubernetes DNS
# ============================================================

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'
CLUSTER_NAME="sylva-lab"; NAMESPACE="nf-network"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  SYLVA-LAB – Challenge 06: NF Networking (AMF ↔ SMF)${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}[1/4] Checking cluster...${NC}"
kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$" || \
  { echo -e "${RED}  ✗ Cluster not found. Run ../start-cluster.sh${NC}"; exit 1; }
echo -e "${GREEN}  ✓ Cluster running${NC}"

echo ""
echo -e "${YELLOW}[2/4] Deploying AMF and SMF in namespace nf-network...${NC}"
kubectl apply -f "${SCRIPT_DIR}/manifests/nf-network.yaml" >/dev/null
echo -e "${GREEN}  ✓ Namespace, AMF, SMF deployed${NC}"

echo ""
echo -e "${YELLOW}[3/4] Waiting for NF pods...${NC}"
echo -n "  Waiting"
for i in $(seq 1 60); do
  READY=$(kubectl get pods -n "${NAMESPACE}" --no-headers 2>/dev/null | grep -c "Running" || echo 0)
  [ "$READY" -ge 2 ] && { echo -e " ${GREEN}✓${NC}"; break; }
  echo -n "."; sleep 3
done
kubectl get pods -n "${NAMESPACE}" -o wide

echo ""
echo -e "${YELLOW}[4/4] Verifying inter-NF communication...${NC}"
sleep 3
AMF_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 \
  http://localhost:8101/health 2>/dev/null || echo "000")
SMF_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 \
  http://localhost:8102/health 2>/dev/null || echo "000")
[ "$AMF_HEALTH" = "200" ] && echo -e "${GREEN}  ✓ AMF UP → http://localhost:8101${NC}" \
  || echo -e "${YELLOW}  ⚠ AMF not yet ready (HTTP $AMF_HEALTH)${NC}"
[ "$SMF_HEALTH" = "200" ] && echo -e "${GREEN}  ✓ SMF UP → http://localhost:8102${NC}" \
  || echo -e "${YELLOW}  ⚠ SMF not yet ready (HTTP $SMF_HEALTH)${NC}"

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅  NF Networking sandbox ready!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  📡 AMF API → ${CYAN}http://localhost:8101${NC}"
echo -e "  📡 SMF API → ${CYAN}http://localhost:8102${NC}"
echo -e "  📋 Run ${YELLOW}./test.sh${NC} | 📚 Open ${YELLOW}README.md${NC}"
echo ""
