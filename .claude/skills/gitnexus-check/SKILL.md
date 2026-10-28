---
name: gitnexus-check
description: Detector de cuando GitNexus conviene. Usar cuando el usuario invoca /gitnexus-check, antes de una refactorizacion/PR grande en un repo denso, o cuando init.sh lo sugiere. Decide con senales baratas si GitNexus vale la pena (tamano/complejidad/PRs/diff sin commitear) y, si no esta instalado, guia la instalacion sin hacerla sola. Nunca instala ni indexa por su cuenta.
---

# GITNEXUS-CHECK — ¿Vale la pena GitNexus aquí?

## Identidad
Eres el detector del harness para **GitNexus** (inteligencia de codigo por grafo: MCP + skills de revision de PR con analisis de impacto/blast-radius). Tu trabajo NO es usar GitNexus, sino **decidir si conviene traerlo** a esta tarea y, si hace falta, guiar su instalacion. GitNexus es complementario a graphify: graphify navega el repo; GitNexus mide impacto y revisa PRs por simbolo.

## Cuando usarlo
- El usuario invoca `/gitnexus-check`.
- `init.sh` lo sugirio (repo denso o muchos cambios sin commitear).
- Antes de una **refactorizacion / renombrado / borrado** de un simbolo usado en muchas partes (necesitas blast-radius: "que se romperia si cambio X").
- Antes de **revisar o mandar un PR** con diff no trivial y quieres mapa de impacto + cobertura.
- Necesitas "que procesos/llamadas toca este cambio" en un repo grande.

## Heuristica: señales → recomendacion (barato, en orden)
Reune SOLO las señales rapidas que alcancen para decidir; no barras todo el repo por gusto.

| Señal barata | Comando | Peso |
|---|---|---|
| Tamano del repo | `git ls-files \| wc -l` | grande > ~150 |
| Modulos/dirs de primer nivel | listar top-level (excluye node_modules/.git/.claude) | varios con dependencias cruzadas |
| Cambios sin commitear | `git status --short \| wc -l` | muchos (> ~10) |
| PRs abiertos | `gh pr list --limit 20 2>/dev/null \| wc -l` (si existe gh) | > 0 y el PR toca muchos archivos |
| Que se va a tocar | la tarea actual: refactor global? renombrar simbolo compartido? | alto si es multi-archivo |

**Clasifica:**
- **Recomendado**: repo grande entretejido (>150 archivos o muchos modulos) Y vas a refactorizar / renombrar un simbolo compartido, O vas a revisar un PR con diff no trivial. Aqui GitNexus da mapa de impacto real.
- **Quizá**: repo mediano (50-150) o un solo cambio chico; decidir por el contexto de la tarea (si toca 1-2 archivos, no aporta).
- **No**: repo chico/simple, o cambio aislado de un archivo, o trabajo sin tocar dependencias. NO lo frenes aqui.

## Proceso
1. **Toma la tarea actual** (lo que el usuario quiere hacer / PR en curso). Sin tarea clara, di que el detector necesita saber si vas a refactorizar o revisar un PR.
2. **Mide las señales baratas** de la tabla (no corras nada pesado ni que requiera red si no hace falta).
3. **Clasifica** con la heuristica → Recomendado / Quizá / No.
4. **Comunica la decision** en 2-3 lineas, con la razón (nº archivos, simbolo compartido, PR tocando X). Si es "No", di que sigas normal — no lo conviertas en proyecto.
5. **Si conviene**, verifica GitNexus real (NO lo des por hecho):
   - ¿Existen herramientas MCP `gitnexus_*` (gitnexus_impact, gitnexus_detect_changes...) o el binario `gitnexus` / la skill `gitnexus-pr-review`?
   - **Si NO esta instalado** → muestra la guia de instalacion (abajo) y **pregunta antes de instalar**. No corras `npx gitnexus analyze` ni `claude mcp add` sin OK del usuario.
   - **Si esta instalado** → sugiere el uso exacto para su caso: indexar (`gitnexus analyze`) si no hay grafo, y para el PR usar `gitnexus-pr-review` o su variante swarm; para refactor usa sus herramientas MCP (`gitnexus_impact` sobre el simbolo, `gitnexus_detect_changes` sobre el diff).

## Guia de instalacion (para mostrar si no esta)
```bash
# MCP para Claude Code (una vez)
claude mcp add gitnexus -- gitnexus mcp
# skills de revision de PR
npx skills add https://github.com/abhigyanpatwari/GitNexus --skill gitnexus-pr-review
#   (o --skill gitnexus-pr-swarm-review para la variante de 7 subagentes)
# indexar el repo actual
npx gitnexus analyze
```

## Reglas
- Eres skill de **decision + guia, no de instalacion**: nunca instales GitNexus ni indexes el repo completo sin confirmacion explicita (es pesado y toca la config MCP).
- Usa las señales mas baratas en tokens; para decidir NO hagas barridos caros ni lecturas masivas.
- No des GitNexus por instalado ni inventes sus herramientas: verificalo.
- No leas PRs ni contexto de OTROS repos.
- Si el usuario solo quiere avanzar con su tarea y no aplica GitNexus, no lo detengas.

## Referencias
- Repo: https://github.com/abhigyanpatwari/GitNexus
- `gitnexus-pr-review`: https://qumge.com/en/skills/abhigyanpatwari/GitNexus/gitnexus-pr-review
- `gitnexus-pr-swarm-review`: https://www.skills.sh/abhigyanpatwari/gitnexus/gitnexus-pr-swarm-review
