# MC Create Aeronautics Deployment

Deployment configuration for the MC Create Aeronautics server.

BlueMap is exposed through host Nginx on HTTPS, with Certbot as the shared certificate source for Nginx and AutoModpack.

## Contents

- `compose.yaml`: Minecraft, backups, RCON Web Admin, and monitoring/observability stack.
- `.env.defaults`: public environment template.
- `backups/`: ignored local Minecraft backup archives created on the VPS.
- `monitoring/`: Prometheus, Loki, Alloy, and Grafana configuration.
- `docs/vps.md`: VPS setup and operations.
- `docs/monitoring.md`: monitoring usage and maintenance.

## Quick Start

```sh
cp .env.defaults .env
${EDITOR:-vi} .env
docker compose pull
docker compose up -d
```

Fill the required values in `.env` before starting, including RCON, Grafana, and `CFG_TGBRIDGE_*` Telegram/BlueMap settings. Set optional `MC_WORLD_SEED` before the first start if the initial world should use a fixed seed. For the public BlueMap URL, use `https://mc-create-aeronautics.mooo.com` after Nginx and Certbot are configured.

See `docs/vps.md` for the full deployment workflow.
