#!/bin/bash

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'
NAMESPACE="nf-security"; PASS=0; FAIL=0

echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  SYLVA-LAB – Challenge 07: Security – Tests${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""

ok()   { echo -e "  ${GREEN}✓ PASS${NC} – $1"; PASS=$((PASS+1)); }
fail() { echo -e "  ${RED}✗ FAIL${NC} – $1"; FAIL=$((FAIL+1)); }
info() { echo -e "  ${YELLOW}ℹ${NC}  $1"; }

echo -e "${YELLOW}[TEST 1] ServiceAccount amf-sa exists${NC}"
kubectl get serviceaccount amf-sa -n $NAMESPACE >/dev/null 2>&1 \
  && ok "ServiceAccount 'amf-sa' exists" || fail "amf-sa not found"

echo ""; echo -e "${YELLOW}[TEST 2] ServiceAccount smf-sa exists${NC}"
kubectl get serviceaccount smf-sa -n $NAMESPACE >/dev/null 2>&1 \
  && ok "ServiceAccount 'smf-sa' exists" || fail "smf-sa not found"

echo ""; echo -e "${YELLOW}[TEST 3] RBAC Role amf-role exists${NC}"
kubectl get role amf-role -n $NAMESPACE >/dev/null 2>&1 \
  && ok "Role 'amf-role' exists" || fail "amf-role not found"

echo ""; echo -e "${YELLOW}[TEST 4] Secret amf-credentials exists${NC}"
kubectl get secret amf-credentials -n $NAMESPACE >/dev/null 2>&1 \
  && ok "Secret 'amf-credentials' exists" || fail "Secret not found"

echo ""; echo -e "${YELLOW}[TEST 5] Secret mounted in AMF pod${NC}"
AMF_POD=$(kubectl get pod -n $NAMESPACE -l app=amf -o name 2>/dev/null | head -1)
if [ -n "$AMF_POD" ]; then
  HAS_SECRET=$(kubectl exec -n $NAMESPACE "$AMF_POD" -- \
    ls /secrets/ 2>/dev/null | grep -c "plmn-id" || echo 0)
  [ "$HAS_SECRET" -ge 1 ] \
    && ok "Secret mounted at /secrets/plmn-id" \
    || fail "Secret not mounted in AMF pod"
else
  fail "No AMF pod found"
fi

echo ""; echo -e "${YELLOW}[TEST 6] AMF pod uses amf-sa ServiceAccount${NC}"
SA=$(kubectl get pod -n $NAMESPACE -l app=amf \
  -o jsonpath='{.items[0].spec.serviceAccountName}' 2>/dev/null)
[ "$SA" = "amf-sa" ] \
  && ok "AMF pod uses ServiceAccount 'amf-sa'" \
  || fail "AMF uses SA '$SA' (expected amf-sa)"

echo ""; echo -e "${YELLOW}[TEST 7] NetworkPolicy default-deny-ingress exists${NC}"
kubectl get networkpolicy default-deny-ingress -n $NAMESPACE >/dev/null 2>&1 \
  && ok "NetworkPolicy 'default-deny-ingress' exists" \
  || fail "NetworkPolicy not found"

echo ""; echo -e "${YELLOW}[TEST 8] AMF loads secret from mounted volume${NC}"
if [ -n "$AMF_POD" ]; then
  RESP=$(kubectl exec -n $NAMESPACE "$AMF_POD" -- \
    wget -qO- http://localhost:8080/health 2>/dev/null || echo "{}")
  SECRET_OK=$(echo "$RESP" | python3 -c \
    "import sys,json; print(json.load(sys.stdin).get('secretLoaded','false'))" 2>/dev/null || echo "false")
  [ "$SECRET_OK" = "True" ] \
    && ok "AMF reports secret loaded from /secrets" \
    || fail "AMF did not load secret (response: $RESP)"
fi

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
TOTAL=$((PASS+FAIL))
[ "$FAIL" -eq 0 ] \
  && echo -e "${GREEN}  ✅  All ${TOTAL} tests passed!${NC}" \
  || echo -e "${YELLOW}  ⚠️  ${PASS}/${TOTAL} passed.${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""
