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
  funcionan en el cliente).

## Mods de terceros incluidas como archivo

Algunas mods van como archivo en este repositorio porque su fuente oficial no permite la descarga automática:

- **Zoltraak: Cinematic Edition** (`zoltraak_cinematic-forge-1.20.1-1.0.5.jar`), de Aling7788565, con licencia **AGPL-3.0**. Proyecto y código: https://www.curseforge.com/minecraft/mc-mods/frieren-flight-irons-spells. Se distribuye sin modificar.
