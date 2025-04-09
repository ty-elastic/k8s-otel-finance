curl -o values.yaml https://raw.githubusercontent.com/elastic/elastic-agent/refs/tags/v8.17.4/deploy/helm/edot-collector/kube-stack/values.yaml

patch -u values.yaml -i values.patch

helm upgrade -f values.yaml opentelemetry-kube-stack  open-telemetry/opentelemetry-kube-stack --namespace opentelemetry-operator-system