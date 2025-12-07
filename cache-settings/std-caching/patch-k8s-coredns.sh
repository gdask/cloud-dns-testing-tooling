#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="kube-system"
CONFIGMAP="coredns"

# -----------------------------
# Multiline patch block to insert
# -----------------------------
read -r -d '' PATCH_BLOCK << 'EOF'
        cache 30 {
            success 9984 5  # Default size (9984) cache of successful responses for a TTL of 5 seconds
            denial 9984 5   # Default size (9984) cache of NXDOMAIN and NODATA responses for a TTL of 5 seconds
        }
EOF

# Escape backslashes and quotes for safe jq injection
PATCH_ESCAPED=$(printf "%s" "$PATCH_BLOCK" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')

# -----------------------------
# Apply patch: insert after "forward" line
# -----------------------------
kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o json \
  | jq --arg block "$PATCH_ESCAPED" '
      .data.Corefile |=
        sub("(forward[^\n]*\n)";
            "\($1)\n\($block)\n"
        )
    ' \
  | kubectl apply -f -

echo "Patched CoreDNS: inserted block after the forward statement."
