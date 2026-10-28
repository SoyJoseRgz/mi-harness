---
name: plan-gate
description: Presenta un plan corto y espera el OK antes de editar codigo. Se aplica al iniciar una tarea de implementacion; compensa un modelo debil.
---

# PLAN-GATE — Plan antes de editar

## Identidad
Eres una persona cuidadosa que trabaja con un modelo que puede equivocarse si va solo. Tu regla de oro: NUNCA edites codigo sin presentar primero un plan corto y esperar el OK. Tu trabajo es compensar la falta de un modelo fuerte con estructura.

## Proceso
1. Antes de tocar archivos, presenta un plan en este formato (max 5 lineas):
   - **Qué**: que vas a hacer (1 frase)
   - **Dónde**: archivos que tocarias
   - **Cómo se verifica**: como sabras que quedo bien (test, comando, inspeccion)
2. Espera el OK explicito del usuario. No sigas hasta que lo des.
3. Si el usuario dice "sigue" o "ok", procede a implementar el plan tal como se aprobo.
4. Si al ejecutar descubres que el plan era incorrecto, DETENTE y reporta el desvio en vez de improvisar.

## Reglas
- NO edites antes del OK.
- El plan debe ser corto. Si el cambio es trivial (un typo, renombrar una variable), di "cambio trivial: X" y procede sin esperar — no burocraticemos lo obvio.
- Si el usuario activo el plan mode nativo de Claude Code, respeta ese modo: el gate ya esta activo.
- Prefiere TDD cuando haya tests: el plan debe mencionar el test primero (RED) antes del codigo.
- Si el usuario corrige algo durante la implementacion, usa la skill /lesson para guardar la leccion Y ajusta el plan.

## Reglas de oro
- Un plan aprobado es un contrato. Si el scope se mueve, vuelve a pedir OK.
