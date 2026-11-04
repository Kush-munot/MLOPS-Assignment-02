#!/usr/bin/env bash
set -euo pipefail

# Container runtime: podman by default; set CONTAINER_RUNTIME=docker where only Docker is installed
RUNTIME="${CONTAINER_RUNTIME:-podman}"
NAME=eduassist-mlflow
IMAGE=localhost/eduassist-mlflow:3.17.2
VOLUME=eduassist-mlflow-data
HOST_PORT="${MLFLOW_PORT:-5001}"

if [ "$RUNTIME" = "podman" ] && ! podman info >/dev/null 2>&1; then
  echo "Starting Podman machine..."
  podman machine start
fi

"$RUNTIME" volume inspect "$VOLUME" >/dev/null 2>&1 || "$RUNTIME" volume create "$VOLUME"

if "$RUNTIME" container inspect "$NAME" >/dev/null 2>&1; then
  "$RUNTIME" start "$NAME"
else
  "$RUNTIME" run -d \
    --name "$NAME" \
    -p 127.0.0.1:${HOST_PORT}:5000 \
    -v "$VOLUME":/mlflow \
    "$IMAGE"
fi

echo "Waiting for MLflow..."
for i in $(seq 1 60); do
  if curl -fsS "http://127.0.0.1:${HOST_PORT}/health" >/dev/null 2>&1; then
    echo "MLflow UI: http://127.0.0.1:${HOST_PORT}"
    exit 0
  fi
  sleep 2
done

echo "MLflow did not become healthy; check: $RUNTIME logs $NAME"
exit 1
