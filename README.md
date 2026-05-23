# MC Create Aeronautics Deployment

Deployment configuration for the MC Create Aeronautics server.

This directory is staged so it can be moved into a separate `mc-create-aeronautics-deployment` repository.

## Contents

- `compose.yaml`: Minecraft, monitoring, RCON, and observability stack.
- `.env.defaults`: public environment template.
- `monitoring/`: Prometheus, Loki, Alloy, and Grafana configuration.
- `docs/vps.md`: VPS setup and operations.
- `docs/monitoring.md`: monitoring usage and maintenance.

## Quick Start

```sh
cp .env.defaults .env
docker compose pull
docker compose up -d
```

See `docs/vps.md` for the full deployment workflow.
