# Repository Instructions

Перед выполнением запроса пользователя всегда сначала перечитай этот файл, если он есть в корне репозитория.

## Project Principles

- Keep this repository as deployment source, not runtime state.
- Treat `compose.yaml`, `.env.defaults`, `monitoring/`, and `docs/` as the committed deployment definition.
- Treat `.env` and `data/` as local VPS/runtime state; never commit them.
- Do not commit Minecraft world data, downloaded mods, generated configs, logs, AutoModpack private state, certificates, keys, or Docker volume exports.
- Keep the deployment aligned with the modpack repository image: `ghcr.io/alexcawl/mc-create-aeronautics-server:<tag>` or `latest`.

## Repository Layout

- `compose.yaml` defines the Minecraft server, RCON Web Admin, and monitoring/observability stack.
- `.env.defaults` is the public template for required secrets and tuning values.
- `monitoring/prometheus/prometheus.yml` defines internal scrape targets.
- `monitoring/alloy/config.alloy` collects Compose container logs and sends them to Loki.
- `monitoring/loki/loki-config.yaml` configures short-retention log storage.
- `monitoring/grafana/provisioning/` and `monitoring/grafana/dashboards/` define provisioned datasources and dashboards.
- `docs/vps.md` documents VPS setup and operations; `docs/monitoring.md` documents observability.

## Secrets and Runtime State

- Never copy real values from `.env` into committed files, examples, logs, or docs.
- Keep `.env.defaults` free of secrets; use empty placeholders for required secrets and safe defaults for public tuning knobs.
- `data/` is mounted as `/data` in the Minecraft container and may contain world data, credentials, logs, jars, configs, and AutoModpack private keys.
- Do not inspect or summarize sensitive runtime files under `data/automodpack/.private/`, certificates, private keys, or token-bearing configs unless explicitly required.
- If adding a new required env var in `compose.yaml`, add it to `.env.defaults` and document it in `docs/vps.md` or `docs/monitoring.md`.

## Docker Compose Rules

- Validate Compose changes with `docker compose config`.
- Keep public game-facing ports intentional:
  - TCP `25565` for Minecraft.
  - UDP `25565` for Sable.
  - TCP `8100` for BlueMap.
  - UDP `24454` for Simple Voice Chat.
- Keep Grafana and RCON Web Admin bound to localhost unless the user explicitly asks to expose them.
- Do not publish the Minecraft RCON port directly to the internet.
- Preserve required-variable guards like `${VAR:?message}` for passwords, Telegram settings, and other mandatory runtime values.
- Prefer pinned infrastructure image tags for reproducibility when multi-arch tags are available; document intentional `latest` usage.
- Do not use `docker compose down -v` in instructions unless the user explicitly wants to delete named monitoring/RCON volumes.

## Monitoring Rules

- Prometheus scrapes only internal Compose targets unless there is a clear reason to publish a port.
- Keep the Minecraft exporter target as `minecraft:19565` and the mc-monitor target as `monitor:8080` unless the services change.
- Keep Loki and Alloy internal to the Compose network; access logs through Grafana.
- When changing dashboard JSON, keep provisioning files and docs consistent.
- Preserve the `compose_project="mc-create-aeronautics"` log filtering convention unless the Compose project name changes.

## Minecraft Operations

- The server currently runs with `ONLINE_MODE=false`; operational docs must continue to call out whitelist/ops implications.
- `MC_MEMORY`, `USE_AIKAR_FLAGS`, and `MC_JVM_XX_OPTS` are runtime tuning knobs. Do not enable Aikar flags and ZGC together in examples.
- Normal server updates should be documented as `docker compose pull` plus `docker compose up -d` or a focused Minecraft service restart.
- Backups should focus on `data/world/`, `data/world_nether/`, `data/world_the_end/`, `data/server.properties`, `data/ops.json`, and `data/whitelist.json` when those paths exist.

## Documentation Rules

- Keep `README.md`, `.env.defaults`, `compose.yaml`, `docs/vps.md`, and `docs/monitoring.md` aligned when ports, services, image tags, env vars, or access patterns change.
- Use concise operational language and commands that can be run from the repository root on the VPS.
- Prefer Russian for new project-specific operational notes if editing an existing Russian section; otherwise match the surrounding document language.

## Git Workflow

- Check `git status --short --branch` before committing.
- Do not rewrite history, reset, amend, rebase, or force-push unless the user explicitly asks.
- Do not revert user/runtime changes unless the user explicitly asks.
- Keep commits focused and use Conventional Commits:
  - `feat: ...` for new deployment capabilities or services.
  - `fix: ...` for bug fixes.
  - `docs: ...` for documentation-only changes.
  - `chore: ...` for maintenance, image bumps, and housekeeping.
- Before committing, run lightweight validation that matches the change, especially `docker compose config` for Compose changes.
