#!/bin/bash
# T'O EPK - crea el servidor en Google Cloud desde Cloud Shell (proyecto activo).
#   bash <(curl -sL https://raw.githubusercontent.com/imfjsp/toepk-pack/main/servidor/crear.sh)
# Si algo ya existe, no lo toca. La instalacion de Pterodactyl sigue sola dentro de la maquina (~10-15 min);
# para ver como va:  bash <(curl -sL https://raw.githubusercontent.com/imfjsp/toepk-pack/main/servidor/estado.sh)
set -euo pipefail
REGION=southamerica-west1
ZONE=southamerica-west1-a
VM=toepk-server
echo "== proyecto: $(gcloud config get-value project 2>/dev/null)"
echo "== activando Compute Engine (puede tardar 1-2 min la primera vez)"
gcloud services enable compute.googleapis.com
if ! gcloud compute addresses describe toepk-ip --region=$REGION >/dev/null 2>&1; then
  echo "== reservando IP fija"
  gcloud compute addresses create toepk-ip --region=$REGION
fi
IP=$(gcloud compute addresses describe toepk-ip --region=$REGION --format='value(address)')
if ! gcloud compute firewall-rules describe toepk-puertos >/dev/null 2>&1; then
  echo "== abriendo puertos 25565 (Minecraft), 80/443 (panel), 8080/2022 (Wings)"
  gcloud compute firewall-rules create toepk-puertos --network=default --direction=INGRESS \
    --allow=tcp:25565,tcp:80,tcp:443,tcp:8080,tcp:2022 --target-tags=toepk --description="T'O EPK"
fi
if ! gcloud compute instances describe $VM --zone=$ZONE >/dev/null 2>&1; then
  echo "== creando la maquina e2-standard-4 (4 vCPU, 16 GB) en Santiago"
  gcloud compute instances create $VM --zone=$ZONE --machine-type=e2-standard-4 \
    --image-family=ubuntu-2404-lts-amd64 --image-project=ubuntu-os-cloud \
    --boot-disk-size=60GB --boot-disk-type=pd-balanced --address="$IP" --tags=toepk \
    --metadata=startup-script=$'#!/bin/bash\ncurl -fsSL https://raw.githubusercontent.com/imfjsp/toepk-pack/main/servidor/ptero.sh | bash'
fi
echo
echo "== LISTO. IP: $IP"
echo "== Panel (en ~15 min): https://${IP//./-}.sslip.io"
echo "== Minecraft: $IP:25565"
