# cloud-dns-testing-tooling
Tooling related to Cloud Native DNS testing

## Generate Entries

`helm template dns-endpoints entries-generator/ -f entries-generator/values-<cluster>.yaml > dns-endpoints/endpoints-<cluster>.yaml`

For Berne
`helm template dns-endpoints entries-generator/ -f entries-generator/values-berne.yaml > dns-endpoints/endpoints-berne.yaml`



## Wipe all the entries from the cluster

kubectl delete dnsendpoints.externaldns.k8s.io --all