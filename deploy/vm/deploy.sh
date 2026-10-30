#!/usr/bin/env bash
set -euo pipefail

ENV="${1:?Uso: odsoft-deploy <dev|staging|prod> <tag> <jar>}"
TAG="${2:?Uso: odsoft-deploy <dev|staging|prod> <tag> <jar>}"
JAR="${3:?Uso: odsoft-deploy <dev|staging|prod> <tag> <jar>}"

case "$ENV" in
    dev) PORT=2224 ;;
    staging) PORT=2225 ;;
    prod) PORT=2228 ;;
    *)
        echo "Ambiente inválido: $ENV" >&2
        exit 2
        ;;
esac

if [[ ! -f "$JAR" ]]; then
    echo "JAR não encontrado: $JAR" >&2
    exit 2
fi

ROOT="/opt/odsoft"
RELEASE="$ROOT/releases/$TAG"
CURRENT="$ROOT/current-$ENV"
SERVICE="odsoft-$ENV.service"

mkdir -p "$RELEASE"
install -m 644 -o odsoft -g odsoft "$JAR" "$RELEASE/app.jar"

PREVIOUS=""
if [[ -L "$CURRENT" ]]; then
    PREVIOUS="$(readlink -f "$CURRENT" || true)"
fi

ln -sfn "$RELEASE" "$CURRENT"
chown -h odsoft:odsoft "$CURRENT"

echo "A reiniciar $SERVICE com $RELEASE..."
systemctl restart "$SERVICE"

healthy=0
for _ in $(seq 1 60); do
    if curl -fsS "http://127.0.0.1:${PORT}/actuator/health" >/dev/null 2>&1; then
        healthy=1
        break
    fi
    sleep 2
done

if [[ "$healthy" -ne 1 ]]; then
    echo "Health check falhou em $ENV." >&2
    if [[ -n "$PREVIOUS" && -d "$PREVIOUS" ]]; then
        echo "A reverter para $PREVIOUS..." >&2
        ln -sfn "$PREVIOUS" "$CURRENT"
        chown -h odsoft:odsoft "$CURRENT"
        systemctl restart "$SERVICE"
    fi
    exit 1
fi

echo "DEPLOY_OK env=$ENV tag=$TAG port=$PORT"
