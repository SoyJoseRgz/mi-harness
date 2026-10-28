#!/bin/bash
# setup-harness.sh — Verifica/instala las herramientas EXTERNAS opcionales del harness.
# Son GLOBALES (una vez por maquina), NO por proyecto:
#   - claude-mem : plugin de Claude Code (thedotmack/claude-mem) para memoria/recall.
#   - graphify   : paquete Python `graphifyy` (binario graphify) + skill + hook-guard global.
# Los skills locales (.claude/skills/*) NO se instalan aqui: viajan con el repo.
# Claude Code y DeepSeek ya deben estar configurados.
# Ejecutar: ./scripts/setup-harness.sh
set -e

echo "Verificando herramientas externas del harness..."

# ============================================
# 1. CLAUDE-MEM (plugin de Claude Code)
#    Detecta si el plugin ya esta habilitado en ~/.claude/settings.json.
#    NO muta tu settings.json global: si falta, imprime como habilitarlo.
# ============================================
echo ""
echo "1) claude-mem (memoria global, plugin thedotmack/claude-mem)"
SETTINGS="$HOME/.claude/settings.json"
if [ -f "$SETTINGS" ] && grep -q 'claude-mem@thedotmack' "$SETTINGS" 2>/dev/null; then
    echo "   ✅ claude-mem: plugin habilitado (thedotmack/claude-mem)."
else
    echo "   ⚠️  claude-mem NO esta habilitado. Es un plugin de Claude Code, se agrega asi:"
    echo ""
    echo "       claude plugin marketplace add thedotmack/claude-mem"
    echo "       # luego habilitalo en /plugin (o reinicia Claude Code)"
    echo ""
    echo "   (No lo configuro yo: esto edita ~/.claude/settings.json global.)"
fi

# ============================================
# 2. GRAPHIFY (paquete Python `graphifyy` -> binario `graphify`)
#    Detecta el binario; si falta, lo instala con uv tool (fallback: pip).
#    Solo toca el paquete global (reversible), nunca ~/.claude/settings.json.
# ============================================
echo ""
echo "2) graphify (navegacion de repos grandes, paquete graphifyy)"
GRAPHIFY_BIN=""
if command -v graphify >/dev/null 2>&1; then
    GRAPHIFY_BIN="$(command -v graphify)"
elif [ -x "$HOME/.local/bin/graphify" ]; then
    GRAPHIFY_BIN="$HOME/.local/bin/graphify"
elif [ -x "$HOME/.local/bin/graphify.EXE" ]; then
    GRAPHIFY_BIN="$HOME/.local/bin/graphify.EXE"
fi

if [ -n "$GRAPHIFY_BIN" ]; then
    echo "   ✅ graphify: instalado ($GRAPHIFY_BIN)."
else
    echo "   Instalando graphifyy (el skill /graphify tambien requiere la skill y el hook-guard globales,"
    echo "   que se configuran aparte en ~/.claude/skills y ~/.claude/settings.json)..."
    if command -v uv >/dev/null 2>&1; then
        echo "   Usando uv tool install..."
        uv tool install --upgrade graphifyy -q
    else
        echo "   uv no encontrado, usando pip install..."
        pip install --upgrade graphifyy -q
    fi
    echo "   ✅ graphify: instalado."
fi

# ============================================
# 3. RESUMEN
# ============================================
echo ""
echo "Listo!"
echo ""
echo "Skills locales (viajan con el repo, ya estan en .claude/skills/):"
echo "  - lesson        (guarda tus correcciones como lecciones)"
echo "  - recall        (trae contexto desde claude-mem, opcional)"
echo "  - plan-gate     (presenta plan antes de editar)"
echo "  - tdd-red/green (tests primero)"
echo "  - ponytail      (frena sobre-ingenieria)"
echo "  - git-guardrails (protege comandos destructivos)"
echo "  - code-review   (revisa el diff con ojos frescos)"
echo "  - gitnexus-check (decide si conviene GitNexus)"
echo "  - self-audit    (automejora del harness)"
echo ""
echo "Externas: claude-mem (plugin) y graphify (graphifyy) — ambas GLOBALES, una vez por maquina."
echo "Nota: Claude Code y DeepSeek ya deben estar configurados."
echo ""
echo "Para iniciar tu sesion: ./scripts/init.sh"
