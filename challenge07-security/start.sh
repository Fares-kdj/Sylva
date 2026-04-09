#!/bin/bash

# ============================================================
#  SYLVA-LAB – Challenge 7: Security and Isolation in Telco
#  RBAC, NetworkPolicy, Secrets
# ============================================================

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'
CLUSTER_NAME="sylva-lab"; NAMESPACE="nf-security"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  SYLVA-LAB – Challenge 07: Security and Isolation${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}[1/4] Checking cluster...${NC}"
kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$" || \
  { echo -e "${RED}  ✗ Cluster not found.${NC}"; exit 1; }
echo -e "${GREEN}  ✓ Cluster running${NC}"

echo ""
echo -e "${YELLOW}[2/4] Deploying RBAC + NetworkPolicy + Secrets...${NC}"
kubectl apply -f "${SCRIPT_DIR}/manifests/nf-security.yaml" >/dev/null
echo -e "${GREEN}  ✓ ServiceAccounts, Roles, Secrets, NetworkPolicies applied${NC}"

echo ""
echo -e "${YELLOW}[3/4] Waiting for AMF pod...${NC}"
echo -n "  Waiting"
for i in $(seq 1 60); do
  READY=$(kubectl get pods -n "${NAMESPACE}" -l app=amf --no-headers 2>/dev/null | grep -c "Running" || echo 0)
  [ "$READY" -ge 1 ] && { echo -e " ${GREEN}✓${NC}"; break; }
  echo -n "."; sleep 3
done
kubectl get pods -n "${NAMESPACE}"

echo ""
echo -e "${YELLOW}[4/4] Summary of security objects...${NC}"
echo "  ServiceAccounts:"
kubectl get serviceaccounts -n "${NAMESPACE}" --no-headers 2>/dev/null | grep -v "default" | awk '{print "    "$1}'
echo "  Roles:"
kubectl get roles -n "${NAMESPACE}" --no-headers 2>/dev/null | awk '{print "    "$1}'
echo "  Secrets:"
kubectl get secrets -n "${NAMESPACE}" --no-headers 2>/dev/null | grep -v "service-account" | awk '{print "    "$1}'
echo "  NetworkPolicies:"
kubectl get networkpolicies -n "${NAMESPACE}" --no-headers 2>/dev/null | awk '{print "    "$1}'

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅  Security sandbox ready!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  📋 Run ${YELLOW}./test.sh${NC} | 📚 Open ${YELLOW}README.md${NC}"
echo ""
