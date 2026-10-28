#!/bin/bash
# init.sh — Inicia tu sesión de trabajo con el harness
# Uso: ./init.sh [ruta-del-proyecto]

set -e

# Colores
VERDE='\033[0;32m'
AMARILLO='\033[1;33m'
ROJO='\033[0;31m'
AZUL='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Cargar config parametrizada por proyecto (si existe)
if [ -f "scripts/config.sh" ]; then
    # shellcheck disable=SC1091
    source scripts/config.sh
else
    HARNESS_NAME="mi proyecto"
    HARNESS_STACK="web"
    HARNESS_TZ="America/Mexico_City"
    HARNESS_MODEL="deepseek-v4-flash"
fi

# ============================================
# 1. DETECTAR PROYECTO
# ============================================
if [ -n "$1" ]; then
    PROYECTO="$1"
else
    # Buscar proyectos recientes en ~/proyectos o ~
    echo -e "${AZUL}📁 Proyectos recientes:${NC}"
    find ~ -maxdepth 2 -type d \( -name ".git" -o -name "package.json" -o -name "*.md" \) -printf "%h\n" 2>/dev/null | sort -u | head -5 | nl -w2 -s'. '
    echo ""
    echo -e "${AMARILLO}Escribe la ruta de tu proyecto (o '.' para actual):${NC}"
    read -r PROYECTO
    [ -z "$PROYECTO" ] && PROYECTO="."
fi

if [ ! -d "$PROYECTO" ]; then
    echo -e "${ROJO}❌ El directorio '$PROYECTO' no existe.${NC}"
    exit 1
fi

cd "$PROYECTO"
PROYECTO_NOMBRE=$(basename "$(pwd)")

# ============================================
# 2. HEADER
# ============================================
echo ""
echo -e "${VERDE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${VERDE}║${NC}  🚀  ${CYAN}HARNESS${NC} — $HARNESS_NAME${NC}"
echo -e "${VERDE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${AZUL}📂 Stack:${NC} $HARNESS_STACK  |  ${AZUL}Proyecto:${NC} $(pwd)"
echo ""

# ============================================
# 3. VERIFICAR HARNESS
# ============================================
echo -e "${AMARILLO}🔧 Verificando harness...${NC}"

# Verificar skills del proyecto (.claude/skills). Los de ~/.claude/skills y plugins son
# globales y se cargan solos en cualquier proyecto: se muestran aparte, sin mezclar.
LOCAL_SKILLS=$(ls -d .claude/skills/*/SKILL.md 2>/dev/null | wc -l)
GLOBAL_SKILLS=$(ls -d "$HOME/.claude/skills"/*/SKILL.md 2>/dev/null | wc -l)
if [ "$LOCAL_SKILLS" -gt 0 ]; then
    echo -e "  ${VERDE}✅${NC} Skills del proyecto: $LOCAL_SKILLS (viajan con el repo)"
    [ "$GLOBAL_SKILLS" -gt 0 ] && echo -e "  ${AZUL}🌐${NC} Skills globales (home): $GLOBAL_SKILLS — se ven en todos tus proyectos"
else
    echo -e "  ${ROJO}⚠️${NC}  No hay skills en .claude/skills. Considera correr setup-harness.sh"
fi

# Verificar Ponytail
if [ -n "$PONYTAIL_MODE" ]; then
    echo -e "  ${VERDE}✅${NC} Ponytail: modo ${CYAN}$PONYTAIL_MODE${NC}"
else
    echo -e "  ${AMARILLO}⚡${NC} Ponytail: modo ${CYAN}full${NC} (default)"
fi

# ============================================
# 4. LECCIONES Y RESÚMENES
# ============================================
echo ""
echo -e "${AMARILLO}🧠 Lecciones y resúmenes...${NC}"

LESSONS_COUNT=$(ls .claude/lessons/*.md 2>/dev/null | wc -l)
if [ "$LESSONS_COUNT" -gt 0 ]; then
    echo -e "  ${VERDE}✅${NC} $LESSONS_COUNT día(s) de lecciones guardadas"
    echo -e "  ${AZUL}💡${NC} Al corregir a Claude, di ${CYAN}/lesson ...${NC} para no repetirlo."
else
    echo -e "  ${AMARILLO}⚡${NC} Sin lecciones aún. Al corregir a Claude, di ${CYAN}/lesson ...${NC}"
fi

ULTIMO_SUMMARY=$(ls -t .claude/summary/*.md 2>/dev/null | head -1)
if [ -n "$ULTIMO_SUMMARY" ]; then
    echo -e "  ${AZUL}📄${NC} Último resumen de sesión: ${CYAN}$(basename "$ULTIMO_SUMMARY")${NC}"
fi

# ============================================
# 6. GRAPHIFY (si repo grande)
# ============================================
echo ""
FILE_COUNT=$(find . -type f -not -path './node_modules/*' -not -path './.git/*' -not -path './.claude/*' | wc -l)

if [ "$FILE_COUNT" -gt 50 ]; then
    echo -e "${AMARILLO}📊 Repo grande detectado ($FILE_COUNT archivos)...${NC}"
    if [ -f "graphify-out/graph.json" ]; then
        GRAPH_AGE=$(( ($(date +%s) - $(stat -c %Y graphify-out/graph.json 2>/dev/null || echo 0)) / 3600 ))
        if [ "$GRAPH_AGE" -gt 24 ]; then
            echo -e "  ${AMARILLO}⚡${NC} Grafo desactualizado (${GRAPH_AGE}h). Sugerencia: ${CYAN}graphify update .${NC}"
        else
            echo -e "  ${VERDE}✅${NC} Grafo actualizado (hace ${GRAPH_AGE}h)"
        fi
    else
        echo -e "  ${ROJO}⚠️${NC}  No hay grafo. Sugerencia: ${CYAN}graphify .${NC}"
    fi
else
    echo -e "${VERDE}✅${NC} Repo pequeño ($FILE_COUNT archivos) — Graphify no necesario"
fi

# ============================================
# 6.25 GITNEXUS (detector opcional — repo denso / PRs)
# ============================================
# Mismo espíritu que graphify: si el repo huele a caso de GitNexus
# (contexto denso o muchos cambios sin commitear), sugiere /gitnexus-check.
# Solo avisa: no indexa nada ni instala.
CHANGES_GIT=$(git status --short 2>/dev/null | wc -l)
if [ "${FILE_COUNT:-0}" -gt 150 ] || [ "${CHANGES_GIT:-0}" -gt 10 ]; then
    echo ""
    echo -e "  ${AZUL}🧭${NC} Contexto denso (${CYAN}$FILE_COUNT archivos / $CHANGES_GIT cambios${NC}). Si vas a refactorizar o revisar PRs, mira ${CYAN}/gitnexus-check${NC} (impacto por símbolos)."
fi

# ============================================
# 6.5 CLAUDE-MEM (enhancer de recall, OPCIONAL)
# ============================================
# Nunca dependencia: si claude-mem no responde, el harness funciona igual.
echo ""
CM_HEALTH=$(curl -s --max-time 2 "http://${HARNESS_CLAUDE_MEM_HOST:-127.0.0.1}:${HARNESS_CLAUDE_MEM_PORT:-37777}/health" 2>/dev/null || true)
if printf '%s' "$CM_HEALTH" | grep -q '"status":"ok"'; then
    echo -e "  ${VERDE}✅${NC} claude-mem: activo (recall opcional) — invoca ${CYAN}/recall${NC} para contexto relevante"
else
    echo -e "  ${AMARILLO}⚡${NC} claude-mem: no activo — opcional, el harness funciona igual"
fi

# ============================================
# 7. HORARIO DEEPSEEK (Pico vs Valle)
# ============================================
echo ""
HORA_UTC=$(date -u +%H)
HORA_LOCAL=$(TZ="$HARNESS_TZ" date +"%H:%M")

# Pico: 01:00-04:00 UTC y 06:00-10:00 UTC (ventanas de precio de DeepSeek, basadas en UTC)
if [ "$HORA_UTC" -ge 1 ] && [ "$HORA_UTC" -lt 4 ] || [ "$HORA_UTC" -ge 6 ] && [ "$HORA_UTC" -lt 10 ]; then
    echo -e "${ROJO}🔴 HORA PICO${NC} — Precio 2x (hora local $HORA_LOCAL $HARNESS_TZ)"
    echo -e "  ${AMARILLO}💡${NC} Usa $HARNESS_MODEL para minimizar costo, o espera a valle."
else
    echo -e "${VERDE}🟢 HORA VALLE${NC} — Precio normal (hora local $HORA_LOCAL $HARNESS_TZ)"
fi

# ============================================
# 7.5 DETECTAR SESIÓN YA ABIERTA
# ============================================
# Si ya estamos DENTRO de Claude Code no abrir otra sesión anidada.
# En una sesión se definen CLAUDE_CODE_SESSION_ID y CLAUDECODE=1.
# También puedes forzar solo-reporte (sin abrir Claude) con HARNESS_NO_LAUNCH=1.
LAUNCH_CLAUDE=1
if [ -n "${CLAUDE_CODE_SESSION_ID:-}" ] || [ "${CLAUDECODE:-}" = "1" ] || [ "${HARNESS_NO_LAUNCH:-}" = "1" ]; then
    LAUNCH_CLAUDE=0
fi

# ============================================
# 8. RESUMEN Y ENTRADA
# ============================================
echo ""
if [ "$LAUNCH_CLAUDE" = "1" ]; then
    echo -e "${VERDE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${VERDE}║${NC}  ✅ ${CYAN}TODO LISTO${NC} — Abriendo Claude Code...                  ${VERDE}║${NC}"
    echo -e "${VERDE}╚══════════════════════════════════════════════════════════════╝${NC}"
else
    echo -e "${VERDE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${VERDE}║${NC}  ✅ ${CYAN}TODO LISTO${NC} — Ya estás en Claude Code                ${VERDE}║${NC}"
    echo -e "${VERDE}╚══════════════════════════════════════════════════════════════╝${NC}"
fi
echo ""
echo -e "${AZUL}Comandos útiles:${NC}"
echo -e "  ${CYAN}modo tdd red${NC}      → Escribe test que falla"
echo -e "  ${CYAN}modo tdd green${NC}    → Escribe código mínimo"
echo -e "  ${CYAN}/lesson ...${NC}      → Guarda una corrección como lección"
echo -e "  ${CYAN}/code-review${NC}     → Revisa diff con ojos frescos"
echo -e "  ${CYAN}/self-audit${NC}     → Audita la sesión actual"
echo -e "  ${CYAN}exit${NC}              → Guarda resumen de sesión"
echo ""

# Abrir Claude Code (solo si NO estamos ya dentro)
if [ "$LAUNCH_CLAUDE" = "1" ]; then
    claude
else
    echo ""
    echo -e "${VERDE}   Ya estás dentro de Claude Code — no se abre otra sesión.${NC}"
    echo -e "${AZUL}   El estado del harness está arriba. Skills listos; escribe o usa /lesson, /recall, etc.${NC}"
fi
