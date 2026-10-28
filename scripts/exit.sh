#!/bin/bash
# exit.sh — Cierra la sesion guardando un resumen real (delega en el hook SessionEnd).
# Uso: ./exit.sh [mensaje-opcional]
set -e

# Colores
VERDE='\033[0;32m'
AMARILLO='\033[1;33m'
ROJO='\033[0;31m'
AZUL='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================
# 1. VERIFICAR QUE ESTAMOS EN UN PROYECTO
# ============================================
if [ ! -d ".claude" ]; then
    echo -e "${ROJO}❌ No se detectó carpeta .claude/ en $(pwd)${NC}"
    echo -e "${AMARILLO}¿Estás en la raíz de tu proyecto?${NC}"
    exit 1
fi

# ============================================
# 2. HARNESS NAME (config parametrizada)
# ============================================
HARNESS_NAME="este proyecto"
if [ -f "scripts/config.sh" ]; then
    # shellcheck disable=SC1091
    source scripts/config.sh
fi

MENSAJE="${1:-Sesión de trabajo}"

echo ""
echo -e "${AZUL}🚪 Cerrando sesión en:${NC} $HARNESS_NAME"
echo ""

# ============================================
# 3. RESUMEN REAL (hook SessionEnd)
# ============================================
echo -e "${AMARILLO}📋 Guardando resumen de sesión...${NC}"

# Si el hook SessionEnd ya lo hizo automaticamente, no duplicar: solo mostrar.
if [ -d ".claude/hooks" ] && [ -f ".claude/hooks/session-end.sh" ]; then
    OUT=$(bash .claude/hooks/session-end.sh "$MENSAJE")
    echo -e "  ${VERDE}✅${NC} $OUT"
    RESUMEN=$(ls -t .claude/summary/*.md 2>/dev/null | head -1)
    if [ -n "$RESUMEN" ]; then
        echo -e "  ${AZUL}📄${NC} ${CYAN}$RESUMEN${NC}"
    fi
else
    echo -e "  ${AMARILLO}⚠️${NC}  No se encontró el hook session-end.sh. Revisa tu instalación."
fi

# ============================================
# 3b. SELF-AUDIT REAL (recurrencia de lecciones)
# ============================================
if [ -f "scripts/self-audit.sh" ]; then
    echo ""
    echo -e "${AMARILLO}🔍 Self-audit (recurrencia de lecciones)...${NC}"
    AUDIT_OUT=$(bash scripts/self-audit.sh 2>/dev/null | head -3)
    echo -e "  ${VERDE}✅${NC} ${AUDIT_OUT##*$'\n'}"
    ULTIMO_AUDIT=$(ls -t .claude/audit/*.md 2>/dev/null | head -1)
    if [ -n "$ULTIMO_AUDIT" ]; then
        echo -e "  ${AZUL}📊${NC} ${CYAN}$ULTIMO_AUDIT${NC}"
    fi
    # Marcamos la sesion para que el hook SessionEnd no re-audite al salir
    # (el dedupe del self-audit solo se activa cuando llega el payload del hook).
    if [ -n "${CLAUDE_CODE_SESSION_ID:-}" ]; then
        touch ".claude/audit/.audited-${CLAUDE_CODE_SESSION_ID}"
    fi
fi

# ============================================
# 4. RECORDATORIO GIT
# ============================================
if [ -d ".git" ]; then
    CAMBIOS_GIT=$(git status --short 2>/dev/null | wc -l)
    if [ "$CAMBIOS_GIT" -gt 0 ]; then
        echo ""
        echo -e "  📝 Git: ${AMARILLO}$CAMBIOS_GIT cambios sin commitear${NC}"
        echo -e "  ${AMARILLO}💡${NC} Revisa con /code-review antes de commitear."
    fi
fi

echo ""
echo -e "${VERDE}¡Hasta la próxima! 👋${NC}"
echo ""
