#!/bin/bash

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'
NAMESPACE="nf-e2e"; PASS=0; FAIL=0

echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  SYLVA-LAB – Challenge 08: E2E 5G Core – Tests${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""

ok()   { echo -e "  ${GREEN}✓ PASS${NC} – $1"; PASS=$((PASS+1)); }
fail() { echo -e "  ${RED}✗ FAIL${NC} – $1"; FAIL=$((FAIL+1)); }
info() { echo -e "  ${YELLOW}ℹ${NC}  $1"; }

echo -e "${YELLOW}[TEST 1] All 3 NF pods running${NC}"
COUNT=$(kubectl get pods -n $NAMESPACE --no-headers 2>/dev/null | grep -c "Running" || echo 0)
[ "$COUNT" -ge 3 ] && ok "${COUNT} NF pods Running (AMF + SMF + UPF)" \
  || fail "Expected ≥3 pods Running, found ${COUNT}"

echo ""; echo -e "${YELLOW}[TEST 2] AMF health${NC}"
CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost:8201/health 2>/dev/null || echo "000")
[ "$CODE" = "200" ] && ok "AMF health HTTP 200" || fail "AMF health (HTTP $CODE)"

echo ""; echo -e "${YELLOW}[TEST 3] SMF health${NC}"
CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost:8202/health 2>/dev/null || echo "000")
[ "$CODE" = "200" ] && ok "SMF health HTTP 200" || fail "SMF health (HTTP $CODE)"

echo ""; echo -e "${YELLOW}[TEST 4] UPF health${NC}"
CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost:8203/health 2>/dev/null || echo "000")
[ "$CODE" = "200" ] && ok "UPF health HTTP 200" || fail "UPF health (HTTP $CODE)"

echo ""; echo -e "${YELLOW}[TEST 5] Full E2E flow: AMF → SMF → UPF${NC}"
RESP=$(curl -s --max-time 15 -X POST \
  http://localhost:8201/namf-comm/v1/ue-complete-registration \
  -H "Content-Type: application/json" \
  -d '{"supi":"imsi-208930000000010","dnn":"internet"}' 2>/dev/null || echo "{}")
STEPS=$(echo "$RESP" | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(len(d.get('steps',[])))" 2>/dev/null || echo "0")
[ "$STEPS" -ge 3 ] \
  && ok "E2E flow completed with ${STEPS} steps" \
  || fail "E2E flow incomplete (${STEPS} steps)"
info "Flow: $(echo $RESP | python3 -c "import sys,json; print(json.load(sys.stdin).get('flow',''))" 2>/dev/null)"

echo ""; echo -e "${YELLOW}[TEST 6] UPF GTP-U tunnel was created${NC}"
UE_IP=$(echo "$RESP" | python3 -c \
  "import sys,json; d=json.load(sys.stdin); s=d.get('smfSession',{}); print(s.get('upfTunnel',{}).get('ueIpv4',''))" \
  2>/dev/null || echo "")
[ -n "$UE_IP" ] \
  && ok "UPF assigned UE IP: ${UE_IP}" \
  || fail "UPF did not assign UE IP"

echo ""; echo -e "${YELLOW}[TEST 7] UPF stats endpoint${NC}"
STATS=$(curl -s --max-time 5 http://localhost:8203/nupf-user/v1/stats 2>/dev/null || echo "{}")
TUNNELS=$(echo "$STATS" | python3 -c \
  "import sys,json; print(json.load(sys.stdin).get('activeTunnels',0))" 2>/dev/null || echo "0")
[ "$TUNNELS" -ge 1 ] \
  && ok "UPF has ${TUNNELS} active tunnel(s)" \
  || fail "UPF has no active tunnels"

echo ""; echo -e "${YELLOW}[TEST 8] SMF context list not empty${NC}"
SMF_LIST=$(curl -s --max-time 5 \
  http://localhost:8202/nsmf-pdusession/v1/sm-contexts 2>/dev/null || echo "[]")
COUNT=$(echo "$SMF_LIST" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")
[ "$COUNT" -ge 1 ] \
  && ok "SMF has ${COUNT} active session context(s)" \
  || fail "SMF has no active sessions"

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
TOTAL=$((PASS+FAIL))
if [ "$FAIL" -eq 0 ]; then
  echo -e "${GREEN}  ✅  All ${TOTAL} tests passed! 5G Core flow validated.${NC}"
  echo -e "${GREEN}  🎉 SYLVA-LAB complete!${NC}"
else
  echo -e "${YELLOW}  ⚠️  ${PASS}/${TOTAL} passed.${NC}"
fi
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""
