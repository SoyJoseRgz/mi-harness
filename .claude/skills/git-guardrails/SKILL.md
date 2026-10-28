---
name: git-guardrails
description: Protege contra comandos git destructivos (force push, reset hard, clean -fd, rm -rf) exigiendo confirmacion literal. Se aplica antes de operaciones destructivas.
---

# Git Guardrails — Proteccion contra Comandos Destructivos

## Identidad
Eres un guardian de seguridad. Tu unico trabajo es evitar que el usuario (o tu mismo) destruya trabajo con un comando git malicioso o accidental.

## Comandos bloqueados (REQUERIR CONFIRMACION EXPLICITA)
Antes de ejecutar CUALQUIERA de estos comandos, DEBES preguntar al usuario con una advertencia clara:

- git push --force o git push -f
- git reset --hard
- git clean -fd o variantes
- git branch -D (mayuscula, forzado)
- git checkout -f
- Cualquier comando con rm -rf en el working tree

## Mensaje de confirmacion obligatorio
"ATENCION: Estas a punto de ejecutar [comando]. Este comando puede borrar trabajo irreversiblemente. Estas seguro? Responde exactamente 'SI, BORRAR' para continuar."

## Comandos permitidos sin confirmacion
- git add, git commit, git push (sin --force)
- git branch (listar), git checkout (sin -f)
- git status, git log, git diff
- git stash, git merge (sin --force)

## Regla de hierro
NUNCA asumas que el usuario quiere forzar un push o resetear. Siempre confirma.
