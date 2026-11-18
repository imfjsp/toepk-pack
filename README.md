# T'O EPK — actualizaciones automáticas

Este repositorio es la fuente de actualizaciones del modpack **T'O EPK** (Minecraft 1.20.1, Forge).
La instancia de Prism que te pasaron ya está configurada: cada vez que pulsas **Jugar**, Prism revisa este
repositorio y baja lo que cambió antes de abrir Minecraft. No tienes que hacer nada.

- `full/` y `lite/`: un pack por instancia (formato [packwiz](https://packwiz.infra.link/)). Las mods de Modrinth y
  CurseForge van como fichas que apuntan a su descarga oficial; aquí solo están los archivos que no tienen otra fuente
  (las mods propias de T'O EPK y unos pocos parches) y las configuraciones.

Direcciones de los packs (van en el comando previo al lanzamiento de la instancia):

- Full: `https://raw.githubusercontent.com/imfjsp/toepk-pack/main/full/pack.toml`
- Lite: `https://raw.githubusercontent.com/imfjsp/toepk-pack/main/lite/pack.toml`
- Servidor: `https://raw.githubusercontent.com/imfjsp/toepk-pack/main/server/pack.toml` (Lite sin las mods que solo
  funcionan en el cliente). `servidor/` tiene los scripts de la máquina: `setup.sh` instala Java 17, Forge y el
  servicio; `start.sh` actualiza el pack antes de cada arranque; hay copia del mundo cada 6 h y reinicio diario a las
  06:00 (hora de Chile) para aplicar actualizaciones.

Si no hay internet o GitHub no responde, Prism avisa y puedes jugar igual con la versión que ya tienes.
