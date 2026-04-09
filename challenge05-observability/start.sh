#!/bin/bash

# ============================================================
#  SYLVA-LAB – Challenge 5: Observability for Network Functions
#  Installs Prometheus + Grafana via Helm kube-prometheus-stack
# ============================================================

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'

CLUSTER_NAME="sylva-lab"
NAMESPACE="monitoring"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  SYLVA-LAB – Challenge 05: Observability (Prometheus + Grafana)${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}[1/5] Checking cluster...${NC}"
kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$" || \
  { echo -e "${RED}  ✗ Cluster not found. Run ../start-cluster.sh${NC}"; exit 1; }
echo -e "${GREEN}  ✓ Cluster running${NC}"

echo ""
echo -e "${YELLOW}[2/5] Adding Prometheus Helm repo...${NC}"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update >/dev/null
echo -e "${GREEN}  ✓ Helm repos updated${NC}"

echo ""
echo -e "${YELLOW}[3/5] Installing kube-prometheus-stack...${NC}"
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null

if helm list -n "${NAMESPACE}" | grep -q "prometheus"; then
  echo -e "${GREEN}  ✓ Prometheus stack already installed.${NC}"
else
  echo "  → Installing (this takes 3–5 minutes)..."
  helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace "${NAMESPACE}" \
    --values "${SCRIPT_DIR}/prometheus-values.yaml" \
    --wait --timeout 8m \
    >/dev/null
  echo -e "${GREEN}  ✓ Prometheus stack installed.${NC}"
fi

echo ""
echo -e "${YELLOW}[4/5] Deploying NF metrics exporter (AMF metrics mock)...${NC}"
kubectl apply -f "${SCRIPT_DIR}/manifests/nf-metrics-mock.yaml" -n "${NAMESPACE}" >/dev/null
echo -e "${GREEN}  ✓ NF metrics mock deployed.${NC}"

echo ""
echo -e "${YELLOW}[5/5] Exposing Grafana via NodePort...${NC}"
kubectl patch svc prometheus-grafana -n "${NAMESPACE}" \
  -p '{"spec":{"type":"NodePort","ports":[{"port":80,"targetPort":3000,"nodePort":30030,"name":"http-web"}]}}' \
  >/dev/null 2>&1 || true
GRAFANA_PASS=$(kubectl get secret prometheus-grafana -n "${NAMESPACE}" \
  -o jsonpath="{.data.admin-password}" 2>/dev/null | base64 -d 2>/dev/null || echo "prom-operator")
echo -e "${GREEN}  ✓ Grafana → http://localhost:3030${NC}"

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅  Observability stack ready!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  📊 Grafana      → ${CYAN}http://localhost:3030${NC}"
echo -e "  👤 Username     → ${CYAN}admin${NC}"
echo -e "  🔑 Password     → ${CYAN}${GRAFANA_PASS}${NC}"
echo ""
echo -e "  📋 Run ${YELLOW}./test.sh${NC} to validate"
echo -e "  📚 Open ${YELLOW}README.md${NC} for the challenge guide"
echo ""
