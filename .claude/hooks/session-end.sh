#!/bin/bash
# session-end.sh — Hook real de SessionEnd.
# Escribe un resumen legible de la sesion en .claude/summary/, con contenido real
# (mensaje, git diff --stat, archivos tocados, lecciones de hoy). NO escribe plantillas vacias.
# Uso: bash session-end.sh "<mensaje de cierre>"
set -u

MENSAJE="${1:-Sesión de trabajo}"
FECHA=$(date +"%Y-%m-%d-%H%M")
HORA=$(date +"%H:%M")
FECHA_DIA=$(date +"%Y-%m-%d")

PROYECTO=$(basename "$(pwd)")
SUMMARY_DIR=".claude/summary"
LESSONS_DIR=".claude/lessons"
LESSON_FILE="$LESSONS_DIR/$FECHA_DIA.md"

mkdir -p "$SUMMARY_DIR"

# --- Dedupe por sesión -------------------------------------------------
# Si exit.sh o el propio hook SessionEnd ya guardaron el resumen de ESTA
# sesión, no escribirlo dos veces. exit.sh (dentro de Claude) trae la env
# CLAUDE_CODE_SESSION_ID; el hook SessionEnd NO la trae y recibe el id por
# stdin JSON (hook_meta.session_id). Solo se lee stdin si la env esta vacia,
# y con timeout (sin esperar EOF) para que un pipe abierto jamas cuelgue.
SID="${CLAUDE_CODE_SESSION_ID:-}"
if [ -z "$SID" ] && [ ! -t 0 ]; then
    SID=$(node -e 'let d="",t;const done=()=>{let s="";try{const j=JSON.parse(d);s=(j.hook_meta&&j.hook_meta.session_id)||""}catch(e){}process.stdout.write(s,()=>process.exit(0))};process.stdin.on("data",c=>{d+=c;clearTimeout(t);t=setTimeout(done,60)});t=setTimeout(done,60)' 2>/dev/null)
fi
LOCK="$SUMMARY_DIR/.saved-${SID:-none}"
if [ -n "$SID" ] && [ -f "$LOCK" ]; then
    echo "Resumen ya guardado para esta sesión ($SID) — sin duplicado."
    exit 0
fi
# Poda de locks viejos (>7 días) para que no se acumulen en .claude/summary
find "$SUMMARY_DIR" -maxdepth 1 -name '.saved-*' -mtime +7 -delete 2>/dev/null || true

SUMMARY_FILE="$SUMMARY_DIR/$FECHA.md"

{
    echo "# Resumen de sesión — $(date +"%Y-%m-%d %H:%M")"
    echo ""
    echo "## Proyecto"
    echo "$PROYECTO"
    echo ""
    echo "## Cierre"
    echo "$MENSAJE"
    echo ""

    # Cambios pendientes (git diff --stat)
    if [ -d ".git" ]; then
        echo "## Cambios en el repo"
        if git diff --stat --quiet 2>/dev/null; then
            echo "- Sin cambios en el working tree (todo commiteado o limpio)."
        else
            git diff --stat 2>/dev/null | tail -n +1 || echo "- (no se pudo leer diff)"
        fi
        UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | head -20)
        if [ -n "$UNTRACKED" ]; then
            echo ""
            echo "### Archivos nuevos sin trackear"
            echo "$UNTRACKED"
        fi
        echo ""
    fi

    # Lecciones de hoy (si hay)
    if [ -f "$LESSON_FILE" ]; then
        echo "## Lecciones de hoy"
        cat "$LESSON_FILE"
        echo ""
    fi
} > "$SUMMARY_FILE"

[ -n "$SID" ] && touch "$LOCK"

echo "✅ Resumen guardado: $SUMMARY_FILE"
