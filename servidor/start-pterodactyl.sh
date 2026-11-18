#!/bin/bash
# T'O EPK - arranque del servidor dentro de Pterodactyl (es /home/container/start.sh; comando de arranque del
# panel: "bash start.sh"). Pone al dia mods y configs desde GitHub (packwiz) y abre Forge.
# Si GitHub no responde, arranca con lo que ya hay; si no hay ninguna mod, no arranca (evita un mundo sin mods).
cd /home/container
export HOME=/home/container
echo "[toepk] actualizando el pack desde GitHub..."
java -Duser.home=/home/container -jar packwiz-installer-bootstrap.jar -g -s server https://raw.githubusercontent.com/imfjsp/toepk-pack/main/server/pack.toml 2>&1 | tee packwiz.log
if ! ls mods/*.jar >/dev/null 2>&1; then
  echo "[toepk] no hay mods: no arranco el servidor (revisa packwiz.log)"
  exit 1
fi
echo "[toepk] $(ls mods/*.jar | wc -l) mods; arrancando Forge"
exec java -Duser.home=/home/container -Xms10240M -Xmx10240M -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 \
  -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 \
  -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 \
  -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 \
  -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dc2me.disableModule.notickvd=true \
  -Dterminal.jline=false -Dterminal.ansi=true @libraries/net/minecraftforge/forge/1.20.1-47.4.28/unix_args.txt nogui
