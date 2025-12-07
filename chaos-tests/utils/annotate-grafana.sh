#!/usr/bin/env bash
set -euo pipefail

GRAFANA_URL="http://localhost:3000"
GRAFANA_TOKEN="${GRAFANA_TOKEN:?Missing GRAFANA_TOKEN env var}"

TEXT="${1:?Missing annotation text}"

TIMESTAMP_MS=$(($(date +%s) * 1000))

curl -s -X POST "${GRAFANA_URL}/api/annotations" \
  -H "Authorization: Bearer ${GRAFANA_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"time\": ${TIMESTAMP_MS},
    \"tags\": [\"resilience testing\"],
    \"text\": \"${TEXT}\"
  }"
