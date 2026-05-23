# Monitoring

Monitoring is part of the default Docker Compose stack.

The setup combines the official `itzg/mc-monitor` Prometheus example with an in-server Prometheus exporter mod:

- `monitor` runs `itzg/mc-monitor` and exports Minecraft status metrics.
- `Prometheus Exporter` runs inside the NeoForge server and exports Minecraft tick, chunk, entity, and JVM metrics.
- `cadvisor` exports Docker container metrics.
- `prometheus` stores time-series data.
- `grafana` provides dashboards.
- `rcon` provides a localhost-bound RCON Web Admin for Minecraft commands.
- `loki` stores recent container logs.
- `alloy` collects Docker container logs and sends them to Loki.
- `spark` remains a Minecraft diagnostics tool for profiling and health reports.

## Access

Grafana is bound to VPS localhost only:

```text
127.0.0.1:3000
```

Open it through an SSH tunnel:

```sh
ssh -L 3000:127.0.0.1:3000 <user>@<vps-host>
```

Then open:

```text
http://localhost:3000
```

RCON Web Admin is also bound to VPS localhost only:

```text
127.0.0.1:4326
127.0.0.1:4327
```

Open it through an SSH tunnel:

```sh
ssh -L 4326:127.0.0.1:4326 -L 4327:127.0.0.1:4327 <user>@<vps-host>
```

Then open:

```text
http://localhost:4326
```

## Configuration

Set these values in the VPS `.env`:

```sh
GRAFANA_ADMIN_PASSWORD=change-me
RCON_WEB_PASSWORD=change-me-too
```

`GRAFANA_ADMIN_PASSWORD` and `RCON_WEB_PASSWORD` are required.

Infrastructure images are pinned in Compose so updates are reproducible where upstream publishes stable multi-arch tags:

- `itzg/mc-monitor:0.16.5`
- `itzg/rcon:latest`
- `ghcr.io/google/cadvisor:v0.57.0`
- `prom/prometheus:v3.11.3`
- `grafana/loki:3.7.2`
- `grafana/alloy:v1.16.1`
- `grafana/grafana-oss:13.0.1`

Grafana update checks, usage reporting, and plugin preinstall behavior are disabled in Compose to keep startup logs deterministic and avoid downloading unused bundled plugins.

`itzg/rcon` uses `latest` because its current versioned tags are published for `amd64` only, while `latest` is multi-arch.

## Metrics

`mc-monitor` exports:

- `minecraft_status_healthy`
- `minecraft_status_response_time_seconds`
- `minecraft_status_players_online_count`
- `minecraft_status_players_max_count`

The `Prometheus Exporter` mod exports:

- `mc_server_tick_seconds`: server tick histogram, used for TPS and MSPT panels.
- `mc_dimension_tick_seconds`: per-dimension tick histogram, used for per-dimension MSPT.
- `mc_dimension_chunks_loaded`: loaded chunks by dimension.
- `mc_entities_total`: entities by dimension and entity type.
- JVM metrics such as `jvm_memory_bytes_used` and `jvm_memory_bytes_max`.

The exporter listens on `minecraft:19565` inside the Compose network. This port is scraped by Prometheus but is not published on the VPS.

`cadvisor` exports container CPU, memory, disk IO, and network metrics.

cAdvisor mounts `/dev/kmsg` read-only so it can detect container OOM events when the host exposes that device. The repeated `There are no NVM devices!` message is harmless on hosts without persistent memory devices.

Loki stores logs for 7 days by default in the `loki-data` Docker volume. Alloy stores read offsets in the `alloy-data` Docker volume so it can resume log collection after restarts. RCON Web Admin stores its database in the `rcon-data` Docker volume.

Grafana provisions three dashboards:

- `Minecraft Container Metrics`: CPU, RAM usage, filesystem usage, network IO, and disk IO from cAdvisor.
- `Minecraft Container Logs`: Docker logs for the `minecraft` container from Loki.
- `Minecraft Server Metrics`: Minecraft-specific status and ping from `mc-monitor`, plus TPS, MSPT, loaded chunks, entities, and JVM heap from `Prometheus Exporter`.

Prometheus also scrapes itself, Loki, and Alloy for operator checks. These scrapes do not publish extra ports on the VPS.

RCON Web Admin connects to the Minecraft service over the internal Compose network. Do not publish RCON Web Admin or the Minecraft RCON port directly to the internet.

## Logs

Grafana provisions a Loki datasource and a `Minecraft Container Logs` dashboard.

Useful LogQL queries in Grafana Explore:

```logql
{compose_project="mc-create-aeronautics", compose_service="minecraft"}
{compose_project="mc-create-aeronautics", compose_service="minecraft"} |= "ERROR"
{compose_project="mc-create-aeronautics", compose_service="minecraft"} |= "Done"
```

Alloy reads Docker logs through `/var/run/docker.sock`. Treat Alloy as trusted infrastructure: access to the Docker socket is powerful even when the socket is mounted read-only. The Alloy and Loki ports are internal to the Compose network and are not exposed on the VPS.

On this server size, Loki and Alloy should usually be small compared with Minecraft itself. Expect tens to a few hundred MiB of RAM combined in normal use, plus disk proportional to log volume and the 7-day retention window. Heavy repeated mod errors can increase Loki disk and CPU usage because every repeated line is indexed and stored.

## Voice Chat

Simple Voice Chat uses UDP `24454` by default:

```sh
VOICE_CHAT_PORT=24454
```

Compose publishes `24454:24454/udp`. Allow UDP `24454` in the VPS firewall and provider firewall if players should use voice chat.

## Sable UDP

Sable opens a UDP listener on the Minecraft server port. Compose publishes `25565:25565/udp` alongside `25565:25565/tcp`. Allow both TCP `25565` and UDP `25565` in the VPS firewall and provider firewall.

## Commands

Start or update the full stack:

```sh
docker compose pull
docker compose up -d
```

Follow monitoring logs:

```sh
docker compose logs -f monitor prometheus grafana rcon cadvisor loki alloy
```

Check the raw Minecraft metrics endpoint from the VPS:

```sh
docker compose exec prometheus wget -qO- http://monitor:8080/metrics
```

Check the raw NeoForge exporter metrics endpoint from the VPS:

```sh
docker compose exec prometheus wget -qO- http://minecraft:19565/metrics
```

Check Loki readiness from the VPS:

```sh
docker compose exec loki wget -qO- http://localhost:3100/ready
```

## spark Diagnostics

Use `spark` when the server is lagging and you need a profiling report:

```text
/spark health
/spark tps
/spark profiler start --timeout 300
```

`spark` reports are diagnostic snapshots. Grafana is the always-on time-series dashboard.
