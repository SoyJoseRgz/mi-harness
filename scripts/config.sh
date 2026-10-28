#!/bin/bash
# config.sh — Parametros por proyecto de la plantilla harness.
# NO se ejecuta directo: se "sourcea" desde init.sh / exit.sh / otros scripts.
# Copia este archivo a cada proyecto y ajusta los valores.

# Nombre legible del proyecto (para headers y mensajes).
HARNESS_NAME="mi proyecto"

# Stack principal (para contexto y mensajes). Libre de formato: "web", "python CLI", "mobile", etc.
HARNESS_STACK="web"

# Zona horaria del proyecto en formato IANA (p.ej. America/Mexico_City, Europe/Madrid).
HARNESS_TZ="America/Mexico_City"

# Modelo por defecto. Solo informativo — Claude Code usa tu config real.
HARNESS_MODEL="deepseek-v4-flash"

# Gate duro de plan: pide confirmacion en el primer edit de cada sesion. "on" | "off"
HARNESS_PLAN_GATE="on"

# claude-mem (enhancer de recall, OPCIONAL — nunca dependencia).
# Si claude-mem no corre, el harness funciona igual. Host/puerto del worker local.
HARNESS_CLAUDE_MEM_HOST="127.0.0.1"
HARNESS_CLAUDE_MEM_PORT="37777"
