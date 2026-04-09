#!/bin/bash

# ============================================================
#  SYLVA-LAB – Challenge 1: Introduction to Sylva in Telco Cloud
#  Mode: Web + Sylva repo exploration (no deployment needed)
# ============================================================

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYLVA_DIR="${SCRIPT_DIR}/../sylva-core"

echo -e "${CYAN}"
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║   Challenge 01 – Introduction to Sylva           ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

# ─── 1. Check Sylva repo ──────────────────────────────────────────────────────
echo -e "${YELLOW}[1/3] Checking Sylva repository...${NC}"

if [ ! -d "$SYLVA_DIR/.git" ]; then
  echo -e "${RED}  ✗ sylva-core not found. Run ../start-cluster.sh first.${NC}"; exit 1
fi
echo -e "${GREEN}  ✓ sylva-core found at: ${SYLVA_DIR}${NC}"

# ─── 2. Explore structure ─────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[2/3] Exploring Sylva repo structure...${NC}"
echo ""
echo "  Root folders:"
ls "$SYLVA_DIR" | awk '{print "    " $0}'
echo ""

if [ -d "$SYLVA_DIR/charts" ]; then
  echo "  Helm charts available:"
  ls "$SYLVA_DIR/charts" 2>/dev/null | awk '{print "    " $0}' | head -15
fi

if [ -d "$SYLVA_DIR/cluster-templates" ]; then
  echo ""
  echo "  Cluster templates:"
  ls "$SYLVA_DIR/cluster-templates" 2>/dev/null | awk '{print "    " $0}' | head -10
fi

# ─── 3. Connectivity check ────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[3/3] Checking web resources...${NC}"

for entry in \
  "Sylva project page|https://sylvaproject.org" \
  "Sylva GitLab|https://gitlab.com/sylva-projects" \
  "CNCF Cloud Native Telco|https://www.cncf.io/reports/cloud-native-network-functions-whitepaper/"; do
  LABEL="${entry%%|*}"; URL="${entry##*|}"
  CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 6 "$URL" 2>/dev/null || echo "000")
  if [[ "$CODE" =~ ^(200|301|302|403)$ ]]; then
    echo -e "  ${GREEN}✓ REACHABLE${NC}  $LABEL"
  else
    echo -e "  ${YELLOW}⚠ CHECK    ${NC}  $LABEL (HTTP $CODE) — $URL"
  fi
done

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅  Challenge 01 environment ready!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  📚 Open ${YELLOW}README.md${NC} to start the challenge."
echo -e "  📁 Sylva repo: ${CYAN}../sylva-core/${NC}"
echo ""
