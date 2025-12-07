#!/usr/bin/env bash
set -euo pipefail

# Usage: apply-setting.sh <profile: no-caching|std-caching> <cluster-name>
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <profile: no-caching|std-caching> <cluster-name> e.g., berne"
    exit 1
fi

PROFILE=$1
CLUSTER_NAME=$2

if [ "$PROFILE" != "no-caching" ] && [ "$PROFILE" != "std-caching" ]; then
    echo "Invalid profile '$PROFILE'. Allowed: no-caching or std-caching"
    exit 2
fi

# Determine the target directory containing YAMLs for this profile+cluster
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$SCRIPT_DIR/$PROFILE/$CLUSTER_NAME"

if [ ! -d "$TARGET_DIR" ]; then
    echo "Target directory '$TARGET_DIR' does not exist. Check profile and cluster name." >&2
    exit 3
fi

# Switch kubectl context
kubectl config use-context kind-$CLUSTER_NAME

# Apply configuration under the profile/cluster folder
kubectl apply -f "$TARGET_DIR"
echo "Applied $PROFILE settings to the $CLUSTER_NAME cluster"

# Restart K8s CoreDNS deployment in kube-system
kubectl rollout restart deployment coredns -n kube-system

# Wait for rollout (best-effort with timeout)
kubectl rollout status deployment/coredns -n kube-system --timeout=30s || \
    echo "Warning: coredns rollout may have timed out or failed to become ready within 30s"


# Restart forwarder CoreDNS in dns namespace
kubectl rollout restart deployment forwarder-coredns -n dns

kubectl rollout status deployment/forwarder-coredns -n dns --timeout=30s || \
    echo "Warning: forwarder-coredns rollout may have timed out or failed to become ready within 30s"

echo "Completed apply + restarts for profile='$PROFILE' cluster='$CLUSTER_NAME'"
