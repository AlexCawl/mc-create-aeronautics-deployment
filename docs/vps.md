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
CFG_TGBRIDGE_BOT_TOKEN=123456789:bot-token-from-botfather
CFG_TGBRIDGE_CHAT_ID=-1001234567890
CFG_TGBRIDGE_TOPIC_ID=123
MC_MEMORY=6G
USE_AIKAR_FLAGS=false
MC_JVM_XX_OPTS=-XX:+UseZGC
```

The Compose file uses `ghcr.io/alexcawl/mc-create-aeronautics-server:latest` when the server should track the current published build. Change the Minecraft service image to an immutable tag such as `ghcr.io/alexcawl/mc-create-aeronautics-server:v1` when the server should stay pinned.

`MC_MEMORY` controls the Minecraft JVM heap size. `MC_JVM_XX_OPTS` is passed to the JVM as `-XX` options and can be used to choose the garbage collector. The default uses ZGC:

```dotenv
USE_AIKAR_FLAGS=false
MC_JVM_XX_OPTS=-XX:+UseZGC
```

Do not enable `USE_AIKAR_FLAGS` at the same time as ZGC, because Aikar's bundled flags select G1GC. To switch back to Aikar/G1GC, use:

```dotenv
USE_AIKAR_FLAGS=true
MC_JVM_XX_OPTS=
```

Minecraft is published on TCP `25565`. Sable also uses UDP `25565` for its low-latency networking pipeline. Simple Voice Chat is published on UDP `24454`. The VPS firewall and provider firewall must allow TCP `25565`, UDP `25565`, and UDP `24454` when players should use all server features from the internet.

The server runs with `online-mode=false`, so players without a licensed Microsoft/Mojang session can join. Use a whitelist and ops list intentionally because Minecraft account identity is no longer verified by Mojang.

## Telegram Alerts

TGBridge is included in the Minecraft server image and reads its runtime config from environment-expanded files. Keep the real bot token in the untracked `.env` file and set:

```dotenv
CFG_TGBRIDGE_BOT_TOKEN=123456789:bot-token-from-botfather
CFG_TGBRIDGE_CHAT_ID=-1001234567890
CFG_TGBRIDGE_TOPIC_ID=123
```

Do not commit real Telegram credentials. For a group or channel, `CFG_TGBRIDGE_CHAT_ID` is usually negative. If the bot posts into a forum topic, set `CFG_TGBRIDGE_TOPIC_ID` to that topic id.

## Server Commands

Start or update the server:

```sh
docker compose pull minecraft
docker compose down
docker compose up -d
```

The server image contains the packwiz metadata and synchronizes `/data/mods` on startup. A normal image pull and Compose restart is enough to refresh server-side mods. `docker compose down -v` does not delete `data/`, because `data/` is a bind-mounted directory in the repository, not a Docker named volume.

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
