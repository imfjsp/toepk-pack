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
# JVM: G1 afinado para un servidor de mods grande en 4 vCPU (flags de Aikar + brucethemoose): pausas cortas,
# paginas grandes de memoria, dedup de strings y cache de codigo amplia.
# Heap 10 GB dentro del limite de 12 GB del contenedor (el resto es metaspace, hilos y buffers nativos).
MEM="-Xms10240M -Xmx10240M"
JVM="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=130 -XX:+UnlockExperimentalVMOptions
 -XX:+UnlockDiagnosticVMOptions -XX:+DisableExplicitGC -XX:+UseTransparentHugePages
 -XX:G1NewSizePercent=28 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=16M -XX:G1ReservePercent=20
 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=3 -XX:InitiatingHeapOccupancyPercent=15
 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=0 -XX:G1SATBBufferEnqueueingThresholdPercent=30
 -XX:G1ConcMarkStepDurationMillis=5 -XX:G1ConcRSHotCardLimit=16 -XX:G1ConcRefinementServiceIntervalMillis=150
 -XX:ConcGCThreads=2 -XX:SurvivorRatio=32 -XX:MaxTenuringThreshold=1 -XX:+UseStringDeduplication
 -XX:+UseFastUnorderedTimeStamps -XX:AllocatePrefetchStyle=3 -XX:+PerfDisableSharedMem
 -XX:ReservedCodeCacheSize=400M -XX:NonNMethodCodeHeapSize=12M -XX:ProfiledCodeHeapSize=194M -XX:NonProfiledCodeHeapSize=194M
 -XX:MetaspaceSize=512M -Djava.net.preferIPv4Stack=true"
# si esta Java no acepta alguna opcion, se vuelve a las de Aikar (las de siempre) en vez de no arrancar
if ! java $MEM $JVM -version >/dev/null 2>&1; then
  echo "[toepk] Java rechazo las opciones afinadas; uso las de Aikar"
  JVM="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions
 -XX:+DisableExplicitGC -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20
 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90
 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1"
fi
exec java -Duser.home=/home/container $MEM $JVM -Dc2me.disableModule.notickvd=true -Dterminal.jline=false \
  -Dterminal.ansi=true @libraries/net/minecraftforge/forge/1.20.1-47.4.28/unix_args.txt nogui
