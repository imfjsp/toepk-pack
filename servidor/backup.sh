#!/bin/bash
# Copia comprimida del mundo; guarda las ultimas 12 (3 dias). Nunca toca el mundo en uso.
cd /opt/toepk || exit 1
[ -d world ] || exit 0
/opt/toepk/rcon.py "save-off" >/dev/null 2>&1; /opt/toepk/rcon.py "save-all flush" >/dev/null 2>&1; sleep 5
tar czf "backups/world-$(date +%Y%m%d-%H%M).tgz" world
/opt/toepk/rcon.py "save-on" >/dev/null 2>&1
ls -1t backups/world-*.tgz | tail -n +13 | xargs -r rm -f
chown -R minecraft:minecraft backups
