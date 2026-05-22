#!/usr/bin/env sh
set -eu

# Resolve the repository root so the script works from any current directory.
ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
REINSTALL_MODS=false

log() {
  printf '[run_minecraft] %s\n' "$*"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --reinstall-mods)
      REINSTALL_MODS=true
      ;;
    -h|--help)
      printf '%s\n' "Usage: scripts/run_minecraft.sh [--reinstall-mods]"
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      printf '%s\n' "Usage: scripts/run_minecraft.sh [--reinstall-mods]" >&2
      exit 1
      ;;
  esac
  shift
done

if [ ! -f "$ENV_FILE" ]; then
  printf '%s\n' "Missing .env. Create it first:" >&2
  printf '%s\n' "  cp .env.defaults .env" >&2
  printf '%s\n' "  edit .env and fill the required values" >&2
  exit 1
fi

log "Using repository root: $ROOT_DIR"
log "Found .env"

cd "$ROOT_DIR"

MC_UID="$(id -u)"
MC_GID="$(id -g)"
export MC_UID MC_GID

log "Using UID=$MC_UID GID=$MC_GID"
log "Pulling Minecraft image"
docker compose pull minecraft

log "Stopping existing Docker Compose stack if present"
docker compose down

if [ "$REINSTALL_MODS" = true ]; then
  log "Reinstall requested: removing downloaded mod jars"
  if [ -d "$ROOT_DIR/data/mods" ]; then
    find "$ROOT_DIR/data/mods" -maxdepth 1 -type f -name '*.jar' -delete
  else
    log "No data/mods directory found"
  fi

  log "Removing legacy cached Modrinth modpack files if present"
  rm -f "$ROOT_DIR/data/modpack.mrpack"
  rm -f "$ROOT_DIR/data/.modrinth-modpack-manifest.json"
  rm -f "$ROOT_DIR/data/.install-modrinth.env"
else
  log "Reinstall not requested: relying on container startup synchronization"
fi

log "Starting Docker Compose stack"
docker compose up -d
log "Docker Compose stack started"
