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