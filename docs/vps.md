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
CFG_TGBRIDGE_BLUEMAP_URL=https://map.example.com
MC_INIT_MEMORY=6G
MC_MAX_MEMORY=16G
USE_AIKAR_FLAGS=true
```

The Compose file uses `ghcr.io/alexcawl/mc-create-aeronautics-server:latest` when the server should track the current published build. Change the Minecraft service image to an immutable tag such as `ghcr.io/alexcawl/mc-create-aeronautics-server:v1` when the server should stay pinned.

`MC_INIT_MEMORY` controls the initial Minecraft JVM heap size, and `MC_MAX_MEMORY` controls the maximum heap size. For a 32 GB VPS, `MC_INIT_MEMORY=6G` and `MC_MAX_MEMORY=16G` leave room for native memory, Docker, monitoring, OS cache, and world-generation worker threads.

The current Compose file exposes `USE_AIKAR_FLAGS` and the committed default enables it:

```dotenv
USE_AIKAR_FLAGS=true
```

With `itzg/minecraft-server:java21`, this selects Aikar's G1GC-oriented JVM flags. Keep `USE_AIKAR_FLAGS=false` if you need to run the JVM without those bundled flags. The deployment currently does not pass custom `JVM_XX_OPTS`/`JVM_OPTS` through Compose; add those environment variables to `compose.yaml` first if a future deployment needs a different garbage collector such as ZGC.

Do not enable Aikar flags and ZGC together, because Aikar's bundled flags select G1GC.

Minecraft is published on TCP `25565`. Sable also uses UDP `25565` for its low-latency networking pipeline. BlueMap is published on TCP `8100`. Simple Voice Chat is published on UDP `24454`. The VPS firewall and provider firewall must allow TCP `25565`, UDP `25565`, TCP `8100`, and UDP `24454` when players should use all server features from the internet.

The server runs with `online-mode=false`, so players without a licensed Microsoft/Mojang session can join. Use a whitelist and ops list intentionally because Minecraft account identity is no longer verified by Mojang.

## Telegram Alerts

TGBridge is included in the Minecraft server image and reads its runtime config from environment-expanded files. Keep the real bot token in the untracked `.env` file and set:

```dotenv
CFG_TGBRIDGE_BOT_TOKEN=123456789:bot-token-from-botfather
CFG_TGBRIDGE_CHAT_ID=-1001234567890
CFG_TGBRIDGE_TOPIC_ID=123
CFG_TGBRIDGE_BLUEMAP_URL=https://map.example.com
```

Do not commit real Telegram credentials. For a group or channel, `CFG_TGBRIDGE_CHAT_ID` is usually negative. If the bot posts into a forum topic, set `CFG_TGBRIDGE_TOPIC_ID` to that topic id. `CFG_TGBRIDGE_BLUEMAP_URL` must be the public URL that Telegram users can open, for example a domain or `http://<vps-ip>:8100`.

## Server Commands

Start or update the server:

```sh
docker compose pull minecraft
docker compose up -d minecraft
```

Start or update the full stack:

```sh
docker compose pull
docker compose up -d
```

The server image contains the packwiz metadata and synchronizes `/data/mods` on startup. A normal image pull and Compose recreate is enough to refresh server-side mods. `docker compose down -v` does not delete `data/`, because `data/` is a bind-mounted directory in the repository, not a Docker named volume. Do not use `down -v` unless you explicitly want to delete named monitoring and RCON volumes.

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

Prometheus, Grafana, Loki, Alloy, and RCON Web Admin store runtime state in Docker named volumes. These volumes are disk-backed Docker volumes, not tmpfs memory volumes, but Linux may cache their disk I/O in RAM as reclaimable page cache.

## Backups

The `backups` service runs `itzg/mc-backup:latest` and writes local tar archives to `backups/`. It uses the existing internal RCON connection to flush world data, pause saves during the archive, and resume saves after the backup completes. The service starts its daily schedule 15 minutes after startup and keeps up to 14 days or 14 archives.

Run an on-demand backup:

```sh
docker compose exec backups backup now
```

Follow backup logs:

```sh
docker compose logs -f backups
```

Check local archives:

```sh
ls -lh backups
```

Restore only into an empty `data/` directory. Stop the server first, move or recreate `data/`, then run:

```sh
docker compose down
mv data "data.before-restore.$(date +%Y%m%d-%H%M%S)"
mkdir data
docker run --rm \
  -v "$PWD/data:/data" \
  -v "$PWD/backups:/backups:ro" \
  --entrypoint restore-tar-backup \
  itzg/mc-backup:latest
docker compose up -d
```
