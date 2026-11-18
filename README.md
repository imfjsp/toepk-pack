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

## Servidor (Google Cloud + Pterodactyl)

- Minecraft: `34.176.132.83` · Panel: https://34-176-132-83.sslip.io
- Máquina e2-standard-4 (4 vCPU, 16 GB) en Santiago; Pterodactyl 1.x + Wings; servidor Forge 1.20.1-47.4.28 con 12 GB.
- Arranque: `start.sh` (copia en `servidor/start-pterodactyl.sh`) actualiza el pack con packwiz y abre Forge.
- Reinicio diario 06:00 (hora de Chile) para aplicar actualizaciones; copia del mundo cada 6 h (sin mods ni librerías).
- 5 mods de CurseForge no permiten descarga automática y se subieron a mano a `mods/`: Bosses'Rise x Epic Fight,
  EF Dual Wield Expansion, Epic Fight Extra Bow Restore (esta no va en el servidor), Epic Spells'n Wizards e ISS Elden
  Ring. Si se actualizan, hay que volver a subirlas.
- `servidor/crear.sh` crea la máquina desde Cloud Shell; `servidor/ptero.sh` instala Pterodactyl.

Si no hay internet o GitHub no responde, Prism avisa y puedes jugar igual con la versión que ya tienes.
