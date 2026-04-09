#!/bin/bash

# ============================================================
#  SYLVA-LAB – Challenge 8: End-to-End 5G Core Scenario
#  AMF → SMF → UPF full registration + data session flow
# ============================================================

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'
CLUSTER_NAME="sylva-lab"; NAMESPACE="nf-e2e"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}"
echo "  ███████╗ ██████╗      ██████╗ ██████╗ ██████╗ ███████╗"
echo "  ██╔════╝██╔════╝     ██╔════╝██╔═══██╗██╔══██╗██╔════╝"
echo "  ███████╗██║  ███╗    ██║     ██║   ██║██████╔╝█████╗  "
echo "  ╚════██║██║   ██║    ██║     ██║   ██║██╔══██╗██╔══╝  "
echo "  ███████║╚██████╔╝    ╚██████╗╚██████╔╝██║  ██║███████╗"
echo "  ╚══════╝ ╚═════╝      ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝"
echo -e "${NC}"
echo -e "  ${CYAN}SYLVA-LAB – Challenge 08: End-to-End 5G Core (AMF → SMF → UPF)${NC}"
echo ""

echo -e "${YELLOW}[1/5] Checking cluster...${NC}"
kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$" || \
  { echo -e "${RED}  ✗ Cluster not found. Run ../start-cluster.sh${NC}"; exit 1; }
echo -e "${GREEN}  ✓ Cluster running${NC}"
kubectl get nodes -l sylva-site --no-headers | awk '{print "  Node: "$1" site="$NF}'

echo ""
echo -e "${YELLOW}[2/5] Deploying 5G Core NFs (AMF + SMF + UPF)...${NC}"
kubectl apply -f "${SCRIPT_DIR}/manifests/5g-core-flow.yaml" >/dev/null
echo -e "${GREEN}  ✓ Namespace nf-e2e, AMF, SMF, UPF deployed${NC}"

echo ""
echo -e "${YELLOW}[3/5] Waiting for all 3 NF pods to be ready...${NC}"
echo -n "  Waiting"
for i in $(seq 1 90); do
  READY=$(kubectl get pods -n "${NAMESPACE}" --no-headers 2>/dev/null | grep -c "Running" || echo 0)
  [ "$READY" -ge 3 ] && { echo -e " ${GREEN}✓${NC}"; break; }
  echo -n "."; sleep 3
done
kubectl get pods -n "${NAMESPACE}" -o wide

echo ""
echo -e "${YELLOW}[4/5] Verifying all NF health endpoints...${NC}"
sleep 3
for NF_DEF in "AMF|8201" "SMF|8202" "UPF|8203"; do
  NF="${NF_DEF%%|*}"; PORT="${NF_DEF##*|}"
  CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 \
    http://localhost:${PORT}/health 2>/dev/null || echo "000")
  [ "$CODE" = "200" ] \
    && echo -e "${GREEN}  ✓ ${NF} UP → http://localhost:${PORT}${NC}" \
    || echo -e "${YELLOW}  ⚠ ${NF} not yet ready (HTTP ${CODE})${NC}"
done

echo ""
echo -e "${YELLOW}[5/5] Running a quick E2E test flow...${NC}"
sleep 2
RESP=$(curl -s --max-time 15 -X POST http://localhost:8201/namf-comm/v1/ue-complete-registration \
  -H "Content-Type: application/json" \
  -d '{"supi":"imsi-208930000000001","dnn":"internet"}' 2>/dev/null || echo "{}")
STEPS=$(echo "$RESP" | python3 -c \
  "import sys,json; d=json.load(sys.stdin); [print(f'  Step {s[\"step\"]}: {s[\"action\"]} → {s.get(\"status\",s.get(\"error\",\"\"))}') for s in d.get('steps',[])]" \
  2>/dev/null || echo "  (parse error)")
echo "$STEPS"

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅  5G Core E2E scenario deployed!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  📡 AMF API → ${CYAN}http://localhost:8201${NC}  (orchestrates the flow)"
echo -e "  📡 SMF API → ${CYAN}http://localhost:8202${NC}  (session management)"
echo -e "  📡 UPF API → ${CYAN}http://localhost:8203${NC}  (user plane / tunnels)"
echo ""
echo -e "  📋 Run ${YELLOW}./test.sh${NC} to validate all 8 tests"
echo -e "  📚 Open ${YELLOW}README.md${NC} for the challenge guide"
echo ""
