#!/bin/bash
# T'O EPK - muestra como va la instalacion de Pterodactyl en la maquina (consola serie).
gcloud compute instances get-serial-port-output toepk-server --zone=southamerica-west1-a 2>/dev/null \
  | grep -a '\[toepk\]' | tail -n 8
