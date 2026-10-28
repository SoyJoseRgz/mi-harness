#!/bin/bash
# plan-gate.sh — Gate duro de plan (hook PreToolUse).
# Pide confirmacion en el PRIMER Edit/Write/NotebookEdit de cada sesion (ask).
# Los edits siguientes de la misma sesion pasan sin preguntar (marker por sesion).
# Apagable con HARNESS_PLAN_GATE=off en scripts/config.sh.
# Lee JSON de stdin (tool_name, hook_meta.session_id). Sin salida = allow.
set -e

PLAN_GATE="${HARNESS_PLAN_GATE:-on}"
if [ "$PLAN_GATE" = "off" ]; then
    echo '{"decision":"allow"}'
    exit 0
fi

# Parsear stdin UNA vez: tool_name \t session_id
PARSE=$(node -e '
let d="";
process.stdin.on("data",c=>d+=c).on("end",()=>{
  try{const j=JSON.parse(d);
    const t=(j.tool_name||"");
    const s=(j.hook_meta&&j.hook_meta.session_id)||"";
    console.log(t+"\t"+s);
  }catch(e){console.log("\t");}
});' 2>/dev/null || echo $'\t')
TOOL="${PARSE%%$'\t'*}"
SID="${PARSE#*$'\t'}"

case "$TOOL" in
    Edit|Write|NotebookEdit) ;;
    *) echo '{"decision":"allow"}'; exit 0 ;;
esac

[ -z "$SID" ] && SID="default"
MARKER="${TMPDIR:-/tmp}/plan-gate-$SID"

if [ -f "$MARKER" ]; then
    echo '{"decision":"allow"}'
    exit 0
fi

touch "$MARKER"
echo "{\"decision\":\"ask\",\"reason\":\"Plan-gate activo: ¿apruebas esta edición ($TOOL)? Después de esta, el resto de la sesión sigue sin preguntar.\"}"
