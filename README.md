# cloud-dns-testing-tooling
Tooling related to Cloud Native DNS testing

## Generate Entries

`helm template dns-endpoints entries-generator/ -f entries-generator/values-<cluster>.yaml > dns-endpoints/endpoints-<cluster>.yaml`

For Berne
`helm template dns-endpoints entries-generator/ -f entries-generator/values-berne.yaml > dns-endpoints/endpoints-berne.yaml`


## Wipe all the entries from the cluster

kubectl delete dnsendpoints.externaldns.k8s.io --all

## Configure caching behavior
Under `cache-settings` you can find different caching profiles
- No Caching, the forwarder zones (5gc in our case) are not cached, any request on this component is propagated to the configured delegate dns server.
- Standard (std) Caching.
  - Default size (9984) cache of successful responses for a TTL of 5 seconds
  - Default size (9984) cache of NXDOMAIN and NODATA responses for a TTL of 5 seconds

  Change the setting of the caching by using the utility `./apply-settings.sh`
  - Apply no-caching in Bern: `./apply-settings.sh no-caching berne`
  - Apply caching in Zurich: `./apply-settings.sh caching zurich`

  ## Run Tests

  Make sure that chainsaw is installed in the jumphost.
  If not, you can install it with `go install github.com/kyverno/chainsaw@latest`, or with any of the alternative ways described [here](https://kyverno.github.io/chainsaw/0.2.3/quick-start/install/).
  If you install it via go, you can execute it with `$HOME/go/bin/chainsaw`, or add the go path in your shell path.

  ex. execute K8s DNS test case with:
  `$HOME/go/bin/chainsaw test chaos-tests/01-k8s-coredns/`