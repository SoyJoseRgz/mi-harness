# Mi Harness de Desarrollo

Plantilla multi-proyecto para trabajar con **Claude Code sobre DeepSeek** (modelo débil/barato).
El harness compensa con estructura lo que el modelo no tiene: te ayuda a **entregar calidad**, te deja **ver qué hace**, y **aprende de tus correcciones**.

> **En una frase:** no es magia, es proceso. Como el modelo es barato pero se distrae, el harness le pone carriles (plan antes de editar, tests primero, lecciones) para que el resultado sea consistente.

---

## Empezar por primera vez (una sola vez por máquina)

1. Copia esta carpeta a tu proyecto (o úsala tal cual aquí).
2. Edita `scripts/config.sh` con tu nombre de proyecto, stack y zona horaria (más abajo se explica).
3. Instala las herramientas externas opcionales:

```bash
cd mi-harness
./scripts/setup-harness.sh   # verifica/instala externos GLOBALES: claude-mem (plugin) + graphify
```

4. Confirma que DeepSeek está configurado (`ANTHROPIC_BASE_URL` y `ANTHROPIC_AUTH_TOKEN`).

Listo. Cada sesión de trabajo ahora es:

```bash
./scripts/init.sh            # entra; si ya estás dentro de Claude Code, solo reporta y NO abre otra sesión
# ...trabajas...
./scripts/exit.sh "qué hiciste"   # (o se cierra solo) guarda resumen + self-audit
```

---

## El ciclo de sesión, explicado

### 1. Entrar → `./scripts/init.sh`

Te muestra el estado de todo antes de empezar y abre Claude Code. Salida real:

```
🚀 HARNESS — mi proyecto
📂 Stack: web | Proyecto: /ruta/al/proyecto
🔧 Verificando harness...
  ✅ Skills cargados: 10
🧠 Lecciones y resúmenes...
  ⚡ Sin lecciones aún. Al corregir a Claude, di /lesson ...
✅ Repo pequeño (7 archivos) — Graphify no necesario
  ✅ claude-mem: activo (recall opcional) — invoca /recall
🟢 HORA VALLE — Precio normal (hora local 16:16 America/Mexico_City)
✅ TODO LISTO — Abriendo Claude Code...
```

Lo que te dice:
- **Skills cargados**: el harness está listo.
- **Lecciones**: cuántos días de correcciones guardadas tienes.
- **claude-mem / Graphify**: herramientas opcionales — si no están, no pasa nada.
- **HORA PICO/VALLE**: cuándo DeepSeek es caro (2x) para que decidas si conviene esperar.

### 2. Trabajar → el harness te guía

Cuando trabajas, el harness te empuja a hacer las cosas en orden:

1. **`/plan-gate`** → antes de tocar código presentas un plan corto y esperas tu OK. Esto es lo que evita que Claude (o tú) se lancen a editar a ciegas.
2. **`modo tdd red` → `modo tdd green`** → primero el test que falla, luego el mínimo código para que pase. Así sabes que lo que haces funciona.
3. **Cuando corrijas a Claude, di `/lesson <tu corrección>`** → se guarda para no repetirlo.

Ejemplo real de una corrección:

```
/luego no dupliques la lógica de auth, usa el helper de services/
```
Guarda `2026-08-24.md` (la fecha del día) con la lección. El self-audit la vigila.

### 3. Cerrar → `./scripts/exit.sh "qué hiciste"`

Guarda dos cosas:
- **Resumen de sesión** en `.claude/summary/` (qué hiciste + `git diff` + archivos nuevos).
- **Self-audit** en `.claude/audit/`: mide si una corrección se repite en días distintos (= no la aprendiste) y lo recomienda.

Si te olvidas de cerrar, el hook `SessionEnd` lo hace solo. Cerrar no **duplica** nada: si `exit.sh` ya guardó el resumen y corrió el self-audit, el hook detecta que es la misma sesión y no los repite. El `/self-audit` manual a mitad de sesión siempre audita (no se suprime).

---

## Los skills, en cristiano

| Skill | Cuándo | Qué hace | Ejemplo |
|-------|--------|----------|---------|
| `/lesson <x>` | Cuando corriges a Claude | Guarda la corrección para no repetirla | `/lesson no dupliques auth` |
| `/recall <tema>` | Antes de una tarea nueva | Trae trabajo pasado relevante desde claude-mem (opcional) | `/recall qué hicimos con el login` |
| `plan-gate` | Antes de cada edición | Presenta plan corto y espera tu OK | (se dispara solo) |
| `tdd-red` | Primero | Escribe el test que falla | `modo tdd red` |
| `tdd-green` | Después | Implementa el mínimo para pasar el test | `modo tdd green` |
| `ponytail` | Al simplificar | Lo más perezoso que funciona (frena sobre-ingeniería) | — |
| `git-guardrails` | Antes de comandos destructivos | Pide confirmación literal | — |
| `code-review-agent` | Antes de commitear | Revisa el diff con ojos frescos | `/code-review` |
| `/gitnexus-check` | Antes de refactorizar/PR en repo denso | Decide si GitNexus aporta (impacto por símbolos) y guía instalación | `/gitnexus-check` |
| `self-audit` | Al cerrar / manual | Mide recurrencia de lecciones, recomienda ajustes | `/self-audit` |

## Los hooks (corren solos, no los ves)

| Hook | Cuándo | Qué hace |
|------|--------|----------|
| `SessionEnd` → `session-end.sh` | Al cerrar sesión | Escribe resumen real en `.claude/summary/` |
| `SessionEnd` → `self-audit.sh` | Al cerrar sesión | Mide recurrencia y escribe `.claude/audit/` |
| `PreToolUse` → `plan-gate.sh` | En el primer edit | Pide confirmación antes de editar (apagable) |

---

## Configuración por proyecto

Copia la plantilla a cada proyecto y edita `scripts/config.sh`:

| Variable | Qué es |
|----------|--------|
| `HARNESS_NAME` | Nombre legible del proyecto |
| `HARNESS_STACK` | Stack (web, python CLI, mobile…) |
| `HARNESS_TZ` | Zona horaria IANA (`America/Mexico_City`, `Europe/Madrid`…) |
| `HARNESS_MODEL` | Modelo por defecto (informativo) |
| `HARNESS_PLAN_GATE` | Gate de plan: `on` / `off` |
| `HARNESS_CLAUDE_MEM_HOST` / `PORT` | Worker de claude-mem (opcional) |

Sin supuestos hardcodeados: `init.sh` y `exit.sh` leen de aquí.

Además del `CLAUDE.md` de plantilla en la raíz: al copiar el harness a un proyecto, edita la sección **"CONTEXTO DEL PROYECTO REAL"** de ese archivo (y `config.sh`) con lo que sea de ESE proyecto. Así cada copia lleva su propio contexto y no depende de lo que haya suelto en tu home (`~`).

---

## Solución de problemas

- **`init.sh` dice "claude-mem: no activo"** → normal, es opcional. Corre `claude-mem` (o ignóralo) si quieres recall.
- **`init.sh` no abre Claude Code** → ya estás dentro de una sesión de Claude Code (o usaste `HARNESS_NO_LAUNCH=1`). Es intencional: no abre otra sesión anidada.
- **El CLAUDE.md trae contexto de otro proyecto** → hay un `CLAUDE.md` suelto en la raíz de tu home (`~`). Claude Code lo carga en todos los proyectos. Bórralo o dale a cada proyecto su propio `CLAUDE.md` (usa la plantilla de este repo).
- **El plan-gate te molesta** → pon `HARNESS_PLAN_GATE="off"` en `config.sh`.
- **No recuerdas un skill** → revisa esta tabla o di `/recall`.
- **Quieres ver el grafo del repo** → `graphify query "tu pregunta"`.

---

## Estructura

```
mi-harness/
├── .claude/
│   ├── hooks/session-end.sh   ← hook real (SessionEnd)
│   ├── hooks/plan-gate.sh     ← gate real (PreToolUse)
│   ├── settings.json          ← registra los hooks
│   └── skills/                ← lesson, recall, plan-gate, ponytail, tdd-red, tdd-green,
│                                  git-guardrails, code-review-agent, gitnexus-check, self-audit
├── CLAUDE.md                  ← plantilla: reglas del harness + sección "CONTEXTO DEL PROYECTO REAL"
├── docs/usage.md              ← referencia detallada
└── scripts/
    ├── config.sh              ← parametriza por proyecto
    ├── init.sh / exit.sh      ← entra / sale
    ├── self-audit.sh          ← mide recurrencia de lecciones
    └── setup-harness.sh       ← verifica/instala externos globales (claude-mem, graphify)
```

## Notas

- `claude-mem` (memoria global) y las lecciones por proyecto **conviven sin duplicarse**: claude-mem captura historial global; `/lesson` captura correcciones específicas.
- `claude-mem` está integrado como **enhancer de recall (nunca dependencia)**: `init.sh` muestra si está activo y `/recall` trae contexto bajo demanda. Si no corre, el harness funciona igual.
