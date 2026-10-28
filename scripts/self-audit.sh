#!/bin/bash
# self-audit.sh — Self-audit REAL basado en recurrencia de lecciones.
# Lee .claude/lessons/*.md, detecta correcciones que se repiten en dias DISTINTOS
# (= no resuelto), y escribe .claude/audit/YYYY-MM-DD-HHMM.md con metricas reales.
# Tambien imprime el reporte a stdout para que Claude lo interprete (skill /self-audit).
# Uso: bash scripts/self-audit.sh
set -e

LESSONS_DIR=".claude/lessons"
AUDIT_DIR=".claude/audit"
mkdir -p "$AUDIT_DIR"

# --- Dedupe del CERRADO AUTOMATICO (hook SessionEnd) -------------------
# exit.sh ya corre self-audit al cerrar; si luego el hook SessionEnd corre el
# MISMO self-audit al salir, se escribirian DOS reportes. La marca para saber que
# esto es el hook (y no un uso manual de /self-audit) es que el stdin trae el
# payload JSON con hook_meta.session_id; exit.sh y el uso manual NO lo traen, asi
# que siempre auditan (es lo que quieres al verificar una correccion a mitad de
# sesion). La lectura de stdin lleva TIMEOUT (60ms, sin esperar EOF) para que un
# pipe que no se cierra jamas cuelgue el script.
VIA_HOOK=""
LOCK=""
if [ ! -t 0 ]; then
    VIA_HOOK=$(node -e 'let d="",t;const done=()=>{let s="";try{const j=JSON.parse(d);s=(j.hook_meta&&j.hook_meta.session_id)||""}catch(e){}process.stdout.write(s,()=>process.exit(0))};process.stdin.on("data",c=>{d+=c;clearTimeout(t);t=setTimeout(done,60)});t=setTimeout(done,60)' 2>/dev/null)
fi
if [ -n "$VIA_HOOK" ]; then
    LOCK="$AUDIT_DIR/.audited-$VIA_HOOK"
    if [ -f "$LOCK" ]; then
        echo "Self-audit ya generado para esta sesión ($VIA_HOOK) — sin duplicado."
        exit 0
    fi
    find "$AUDIT_DIR" -maxdepth 1 -name '.audited-*' -mtime +7 -delete 2>/dev/null || true
fi

FECHA=$(date +"%Y-%m-%d-%H%M")
AUDIT_FILE="$AUDIT_DIR/$FECHA.md"

# ---------- Recopilar lecciones ----------
# Normaliza la correccion (minusculas, espacios simples, sin punto final) como clave.
normalizar() {
    printf '%s' "$1" \
        | sed 's/^- *Correccion: *//I' \
        | tr '[:upper:]' '[:lower:]' \
        | sed 's/[[:space:]]\+/ /g; s/^[[:space:]]*//; s/[[:space:]]*$//; s/\.$//'
}

declare -A CORR_DATES   # correccion normalizada (solo abiertas) -> fechas de aparicion (una por linea)
TOTAL=0
RESUELTAS=0

for f in "$LESSONS_DIR"/*.md; do
    [ -e "$f" ] || continue
    FECHA_DIA=$(basename "$f" .md)   # YYYY-MM-DD
    # awk: por entrada, imprime "A\t<correccion>" (abierta) o "R\t<correccion>" (resuelta)
    while IFS=$'\t' read -r est corr; do
        TOTAL=$((TOTAL + 1))
        corr=$(normalizar "$corr")
        [ -z "$corr" ] && continue
        if [ "$est" = "R" ]; then
            RESUELTAS=$((RESUELTAS + 1))
            continue
        fi
        CORR_DATES["$corr"]="${CORR_DATES["$corr"]:-}$FECHA_DIA"$'\n'
    done < <(awk -v RS='\n## ' '
        {
          corr=""; estado=""
          n = split($0, lines, "\n")
          for (i=1;i<=n;i++) {
            if (lines[i] ~ /^- *[Cc]orreccion: *./) { sub(/^- *[Cc]orreccion: */, "", lines[i]); corr=lines[i] }
            if (lines[i] ~ /^- *[Ee]stado: *./) { sub(/^- *[Ee]stado: */, "", lines[i]); estado=tolower(lines[i]) }
          }
          if (corr != "") {
            if (estado == "resuelta") print "R\t" corr
            else print "A\t" corr
          }
        }' "$f" 2>/dev/null || true)
done

# ---------- Detectar recurrentes (misma correccion en >=2 dias DISTINTOS) ----------
RECURRENTES=()
for c in "${!CORR_DATES[@]}"; do
    NDIAS=$(printf '%s' "${CORR_DATES[$c]}" | sed '/^$/d' | sort -u | wc -l)
    if [ "$NDIAS" -ge 2 ]; then
        FECHAS=$(printf '%s' "${CORR_DATES[$c]}" | sed '/^$/d' | sort -u | paste -sd ', ' -)
        RECURRENTES+=("$c|$NDIAS|$FECHAS")
    fi
done

# ---------- Escribir reporte ----------
{
    echo "# Self-Audit — $(date +"%Y-%m-%d %H:%M")"
    echo ""
    echo "## Métricas reales (de .claude/lessons/)"
    echo "- Total de correcciones registradas: $TOTAL"
    echo "- Marcadas como resueltas: $RESUELTAS"
    echo "- Correcciones abiertas distintas: ${#CORR_DATES[@]}"
    echo "- Correcciones recurrentes (2+ días distintos): ${#RECURRENTES[@]}"
    echo ""
    if [ "${#RECURRENTES[@]}" -eq 0 ]; then
        echo "## Diagnóstico"
        echo "✅ Sin correcciones recurrentes. Lo que corregiste no se ha vuelto a repetir."
    else
        echo "## Correcciones recurrentes (NO resueltas)"
        for r in "${RECURRENTES[@]}"; do
            IFS='|' read -r corr ndias fechas <<< "$r"
            echo "- **$corr** — $ndias días distintos ($fechas)"
        done
        echo ""
        echo "## Diagnóstico"
        echo "⚠️ Estas correcciones se repiten en días distintos: la lección no se consolidó."
        echo "   La recurrencia es la señal de que el ajuste del harness no funcionó todavía."
    fi
} > "$AUDIT_FILE"

# Si vino del hook, marcar la sesion para que una futura corrida del hook no duplique.
[ -n "$VIA_HOOK" ] && [ -n "$LOCK" ] && touch "$LOCK"

echo "✅ Self-audit generado: $AUDIT_FILE"
cat "$AUDIT_FILE"
