#!/usr/bin/env bash
set -euo pipefail

ENV="${1:-dev}"
case "$ENV" in
    dev) PORT=2224 ;;
    staging) PORT=2225 ;;
    prod) PORT=2228 ;;
    *)
        echo "Ambiente inválido: $ENV" >&2
        exit 2
        ;;
esac

URL="http://127.0.0.1:${PORT}/actuator/health"

for _ in $(seq 1 30); do
    if curl -fsS "$URL"; then
        echo
        echo "SMOKE_OK env=$ENV"
        exit 0
    fi
    sleep 2
done

echo "SMOKE_FAILED env=$ENV" >&2
exit 1
