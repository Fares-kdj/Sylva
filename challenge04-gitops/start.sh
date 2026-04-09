#!/bin/bash

# ============================================================
#  SYLVA-LAB – Challenge 4: GitOps Deployment with Argo CD
#  Installs real Argo CD + deploys AMF/SMF via GitOps
# ============================================================

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

CLUSTER_NAME="sylva-lab"
ARGOCD_NS="argocd"
ARGOCD_VERSION="v2.10.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  SYLVA-LAB – Challenge 04: GitOps with Argo CD${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}[1/6] Checking cluster...${NC}"
kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$" || \
  { echo -e "${RED}  ✗ Cluster not found. Run ../start-cluster.sh${NC}"; exit 1; }
echo -e "${GREEN}  ✓ Cluster running${NC}"

echo ""
echo -e "${YELLOW}[2/6] Installing Argo CD ${ARGOCD_VERSION}...${NC}"

kubectl create namespace "${ARGOCD_NS}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null

if kubectl get deployment argocd-server -n "${ARGOCD_NS}" >/dev/null 2>&1; then
  echo -e "${GREEN}  ✓ Argo CD already installed – skipping.${NC}"
else
  echo "  → Applying Argo CD manifests..."
  kubectl apply -n "${ARGOCD_NS}" \
    -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml" \
    >/dev/null
  echo -e "${GREEN}  ✓ Argo CD manifests applied.${NC}"
fi

echo ""
echo -e "${YELLOW}[3/6] Waiting for Argo CD to be ready...${NC}"
echo -n "  Waiting for argocd-server"
for i in $(seq 1 60); do
  READY=$(kubectl get pods -n "${ARGOCD_NS}" -l app.kubernetes.io/name=argocd-server \
    --no-headers 2>/dev/null | grep -c "Running" || echo 0)
  [ "$READY" -ge 1 ] && { echo -e " ${GREEN}✓${NC}"; break; }
  echo -n "."; sleep 5
done

echo ""
echo -e "${YELLOW}[4/6] Exposing Argo CD UI via NodePort...${NC}"
kubectl patch svc argocd-server -n "${ARGOCD_NS}" \
  -p '{"spec":{"type":"NodePort","ports":[{"port":80,"targetPort":8080,"nodePort":30080,"name":"http"}]}}' \
  >/dev/null 2>&1 || true
echo -e "${GREEN}  ✓ Argo CD UI → http://localhost:8080${NC}"

echo ""
echo -e "${YELLOW}[5/6] Getting initial admin password...${NC}"
sleep 3
ARGOCD_PASS=$(kubectl -n "${ARGOCD_NS}" get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null || echo "")

if [ -n "$ARGOCD_PASS" ]; then
  echo -e "${GREEN}  ✓ Admin password retrieved${NC}"
  echo -e "${CYAN}  Username: admin${NC}"
  echo -e "${CYAN}  Password: ${ARGOCD_PASS}${NC}"
  echo "$ARGOCD_PASS" > "${SCRIPT_DIR}/argocd-admin-password.txt"
  echo -e "${YELLOW}  (saved to argocd-admin-password.txt)${NC}"
else
  echo -e "${YELLOW}  ⚠ Password not yet available – run: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d${NC}"
fi

echo ""
echo -e "${YELLOW}[6/6] Creating Argo CD Application for AMF NF...${NC}"
kubectl apply -f "${SCRIPT_DIR}/manifests/argocd-nf-app.yaml" >/dev/null
echo -e "${GREEN}  ✓ Argo CD Application 'amf-nf' created${NC}"

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅  Argo CD installed and AMF GitOps App created!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  🌐 Argo CD UI  → ${CYAN}http://localhost:8080${NC}"
echo -e "  👤 Username    → ${CYAN}admin${NC}"
echo -e "  🔑 Password    → ${CYAN}$(cat ${SCRIPT_DIR}/argocd-admin-password.txt 2>/dev/null || echo 'see argocd-admin-password.txt')${NC}"
echo ""
echo -e "  📋 Run ${YELLOW}./test.sh${NC} to validate"
echo -e "  📚 Open ${YELLOW}README.md${NC} for the challenge guide"
echo ""
