#!/bin/bash

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'
NAMESPACE="nf-network"; PASS=0; FAIL=0

echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  SYLVA-LAB – Challenge 06: NF Networking – Tests${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""

ok()   { echo -e "  ${GREEN}✓ PASS${NC} – $1"; PASS=$((PASS+1)); }
fail() { echo -e "  ${RED}✗ FAIL${NC} – $1"; FAIL=$((FAIL+1)); }
info() { echo -e "  ${YELLOW}ℹ${NC}  $1"; }

echo -e "${YELLOW}[TEST 1] AMF pod running${NC}"
[ "$(kubectl get pods -n $NAMESPACE -l app=amf --no-headers 2>/dev/null | grep -c Running)" -ge 1 ] \
  && ok "AMF Running" || fail "AMF not running"

echo ""; echo -e "${YELLOW}[TEST 2] SMF pod running${NC}"
[ "$(kubectl get pods -n $NAMESPACE -l app=smf --no-headers 2>/dev/null | grep -c Running)" -ge 1 ] \
  && ok "SMF Running" || fail "SMF not running"

echo ""; echo -e "${YELLOW}[TEST 3] AMF health endpoint${NC}"
CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost:8101/health 2>/dev/null || echo "000")
[ "$CODE" = "200" ] && ok "AMF health HTTP 200" || fail "AMF health (HTTP $CODE)"

echo ""; echo -e "${YELLOW}[TEST 4] SMF health endpoint${NC}"
CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost:8102/health 2>/dev/null || echo "000")
[ "$CODE" = "200" ] && ok "SMF health HTTP 200" || fail "SMF health (HTTP $CODE)"

echo ""; echo -e "${YELLOW}[TEST 5] AMF → SMF inter-NF call (PDU session trigger)${NC}"
RESP=$(curl -s --max-time 10 -X POST http://localhost:8101/namf-comm/v1/pdu-sessions \
  -H "Content-Type: application/json" \
  -d '{"supi":"imsi-208930000000001","dnn":"internet","pduSessionId":1}' 2>/dev/null || echo "{}")
SMF_REF=$(echo "$RESP" | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(d.get('smfResponse',{}).get('smContextRef',''))" 2>/dev/null || echo "")
[ -n "$SMF_REF" ] \
  && ok "AMF called SMF – smContextRef: ${SMF_REF}" \
  || fail "AMF → SMF call failed"
info "interNfCall: $(echo $RESP | python3 -c "import sys,json; print(json.load(sys.stdin).get('interNfCall',''))" 2>/dev/null)"

echo ""; echo -e "${YELLOW}[TEST 6] SMF session created directly${NC}"
RESP=$(curl -s --max-time 5 -X POST http://localhost:8102/nsmf-pdusession/v1/sm-contexts \
  -H "Content-Type: application/json" \
  -d '{"supi":"imsi-208930000000002","dnn":"ims","pduSessionId":2}' 2>/dev/null || echo "{}")
REF=$(echo "$RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('smContextRef',''))" 2>/dev/null || echo "")
[ -n "$REF" ] && ok "SMF session created – ref: ${REF}" || fail "SMF session creation failed"

echo ""; echo -e "${YELLOW}[TEST 7] Kubernetes DNS resolves SMF service${NC}"
AMF_POD=$(kubectl get pod -n $NAMESPACE -l app=amf -o name 2>/dev/null | head -1)
if [ -n "$AMF_POD" ]; then
  DNS_OK=$(kubectl exec -n $NAMESPACE "$AMF_POD" -- \
    wget -qO- http://smf.nf-network.svc.cluster.local:8080/health 2>/dev/null | grep -c "UP" || echo 0)
  [ "$DNS_OK" -ge 1 ] \
    && ok "AMF pod resolves smf.nf-network.svc.cluster.local" \
    || fail "DNS resolution failed inside cluster"
else
  fail "No AMF pod found"
fi

echo ""; echo -e "${YELLOW}[TEST 8] Both NFs on core node${NC}"
AMF_NODE=$(kubectl get pod -n $NAMESPACE -l app=amf -o jsonpath='{.items[0].spec.nodeName}' 2>/dev/null)
SMF_NODE=$(kubectl get pod -n $NAMESPACE -l app=smf -o jsonpath='{.items[0].spec.nodeName}' 2>/dev/null)
AMF_SITE=$(kubectl get node "$AMF_NODE" -o jsonpath='{.metadata.labels.sylva-site}' 2>/dev/null)
SMF_SITE=$(kubectl get node "$SMF_NODE" -o jsonpath='{.metadata.labels.sylva-site}' 2>/dev/null)
[ "$AMF_SITE" = "core" ] && [ "$SMF_SITE" = "core" ] \
  && ok "Both AMF and SMF running on core node" \
  || fail "Unexpected placement (AMF site=$AMF_SITE, SMF site=$SMF_SITE)"

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
TOTAL=$((PASS+FAIL))
[ "$FAIL" -eq 0 ] \
  && echo -e "${GREEN}  ✅  All ${TOTAL} tests passed!${NC}" \
  || echo -e "${YELLOW}  ⚠️  ${PASS}/${TOTAL} passed.${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""
