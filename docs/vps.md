# VPS Operations

Clone the repository on the VPS and keep the server rooted in that checkout:

```sh
git clone <repo-url> mc-create-aeronautics-deployment
cd mc-create-aeronautics-deployment
```

## Configuration

Create `.env` locally on the VPS from the committed defaults. This file is intentionally ignored and should contain the real passwords and local tuning.

```sh
cp .env.defaults .env
```

Then edit the required values:

```dotenv
RCON_PASSWORD=change-me
GRAFANA_ADMIN_PASSWORD=change-me-too
RCON_WEB_PASSWORD=change-me-too
MC_MEMORY=6G
USE_AIKAR_FLAGS=true
```

The Compose file uses `ghcr.io/alexcawl/mc-create-aeronautics-server:latest` when the server should track the current published build. Change the Minecraft service image to an immutable tag such as `ghcr.io/alexcawl/mc-create-aeronautics-server:v1` when the server should stay pinned.

`MC_MEMORY` controls the Minecraft JVM heap size. `USE_AIKAR_FLAGS=true` enables itzg's bundled Aikar JVM flags.

Minecraft is published on TCP `25565`. Sable also uses UDP `25565` for its low-latency networking pipeline. Simple Voice Chat is published on UDP `24454`. The VPS firewall and provider firewall must allow TCP `25565`, UDP `25565`, and UDP `24454` when players should use all server features from the internet.

The server runs with `online-mode=false`, so players without a licensed Microsoft/Mojang session can join. Use a whitelist and ops list intentionally because Minecraft account identity is no longer verified by Mojang.

## Server Commands

Start or update the server:

```sh
scripts/run_minecraft.sh
```

Force reinstall the server mod jars from the packwiz metadata bundled in the server image:

```sh
scripts/run_minecraft.sh --reinstall-mods
```

This deletes `data/mods/*.jar` before starting the container. The server image also sets `REMOVE_OLD_MODS=TRUE`, so normal starts synchronize `/data/mods` with the packwiz server install. `docker compose down -v` does not delete `data/`, because `data/` is a bind-mounted directory in the repository, not a Docker named volume.

Stop it:

```sh
docker compose down
```

Follow logs:

```sh
docker compose logs -f minecraft
```

Open Grafana through an SSH tunnel:

```sh
ssh -L 3000:127.0.0.1:3000 <user>@<vps-host>
```

Then open `http://localhost:3000`.

Open RCON Web Admin through an SSH tunnel:

```sh
ssh -L 4326:127.0.0.1:4326 -L 4327:127.0.0.1:4327 <user>@<vps-host>
```

Then open `http://localhost:4326`.

## Runtime Data

`data/` is mounted as `/data` in the container and contains world data, logs, crash reports, downloaded jars, generated configs, and AutoModpack runtime state.

Do not commit `data/`.

Prometheus, Grafana, Loki, Alloy, and RCON Web Admin store runtime state in Docker named volumes.

## Backups

Runtime state is in `data/`. Back up at least:

```text
data/world/
data/world_nether/
data/world_the_end/
data/server.properties
data/ops.json
data/whitelist.json
```
