#!/usr/bin/env bash
set -euo pipefail

ENV="${1:-dev}"
case "$ENV" in
    dev) PORT=8091 ;;
    staging) PORT=8092 ;;
    prod) PORT=8093 ;;
    *)
        echo "Ambiente invalido: $ENV (use dev, staging ou prod)" >&2
        exit 2
        ;;
esac

HEALTH_HOST="${HEALTH_HOST:-localhost}"
URL="http://${HEALTH_HOST}:${PORT}/actuator/health"

echo "A validar ${ENV} em ${URL}..."
for _ in $(seq 1 30); do
    if curl -fsS "$URL"; then
        echo
        echo "SMOKE_OK env=${ENV}"
        exit 0
    fi
    sleep 2
done

echo "SMOKE_FAILED env=${ENV}" >&2
exit 1
