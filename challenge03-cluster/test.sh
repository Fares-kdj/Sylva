#!/bin/bash

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'
PASS=0; FAIL=0

echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  SYLVA-LAB – Challenge 03: Cluster Setup – Tests${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""

ok()   { echo -e "  ${GREEN}✓ PASS${NC} – $1"; PASS=$((PASS+1)); }
fail() { echo -e "  ${RED}✗ FAIL${NC} – $1"; FAIL=$((FAIL+1)); }
info() { echo -e "  ${YELLOW}ℹ${NC}  $1"; }

echo -e "${YELLOW}[TEST 1] Cluster has 3 nodes${NC}"
COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
[ "$COUNT" -eq 3 ] && ok "3 nodes found (1 control-plane + 2 workers)" \
  || fail "Expected 3 nodes, found ${COUNT}"

echo ""; echo -e "${YELLOW}[TEST 2] Edge node labeled${NC}"
EDGE=$(kubectl get nodes -l sylva-site=edge --no-headers 2>/dev/null | wc -l)
[ "$EDGE" -ge 1 ] && ok "Edge node exists" || fail "No edge node found"
info "$(kubectl get nodes -l sylva-site=edge --no-headers 2>/dev/null | awk '{print $1}')"

echo ""; echo -e "${YELLOW}[TEST 3] Core node labeled${NC}"
CORE=$(kubectl get nodes -l sylva-site=core --no-headers 2>/dev/null | wc -l)
[ "$CORE" -ge 1 ] && ok "Core node exists" || fail "No core node found"
info "$(kubectl get nodes -l sylva-site=core --no-headers 2>/dev/null | awk '{print $1}')"

echo ""; echo -e "${YELLOW}[TEST 4] sylva-system namespace exists${NC}"
kubectl get namespace sylva-system >/dev/null 2>&1 \
  && ok "Namespace 'sylva-system' exists" || fail "Namespace missing"

echo ""; echo -e "${YELLOW}[TEST 5] nf-core namespace exists${NC}"
kubectl get namespace nf-core >/dev/null 2>&1 \
  && ok "Namespace 'nf-core' exists" || fail "Namespace missing"

echo ""; echo -e "${YELLOW}[TEST 6] nf-edge namespace exists${NC}"
kubectl get namespace nf-edge >/dev/null 2>&1 \
  && ok "Namespace 'nf-edge' exists" || fail "Namespace missing"

echo ""; echo -e "${YELLOW}[TEST 7] Namespaces have sylva-managed label${NC}"
COUNT=$(kubectl get namespaces -l sylva-managed=true --no-headers 2>/dev/null | wc -l)
[ "$COUNT" -ge 3 ] \
  && ok "${COUNT} Sylva-managed namespaces found" \
  || fail "Expected ≥3 sylva-managed namespaces, found ${COUNT}"

echo ""; echo -e "${YELLOW}[TEST 8] Sylva-core repo cloned${NC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -d "${SCRIPT_DIR}/../sylva-core/.git" ] \
  && ok "sylva-core repository found" \
  || fail "sylva-core not found – run ../start-cluster.sh"

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
TOTAL=$((PASS+FAIL))
[ "$FAIL" -eq 0 ] \
  && echo -e "${GREEN}  ✅  All ${TOTAL} tests passed!${NC}" \
  || echo -e "${YELLOW}  ⚠️  ${PASS}/${TOTAL} passed.${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""
