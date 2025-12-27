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

echo "=== Waiting for old CoreDNS pods to terminate ==="

# Get the newest ReplicaSet (by creation timestamp)
NEW_RS=$(kubectl get rs -n kube-system -l k8s-app=kube-dns \
  --sort-by=.metadata.creationTimestamp \
  -o jsonpath='{.items[-1].metadata.name}')

echo "Newest ReplicaSet: $NEW_RS"

# Wait until ONLY pods from the new RS are running
for i in {1..30}; do
  mapfile -t COREDNS_PODS < <(
    kubectl get pods -n kube-system -l k8s-app=kube-dns,pod-template-hash=$(kubectl get rs "$NEW_RS" -n kube-system -o jsonpath='{.metadata.labels.pod-template-hash}') \
      -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.podIP}{"\n"}{end}'
  )

  if [[ "${#COREDNS_PODS[@]}" -eq 2 ]]; then
    break
  fi

  echo "Waiting for old CoreDNS pods to terminate..."
  sleep 2
done

if [[ "${#COREDNS_PODS[@]}" -ne 2 ]]; then
  echo "ERROR: Expected exactly 2 CoreDNS pods from new ReplicaSet"
  printf '%s\n' "${COREDNS_PODS[@]}"
  exit 1
fi


COREDNS_POD_1_NAME=$(echo "${COREDNS_PODS[0]}" | awk '{print $1}')
COREDNS_POD_1_IP=$(echo "${COREDNS_PODS[0]}" | awk '{print $2}')

COREDNS_POD_2_NAME=$(echo "${COREDNS_PODS[1]}" | awk '{print $1}')
COREDNS_POD_2_IP=$(echo "${COREDNS_PODS[1]}" | awk '{print $2}')

echo "CoreDNS mapping:"
echo "  coredns-pod-1 -> $COREDNS_POD_1_NAME ($COREDNS_POD_1_IP)"
echo "  coredns-pod-2 -> $COREDNS_POD_2_NAME ($COREDNS_POD_2_IP)"

echo "=== Patching EndpointSlices ==="

kubectl patch endpointslice coredns-pod-1 -n kube-system --type=merge -p "{
  \"endpoints\": [{
    \"addresses\": [\"$COREDNS_POD_1_IP\"]
  }]
}"

kubectl patch endpointslice coredns-pod-2 -n kube-system --type=merge -p "{
  \"endpoints\": [{
    \"addresses\": [\"$COREDNS_POD_2_IP\"]
  }]
}"


# Restart forwarder CoreDNS in dns namespace
kubectl rollout restart deployment forwarder-coredns -n dns

kubectl rollout status deployment/forwarder-coredns -n dns --timeout=30s || \
    echo "Warning: forwarder-coredns rollout may have timed out or failed to become ready within 30s"

echo "Completed apply + restarts for profile='$PROFILE' cluster='$CLUSTER_NAME'"
