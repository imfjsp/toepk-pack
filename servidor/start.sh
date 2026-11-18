#!/bin/bash
# Arranque: primero se pone al dia con el pack de GitHub (mods y configs), despues abre el servidor.
cd /opt/toepk
java -jar packwiz-installer-bootstrap.jar -g -s server \
  https://raw.githubusercontent.com/imfjsp/toepk-pack/main/server/pack.toml \
  || echo "[toepk] no se pudo actualizar el pack; arranco con lo que hay"
exec java @user_jvm_args.txt @libraries/net/minecraftforge/forge/1.20.1-47.4.28/unix_args.txt nogui
