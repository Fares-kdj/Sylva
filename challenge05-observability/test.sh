#!/bin/bash

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'
PASS=0; FAIL=0

echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  SYLVA-LAB – Challenge 05: Observability – Tests${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""

ok()   { echo -e "  ${GREEN}✓ PASS${NC} – $1"; PASS=$((PASS+1)); }
fail() { echo -e "  ${RED}✗ FAIL${NC} – $1"; FAIL=$((FAIL+1)); }
info() { echo -e "  ${YELLOW}ℹ${NC}  $1"; }

echo -e "${YELLOW}[TEST 1] Namespace 'monitoring' exists${NC}"
kubectl get namespace monitoring >/dev/null 2>&1 \
  && ok "Namespace exists" || fail "Namespace missing"

echo ""; echo -e "${YELLOW}[TEST 2] Prometheus server running${NC}"
PODS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus \
  --no-headers 2>/dev/null | grep -c "Running" || echo 0)
[ "$PODS" -ge 1 ] && ok "Prometheus pod Running" || fail "Prometheus not running"

echo ""; echo -e "${YELLOW}[TEST 3] Grafana running${NC}"
PODS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana \
  --no-headers 2>/dev/null | grep -c "Running" || echo 0)
[ "$PODS" -ge 1 ] && ok "Grafana pod Running" || fail "Grafana not running"

echo ""; echo -e "${YELLOW}[TEST 4] Grafana UI reachable${NC}"
CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 \
  http://localhost:3030 2>/dev/null || echo "000")
[[ "$CODE" =~ ^(200|302)$ ]] \
  && ok "Grafana UI reachable (HTTP $CODE)" \
  || fail "Grafana not reachable (HTTP $CODE)"

echo ""; echo -e "${YELLOW}[TEST 5] NF metrics exporter running${NC}"
PODS=$(kubectl get pods -n monitoring -l app=nf-metrics-exporter \
  --no-headers 2>/dev/null | grep -c "Running" || echo 0)
[ "$PODS" -ge 1 ] && ok "NF metrics exporter Running" || fail "Exporter not running"

echo ""; echo -e "${YELLOW}[TEST 6] NF metrics endpoint returns Prometheus format${NC}"
METRICS=$(kubectl exec -n monitoring \
  $(kubectl get pod -n monitoring -l app=nf-metrics-exporter -o name | head -1) \
  -- wget -qO- http://localhost:9090/metrics 2>/dev/null || echo "")
echo "$METRICS" | grep -q "amf_registered_ue_count" \
  && ok "amf_registered_ue_count metric found" \
  || fail "amf_registered_ue_count not in metrics"

echo ""; echo -e "${YELLOW}[TEST 7] ServiceMonitor exists${NC}"
kubectl get servicemonitor nf-metrics -n monitoring >/dev/null 2>&1 \
  && ok "ServiceMonitor 'nf-metrics' exists" \
  || fail "ServiceMonitor missing"

echo ""; echo -e "${YELLOW}[TEST 8] Node exporter running${NC}"
PODS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=node-exporter \
  --no-headers 2>/dev/null | grep -c "Running" || echo 0)
[ "$PODS" -ge 1 ] && ok "Node exporter Running (${PODS} pods)" || fail "Node exporter not running"
info "Node exporter exposes host-level metrics (CPU, memory, network)"

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
TOTAL=$((PASS+FAIL))
[ "$FAIL" -eq 0 ] \
  && echo -e "${GREEN}  ✅  All ${TOTAL} tests passed!${NC}" \
  || echo -e "${YELLOW}  ⚠️  ${PASS}/${TOTAL} passed.${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""
