curl -o values.yaml https://raw.githubusercontent.com/elastic/elastic-agent/refs/tags/v8.17.4/deploy/helm/edot-collector/kube-stack/values.yaml

patch -u values.yaml -i values.patch

helm uninstall opentelemetry-kube-stack open-telemetry/opentelemetry-kube-stack --namespace opentelemetry-operator-system
helm install opentelemetry-kube-stack open-telemetry/opentelemetry-kube-stack \
  --namespace opentelemetry-operator-system \
  --values values.yaml \
  --version '0.3.3'

sleep 10  # Waits 15 seconds.

kubectl rollout restart deployment -n k8sotel 