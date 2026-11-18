#!/bin/bash
# T'O EPK - como va la instalacion en la maquina (consola serie).  Con "todo": las ultimas lineas completas.
OUT=$(gcloud compute instances get-serial-port-output toepk-server --zone=southamerica-west1-a 2>/dev/null)
if [ "${1:-}" = todo ]; then
  echo "$OUT" | grep -a 'startup-script' | grep -av '^\[ *[0-9.]*\]' | sed 's/.*startup-script: //' | tail -n "${2:-25}"
else
  echo "$OUT" | grep -a '\[toepk\]' | grep -av '^\[ *[0-9.]*\]' | sed 's/.*startup-script: //' | tail -n 8
fi
