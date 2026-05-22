# MC Create Aeronautics Deployment

Deployment configuration for the MC Create Aeronautics server.

This directory is staged so it can be moved into a separate `mc-create-aeronautics-deployment` repository.

## Contents

- `compose.yaml`: Minecraft, monitoring, RCON, and observability stack.
- `.env.defaults`: public environment template.
- `scripts/run_minecraft.sh`: convenience runner for pull/down/up and optional mod reinstall.
- `monitoring/`: Prometheus, Loki, Alloy, and Grafana configuration.
- `docs/vps.md`: VPS setup and operations.
- `docs/monitoring.md`: monitoring usage and maintenance.

## Quick Start

```sh
cp .env.defaults .env
scripts/run_minecraft.sh
```

See `docs/vps.md` for the full deployment workflow.
