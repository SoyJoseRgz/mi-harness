# Uso del Harness

Plantilla multi-proyecto para trabajar con Claude Code sobre DeepSeek. Este documento describe el flujo **real** (lo que funciona), no el aspiracional.

## Lo que hace el harness

- **Entrega calidad** con un modelo débil/barato: compensa con estructura (TDD, plan antes de editar, gates).
- **Te deja ver qué hace**: resumen legible al cerrar sesión.
- **Aprende de tus correcciones**: `/lesson` guarda lo que pides cambiar para no repetirlo.

## Configuración por proyecto

Edita `scripts/config.sh` en cada proyecto que copies la plantilla:

| Variable | Qué es |
|----------|--------|
| `HARNESS_NAME` | Nombre legible del proyecto |
| `HARNESS_STACK` | Stack (web, python CLI, mobile…) |
| `HARNESS_TZ` | Zona horaria en formato IANA |
| `HARNESS_MODEL` | Modelo por defecto (informativo) |
| `HARNESS_CLAUDE_MEM_HOST` / `PORT` | Worker de claude-mem (opcional; defaults `127.0.0.1:37777`) |

No hay supuestos hardcodeados: `init.sh` y `exit.sh` leen de aquí.

## Skills (viajan con el repo, en `.claude/skills/`)

| Skill | Cuándo | Qué hace |
|-------|--------|----------|
| `lesson` | Cuando corriges a Claude | Guarda la corrección en `.claude/lessons/` |
| `recall` | Antes de una tarea nueva / al pedirlo | Trae contexto relevante del proyecto desde claude-mem (opcional, nunca dependencia) |
| `plan-gate` | Antes de cada edición | Presenta plan corto y espera tu OK |
| `tdd-red` | Primero | Escribe el test que falla |
| `tdd-green` | Después | Implementa el mínimo para pasarlo |
| `ponytail` | Al simplificar | Lo más perezoso que funciona |
| `git-guardrails` | Antes de comandos destructivos | Pide confirmación literal |
| `code-review-agent` | Antes de commitear | Revisa el diff con ojos frescos |
| `self-audit` | Al cerrar / manual | Mide recurrencia de lecciones, recomienda ajustes |

## Hooks (registrados en `.claude/settings.json`)

- **`SessionEnd` → `session-end.sh`**: escribe un resumen real en `.claude/summary/` (mensaje + `git diff --stat` + archivos nuevos + lecciones de hoy). Nada de plantillas vacías.
- **`SessionEnd` → `self-audit.sh`**: recolección automática — mide recurrencia de lecciones y escribe el audit en `.claude/audit/`.
- **`PreToolUse` → `plan-gate.sh`** (solo `Edit|Write|NotebookEdit`): gate duro — pide confirmación en el primer edit de cada sesión. Apagable con `HARNESS_PLAN_GATE=off` en `scripts/config.sh`.

> Nota: los hooks `.md` antiguos (`sessionend-memo.md`, etc.) eran prompts en prosa, no hooks ejecutables — por eso `.claude/memo/` y `.claude/audit/` quedaban vacíos. Fueron eliminados; el hook real es el `.sh` registrado en `settings.json`.

## Ciclo de sesión

1. **Entrar**: `./scripts/init.sh` (o `init.sh <ruta>`)
2. **Trabajar**: la plantilla guía con plan-gate + TDD. Cuando corrijas algo, di `/lesson <tu corrección>`.
3. **Salir**: `./scripts/exit.sh "qué hiciste"` — o déjalo al hook `SessionEnd`.

## Instalación (una vez por máquina)

```bash
cd mi-harness
./scripts/setup-harness.sh   # instala claude-mem + graphify (externos)
```

Los skills y hooks locales viajan con el repo: copia la carpeta `.claude/` a cada proyecto.

## claude-mem (enhancer de recall, nunca dependencia)

claude-mem está integrado de forma opcional:

- **`init.sh`** hace un health-check del worker local y muestra si está activo (1 línea, skip silencioso si no responde).
- **`/recall <tema?>`** trae contexto relevante del proyecto vía las herramientas MCP de claude-mem (busca → filtra → trae detalles → sintetiza). Si claude-mem no está o no hay contexto, lo dice y continúa.
- Los skills y hooks del harness no dependen de claude-mem: si lo apagas, todo sigue funcionando.
