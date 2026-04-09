#!/bin/bash

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'
PASS=0; FAIL=0

echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  SYLVA-LAB – Challenge 04: GitOps Argo CD – Tests${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""

ok()   { echo -e "  ${GREEN}✓ PASS${NC} – $1"; PASS=$((PASS+1)); }
fail() { echo -e "  ${RED}✗ FAIL${NC} – $1"; FAIL=$((FAIL+1)); }
info() { echo -e "  ${YELLOW}ℹ${NC}  $1"; }

echo -e "${YELLOW}[TEST 1] Argo CD namespace exists${NC}"
kubectl get namespace argocd >/dev/null 2>&1 \
  && ok "Namespace 'argocd' exists" || fail "Namespace missing"

echo ""; echo -e "${YELLOW}[TEST 2] Argo CD server pod running${NC}"
PODS=$(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server \
  --no-headers 2>/dev/null | grep -c "Running" || echo 0)
[ "$PODS" -ge 1 ] && ok "argocd-server pod Running" || fail "argocd-server not running"

echo ""; echo -e "${YELLOW}[TEST 3] Argo CD UI reachable${NC}"
CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 \
  http://localhost:8080 2>/dev/null || echo "000")
[[ "$CODE" =~ ^(200|301|302)$ ]] \
  && ok "Argo CD UI reachable (HTTP $CODE)" \
  || fail "Argo CD UI not reachable (HTTP $CODE)"

echo ""; echo -e "${YELLOW}[TEST 4] Argo CD Application 'amf-nf' created${NC}"
kubectl get application amf-nf -n argocd >/dev/null 2>&1 \
  && ok "Application 'amf-nf' exists in Argo CD" \
  || fail "Application 'amf-nf' not found"

echo ""; echo -e "${YELLOW}[TEST 5] Argo CD repo-server running${NC}"
PODS=$(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-repo-server \
  --no-headers 2>/dev/null | grep -c "Running" || echo 0)
[ "$PODS" -ge 1 ] && ok "argocd-repo-server Running" || fail "argocd-repo-server not running"

echo ""; echo -e "${YELLOW}[TEST 6] Argo CD application-controller running${NC}"
PODS=$(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-application-controller \
  --no-headers 2>/dev/null | grep -c "Running" || echo 0)
[ "$PODS" -ge 1 ] && ok "argocd-application-controller Running" || fail "Controller not running"

echo ""; echo -e "${YELLOW}[TEST 7] Admin secret exists${NC}"
kubectl get secret argocd-initial-admin-secret -n argocd >/dev/null 2>&1 \
  && ok "Admin secret exists" || fail "Admin secret not found"

echo ""; echo -e "${YELLOW}[TEST 8] Argo CD service is NodePort${NC}"
SVC_TYPE=$(kubectl get svc argocd-server -n argocd \
  -o jsonpath='{.spec.type}' 2>/dev/null)
[ "$SVC_TYPE" = "NodePort" ] \
  && ok "argocd-server is NodePort" \
  || fail "argocd-server type is '$SVC_TYPE' (expected NodePort)"

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
TOTAL=$((PASS+FAIL))
[ "$FAIL" -eq 0 ] \
  && echo -e "${GREEN}  ✅  All ${TOTAL} tests passed!${NC}" \
  || echo -e "${YELLOW}  ⚠️  ${PASS}/${TOTAL} passed.${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""
