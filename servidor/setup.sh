#!/bin/bash
# T'O EPK - instala o pone al dia el servidor (Ubuntu). Lo corre el startup-script de la VM en cada arranque.
# Es idempotente: lo ya instalado no se toca; el mundo y server.properties nunca se pisan.
set -euo pipefail
REPO=https://raw.githubusercontent.com/imfjsp/toepk-pack/main
DIR=/opt/toepk
MC=1.20.1
FORGE=47.4.28
log() { echo "[toepk-setup] $*"; }

export DEBIAN_FRONTEND=noninteractive
if ! command -v java >/dev/null || ! java -version 2>&1 | grep -q '"17'; then
  log "instalando Java 17"
  apt-get update -q && apt-get install -y -q openjdk-17-jre-headless curl python3 >/dev/null
fi
id minecraft >/dev/null 2>&1 || useradd --system --home "$DIR" --shell /usr/sbin/nologin minecraft
mkdir -p "$DIR/backups"

# swap de 4 GB para que un pico de memoria no mate el servidor
if ! swapon --show | grep -q /swapfile; then
  [ -f /swapfile ] || { fallocate -l 4G /swapfile && chmod 600 /swapfile && mkswap /swapfile >/dev/null; }
  swapon /swapfile || true
  grep -q /swapfile /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

cd "$DIR"
if [ ! -f "libraries/net/minecraftforge/forge/$MC-$FORGE/unix_args.txt" ]; then
  log "instalando Forge $MC-$FORGE"
  curl -fsSL -o forge-installer.jar "https://maven.minecraftforge.net/net/minecraftforge/forge/$MC-$FORGE/forge-$MC-$FORGE-installer.jar"
  java -jar forge-installer.jar --installServer >/dev/null
  mv -f forge-installer.jar.log "$DIR/backups/forge-installer.log" 2>/dev/null || true
fi

# scripts y servicio (siempre la ultima version del repositorio)
for f in start.sh rcon.py backup.sh; do curl -fsSL -o "$f" "$REPO/servidor/$f"; done
chmod +x start.sh rcon.py backup.sh
curl -fsSL -o /etc/systemd/system/toepk.service "$REPO/servidor/toepk.service"
curl -fsSL -o /etc/systemd/system/toepk-reinicio.service "$REPO/servidor/toepk-reinicio.service"
curl -fsSL -o /etc/systemd/system/toepk-reinicio.timer "$REPO/servidor/toepk-reinicio.timer"
curl -fsSL -o /etc/systemd/system/toepk-backup.service "$REPO/servidor/toepk-backup.service"
curl -fsSL -o /etc/systemd/system/toepk-backup.timer "$REPO/servidor/toepk-backup.timer"
ln -sf "$DIR/rcon.py" /usr/local/bin/toepk
[ -f packwiz-installer-bootstrap.jar ] || curl -fsSL -o packwiz-installer-bootstrap.jar \
  https://github.com/packwiz/packwiz-installer-bootstrap/releases/latest/download/packwiz-installer-bootstrap.jar

# memoria para Java: lo que tenga la maquina menos ~4 GB para el sistema
TOTAL=$(awk '/MemTotal/ {print int($2/1048576)}' /proc/meminfo)
HEAP=$(( TOTAL > 8 ? TOTAL - 4 : 4 ))
cat > user_jvm_args.txt <<ARGS
-Xms${HEAP}G
-Xmx${HEAP}G
-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions
-XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40
-XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4
-XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5
-XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dc2me.disableModule.notickvd=true
ARGS

# server.properties: solo la primera vez (despues lo que cambies tu se respeta)
if [ ! -f server.properties ]; then
  PASS=$(head -c 18 /dev/urandom | base64 | tr -dc 'A-Za-z0-9')
  cat > server.properties <<PROPS
motd=§6T'O EPK §7- Epic Fight RPG
max-players=12
view-distance=8
simulation-distance=6
spawn-protection=0
allow-flight=true
difficulty=normal
online-mode=true
enable-rcon=true
rcon.port=25575
rcon.password=$PASS
broadcast-rcon-to-ops=false
sync-chunk-writes=false
max-tick-time=-1
PROPS
fi
[ -f eula.txt ] || echo "eula=${TOEPK_EULA:-false}" > eula.txt

chown -R minecraft:minecraft "$DIR"
systemctl daemon-reload
systemctl enable --now toepk-backup.timer toepk-reinicio.timer >/dev/null
if grep -q 'eula=true' eula.txt; then
  systemctl enable toepk.service >/dev/null
  systemctl is-active --quiet toepk.service || systemctl start toepk.service
  log "servidor en marcha"
else
  log "falta aceptar el EULA de Minecraft: echo eula=true > $DIR/eula.txt && systemctl enable --now toepk"
fi
