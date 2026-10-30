#!/usr/bin/env bash
set -euo pipefail

ENV="${1:-dev}"
TAG="${2:-local}"
case "$ENV" in
    dev) PORT=8091 ;;
    staging) PORT=8092 ;;
    prod) PORT=8093 ;;
    *)
        echo "Ambiente invalido: $ENV (use dev, staging ou prod)" >&2
        exit 2
        ;;
esac

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
mkdir -p .deploy

PREVIOUS_FILE=".deploy/${ENV}.previous"
PREVIOUS=""
if [[ -f "$PREVIOUS_FILE" ]]; then
    PREVIOUS="$(cat "$PREVIOUS_FILE")"
fi
echo "$TAG" > "$PREVIOUS_FILE"

IMAGE="odsoft-lms:${TAG}"
HEALTH_HOST="${HEALTH_HOST:-localhost}"

echo "A construir o JAR..."
mvn -B -DskipTests package

echo "A construir ${IMAGE}..."
docker build -t "$IMAGE" .

echo "A publicar ${ENV} com ${IMAGE}..."
LMS_IMAGE="$IMAGE" docker compose up -d "lms-${ENV}"

healthy=0
for _ in $(seq 1 60); do
    if curl -fsS "http://${HEALTH_HOST}:${PORT}/actuator/health" >/dev/null 2>&1; then
        healthy=1
        break
    fi
    sleep 2
done

if [[ "$healthy" -ne 1 ]]; then
    echo "Deployment de ${ENV} falhou no health check." >&2
    if [[ -n "$PREVIOUS" ]]; then
        echo "A reverter para ${PREVIOUS}..." >&2
        LMS_IMAGE="odsoft-lms:${PREVIOUS}" docker compose up -d "lms-${ENV}"
    fi
    exit 1
fi

echo "DEPLOY_OK env=${ENV} image=${IMAGE}"
