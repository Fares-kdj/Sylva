#!/bin/bash

# ============================================================
#  SYLVA-LAB – Challenge 2: Kubernetes Fundamentals (Telco View)
#  Deploy AMF mock as a 5G Network Function
# ============================================================

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

CLUSTER_NAME="sylva-lab"
NAMESPACE="nf-5g"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  SYLVA-LAB – Challenge 02: Kubernetes Fundamentals${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}[1/4] Checking cluster...${NC}"
kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$" || \
  { echo -e "${RED}  ✗ Cluster not found. Run ../start-cluster.sh${NC}"; exit 1; }
echo -e "${GREEN}  ✓ Cluster '${CLUSTER_NAME}' running${NC}"

echo ""
echo -e "${YELLOW}[2/4] Deploying AMF mock (5G Network Function)...${NC}"
kubectl apply -f "${SCRIPT_DIR}/manifests/amf-mock.yaml" >/dev/null
echo -e "${GREEN}  ✓ AMF Namespace, Deployment and Service applied${NC}"

echo ""
echo -e "${YELLOW}[3/4] Waiting for AMF pod to be ready...${NC}"
echo -n "  Waiting"
for i in $(seq 1 60); do
  READY=$(kubectl get pods -n "${NAMESPACE}" -l app=amf --no-headers 2>/dev/null | grep -c "Running" || echo 0)
  [ "$READY" -ge 1 ] && { echo -e " ${GREEN}✓${NC}"; break; }
  echo -n "."; sleep 3
done

kubectl get pods -n "${NAMESPACE}" -o wide

echo ""
echo -e "${YELLOW}[4/4] Verifying AMF health endpoint...${NC}"
sleep 2
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 \
  http://localhost:8002/health 2>/dev/null || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
  echo -e "${GREEN}  ✓ AMF is UP at http://localhost:8002${NC}"
  curl -s http://localhost:8002/health | python3 -m json.tool 2>/dev/null \
    || curl -s http://localhost:8002/health
else
  echo -e "${YELLOW}  ⚠ AMF not yet reachable (HTTP ${HTTP_CODE}) – try again in a moment${NC}"
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅  AMF mock deployed on core worker node!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  📡 AMF API → ${CYAN}http://localhost:8002${NC}"
echo -e "  📋 Run ${YELLOW}./test.sh${NC} to validate"
echo -e "  📚 Open ${YELLOW}README.md${NC} for the challenge guide"
echo ""
