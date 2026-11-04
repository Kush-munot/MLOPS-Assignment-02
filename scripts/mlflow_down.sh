#!/usr/bin/env bash
set -euo pipefail

RUNTIME="${CONTAINER_RUNTIME:-podman}"
"$RUNTIME" stop eduassist-mlflow
echo "Stopped. Data is kept in the volume eduassist-mlflow-data."
