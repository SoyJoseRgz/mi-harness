# CLAUDE.md — Harness (plantilla multi-proyecto)

Este repo es una **plantilla de harness** para Claude Code sobre DeepSeek (modelo barato pero distraído): le pone carriles (plan antes de editar, tests primero, lecciones) para entregar calidad. Cuando copies esta carpeta a un **proyecto real**, edita `scripts/config.sh` y pega debajo el contexto de ESE proyecto.

## Flujo de sesión

- **Iniciar:** `./scripts/init.sh` — muestra el estado y abre Claude Code. Si ya estás dentro de Claude Code **no abre sesión anidada** (solo reporta). Forzar "solo reporte" con `HARNESS_NO_LAUNCH=1`.
- **Cerrar:** `./scripts/exit.sh "qué hiciste"` — guarda resumen en `.claude/summary/` y self-audit en `.claude/audit/` (o lo hace el hook `SessionEnd` solo).
- **Config por proyecto:** `scripts/config.sh` → `HARNESS_NAME`, `HARNESS_STACK`, `HARNESS_TZ`, `HARNESS_PLAN_GATE`.

## Reglas de trabajo (los skills viajan con el repo)

1. **Antes de editar** → presenta plan corto y espera OK (`/plan-gate`, hook `PreToolUse`; apagable con `HARNESS_PLAN_GATE=off`).
2. **Tests primero** → `/tdd-red` escribe el test que falla; `/tdd-green` implementa el mínimo para que pase.
3. **Simplifica** → `/ponytail`: lo más perezoso que todavía funciona (frena sobre-ingeniería).
4. **Corrige con lección** → cuando corrijas a Claude, di `/lesson <tu corrección>` para no repetirla (se guarda en `.claude/lessons/`).
5. **Contexto pasado** → `/recall <tema>` trae trabajo relevante desde claude-mem (opcional).
6. **Antes de commitear** → `/code-review` revisa el diff con ojos frescos.
7. **Comandos destructivos** → `git-guardrails` pide confirmación literal.
8. **Automejora** → `/self-audit` mide si repites la misma corrección en días distintos.

## Notas

- **Este harness NO es el producto.** La memoria real del proyecto la define cada proyecto: `scripts/config.sh` y la sección de contexto de abajo. Nunca asumas que el harness es lo que estás construyendo.
- `claude-mem` (memoria global) y `/lesson` (lecciones por proyecto) conviven sin duplicarse.
- Los hooks (`SessionEnd`, `PreToolUse`) están registrados en `.claude/settings.json` y corren solos.

---

## CONTEXTO DEL PROYECTO REAL

> (Al copiar este harness a un proyecto, borra el marcador y describe aquí ESE proyecto: qué es, stack, decisiones vinculantes, fuente de verdad. Ejemplo: "App X — Next.js + Prisma. PRD en `prd.md`, decisiones en `docs/architecture.md`.")
