#!/bin/bash
# harness-update.sh — Sincroniza las piezas CANONICAS del harness desde una copia
# maestra hacia el proyecto actual, SIN pisar tu personalizacion.
#
# Para que este harness valga la pena cuando lo copias a N proyectos, los arreglos
# se hacen UNA vez en la copia maestra y este script los propaga a cada proyecto.
# Ejecutalo DESDE la raiz del proyecto destino (cwd).
#
# ACTUALIZA (piezas del harness, seguro sobrescribir):
#   .claude/settings.json, .claude/hooks/*.sh,
#   .claude/skills/*/SKILL.md   (los skills que viajan con el harness),
#   scripts/init.sh exit.sh self-audit.sh setup-harness.sh (y este script),
#   docs/usage.md
#
# MANTIENE TUYO (NO se toca):
#   scripts/config.sh, tu CLAUDE.md (contexto del proyecto),
#   .claude/lessons .claude/summary .claude/audit (estado local),
#   skills locales EXTRA que hayas agregado solo en este proyecto.
#
# Uso (desde la raiz del proyecto): ./scripts/harness-update.sh [/ruta/al/harness]
# Si no pasas ruta, prueba $HARNESS_SRC y luego ubicaciones por defecto.
set -e

# Colores
VERDE='\033[0;32m'; AMARILLO='\033[1;33m'; ROJO='\033[0;31m'; AZUL='\033[0;34m'; NC='\033[0m'

# ============================================
# 0. RESOLVER LA COPIA MAESTRA (SRC)
# ============================================
SRC="${1:-}"
CANDIDATOS=()
[ -n "$SRC" ] && CANDIDATOS+=("$SRC")
[ -n "$HARNESS_SRC" ] && CANDIDATOS+=("$HARNESS_SRC")
CANDIDATOS+=("$HOME/Desktop/mi-harness" "$HOME/proyectos/mi-harness")

for c in "${CANDIDATOS[@]}"; do
    if [ -f "$c/scripts/init.sh" ] && [ -d "$c/.claude/skills" ]; then
        SRC="$c"; break
    fi
done

if [ -z "$SRC" ] || [ ! -f "$SRC/scripts/init.sh" ]; then
    echo -e "${ROJO}❌ No encontre la copia maestra del harness.${NC}"
    echo -e "${AMARILLO}Pasa la ruta: ./scripts/harness-update.sh /ruta/al/harness${NC}"
    exit 1
fi

echo -e "${VERDE}🔄 Sincronizando harness desde:${NC} $SRC"
echo -e "   → hacia: $(pwd)"

# ============================================
# 1. COPIAS (siempre reemplazan el destino; nunca anidan)
# ============================================
overwrite() { # $1 = ruta relativa dentro de SRC
    if [ -e "$SRC/$1" ]; then
        mkdir -p "$(dirname "$1")"
        rm -rf "$1"
        cp -a "$SRC/$1" "$1" && echo -e "  ${VERDE}✓${NC} $1"
    fi
}
sync_skills() {
    mkdir -p .claude/skills
    for d in "$SRC"/.claude/skills/*/; do
        [ -d "$d" ] || continue
        name=$(basename "$d")
        rm -rf ".claude/skills/$name"
        cp -a "$d" ".claude/skills/$name" && echo -e "  ${VERDE}✓${NC} .claude/skills/$name"
    done
}
sync_hooks() {
    mkdir -p .claude/hooks
    for f in "$SRC"/.claude/hooks/*.sh; do
        [ -e "$f" ] || continue
        rm -rf ".claude/hooks/$(basename "$f")"
        cp -a "$f" ".claude/hooks/$(basename "$f")" && echo -e "  ${VERDE}✓${NC} .claude/hooks/$(basename "$f")"
    done
}

# ============================================
# 2. EJECUTAR
# ============================================
echo ""
echo -e "${AZUL}📦 Skills (add/update, no borra extra):${NC}"
sync_skills

echo ""
echo -e "${AZUL}🔌 Hooks y settings:${NC}"
sync_hooks
overwrite .claude/settings.json

echo ""
echo -e "${AZUL}🛠 Scripts:${NC}"
for s in init.sh exit.sh self-audit.sh setup-harness.sh harness-update.sh; do
    overwrite "scripts/$s"
done

echo ""
echo -e "${AZUL}📄 Docs:${NC}"
overwrite docs/usage.md

echo ""
echo -e "${VERDE}✅ Listo.${NC}"
echo -e "${AMARILLO}   No se toco: scripts/config.sh, tu CLAUDE.md, ni el estado local (lessons/summary/audit).${NC}"
echo -e "${AMARILLO}   Revisa el diff (git diff) antes de commitear, por si la maestra trae cambios que quieras adaptar.${NC}"
