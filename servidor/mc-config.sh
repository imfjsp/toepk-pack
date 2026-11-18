#!/bin/bash
# T'O EPK - deja listo el servidor de Minecraft creado en Pterodactyl (correr como root en la maquina, una vez
# creado el servidor en el panel con el huevo "Forge Minecraft"):
#   curl -sL https://raw.githubusercontent.com/imfjsp/toepk-pack/main/servidor/mc-config.sh | sudo bash
# - comando de arranque: actualiza el pack de GitHub (packwiz) y abre Forge con los argumentos de Aikar
# - eula.txt (aceptado por el dueno), server.properties con valores para el pack (solo si no existe)
set -euo pipefail
PACK=https://raw.githubusercontent.com/imfjsp/toepk-pack/main/server/pack.toml
UUID=$(mysql -N -u root panel -e "SELECT s.uuid FROM servers s JOIN eggs e ON e.id=s.egg_id WHERE e.name LIKE '%Forge%' ORDER BY s.id DESC LIMIT 1")
[ -n "$UUID" ] || { echo "no hay ningun servidor Forge en el panel"; exit 1; }
SID=$(mysql -N -u root panel -e "SELECT id FROM servers WHERE uuid='$UUID'")
MEM=$(mysql -N -u root panel -e "SELECT memory FROM servers WHERE uuid='$UUID'")
DIR=/var/lib/pterodactyl/volumes/$UUID
echo "servidor $SID ($UUID), memoria ${MEM} MB, carpeta $DIR"

STARTUP='[ -f packwiz-installer-bootstrap.jar ] || curl -fsSLo packwiz-installer-bootstrap.jar https://github.com/packwiz/packwiz-installer-bootstrap/releases/latest/download/packwiz-installer-bootstrap.jar; java -jar packwiz-installer-bootstrap.jar -g -s server '"$PACK"' || echo "[toepk] no se pudo actualizar el pack"; java -Xms{{SERVER_MEMORY}}M -Xmx{{SERVER_MEMORY}}M -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dc2me.disableModule.notickvd=true -Dterminal.jline=false -Dterminal.ansi=true @libraries/net/minecraftforge/forge/1.20.1-47.4.28/unix_args.txt nogui'
# memoria de Java: la del servidor menos ~1,5 GB para lo que Java usa fuera del heap
HEAP=$(( MEM > 4096 ? MEM - 1536 : MEM ))
STARTUP=${STARTUP//\{\{SERVER_MEMORY\}\}/$HEAP}
mysql -u root panel -e "UPDATE servers SET startup=FROM_BASE64('$(printf '%s' "$STARTUP" | base64 -w0)') WHERE id=$SID"
mysql -N -u root panel -e "SELECT LEFT(startup, 160) FROM servers WHERE id=$SID"

mkdir -p "$DIR"
echo "eula=true" > "$DIR/eula.txt"
if [ ! -f "$DIR/server.properties" ]; then
cat > "$DIR/server.properties" <<'PROPS'
motd=§6T'O EPK §7- Epic Fight RPG
server-port=25565
max-players=12
view-distance=8
simulation-distance=6
spawn-protection=0
allow-flight=true
difficulty=normal
online-mode=true
sync-chunk-writes=false
max-tick-time=-1
PROPS
fi
chown -R 988:988 "$DIR" 2>/dev/null || chown -R pterodactyl:pterodactyl "$DIR" 2>/dev/null || true
echo "listo: arranca el servidor desde el panel (la primera vez baja ~200 mods)"
