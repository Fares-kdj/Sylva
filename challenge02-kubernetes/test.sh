#!/bin/bash

# ============================================================
#  SYLVA-LAB – Challenge 2: Validation Script – 8 Tests
# ============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'

NAMESPACE="nf-5g"; PASS=0; FAIL=0

echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  SYLVA-LAB – Challenge 02: Kubernetes Fundamentals – Tests${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""

ok()   { echo -e "  ${GREEN}✓ PASS${NC} – $1"; PASS=$((PASS+1)); }
fail() { echo -e "  ${RED}✗ FAIL${NC} – $1"; FAIL=$((FAIL+1)); }
info() { echo -e "  ${YELLOW}ℹ${NC}  $1"; }

echo -e "${YELLOW}[TEST 1] Cluster running${NC}"
kind get clusters 2>/dev/null | grep -q "^sylva-lab$" \
  && ok "Cluster 'sylva-lab' exists" || fail "Cluster not found"

echo ""; echo -e "${YELLOW}[TEST 2] Namespace 'nf-5g' exists${NC}"
kubectl get namespace nf-5g >/dev/null 2>&1 \
  && ok "Namespace 'nf-5g' exists" || fail "Namespace not found"

echo ""; echo -e "${YELLOW}[TEST 3] AMF pod running${NC}"
PODS=$(kubectl get pods -n $NAMESPACE -l app=amf --no-headers 2>/dev/null | grep -c "Running" || echo 0)
[ "$PODS" -ge 1 ] && ok "AMF pod Running" || fail "AMF pod not Running"

echo ""; echo -e "${YELLOW}[TEST 4] AMF pod on core node${NC}"
NODE=$(kubectl get pod -n $NAMESPACE -l app=amf -o jsonpath='{.items[0].spec.nodeName}' 2>/dev/null)
SITE=$(kubectl get node "$NODE" -o jsonpath='{.metadata.labels.sylva-site}' 2>/dev/null)
[ "$SITE" = "core" ] \
  && ok "AMF running on core node ($NODE)" \
  || fail "AMF not on core node (site=$SITE, node=$NODE)"

echo ""; echo -e "${YELLOW}[TEST 5] AMF Service exists (NodePort)${NC}"
SVC_TYPE=$(kubectl get svc amf -n $NAMESPACE -o jsonpath='{.spec.type}' 2>/dev/null)
[ "$SVC_TYPE" = "NodePort" ] \
  && ok "AMF Service is NodePort" || fail "Service missing or wrong type"

echo ""; echo -e "${YELLOW}[TEST 6] AMF health endpoint reachable${NC}"
CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost:8002/health 2>/dev/null || echo "000")
[ "$CODE" = "200" ] && ok "AMF health returned HTTP 200" || fail "AMF health not reachable (HTTP $CODE)"

echo ""; echo -e "${YELLOW}[TEST 7] AMF NF info endpoint${NC}"
CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 \
  http://localhost:8002/namf-comm/v1/nf-info 2>/dev/null || echo "000")
[ "$CODE" = "200" ] && ok "AMF NF info returned HTTP 200" || fail "NF info not reachable (HTTP $CODE)"

echo ""; echo -e "${YELLOW}[TEST 8] Register a UE via AMF API${NC}"
RESP=$(curl -s --max-time 5 -X POST http://localhost:8002/namf-comm/v1/ue-registrations \
  -H "Content-Type: application/json" \
  -d '{"supi":"imsi-208930000000001","plmnId":{"mcc":"208","mnc":"93"}}' 2>/dev/null || echo "{}")
REG_ID=$(echo "$RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('registrationId',''))" 2>/dev/null || echo "")
[ -n "$REG_ID" ] \
  && ok "UE registered – registrationId: ${REG_ID}" \
  || fail "UE registration failed"
info "supi: imsi-208930000000001"

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
TOTAL=$((PASS+FAIL))
[ "$FAIL" -eq 0 ] \
  && echo -e "${GREEN}  ✅  All ${TOTAL} tests passed!${NC}" \
  || echo -e "${YELLOW}  ⚠️  ${PASS}/${TOTAL} tests passed.${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""
