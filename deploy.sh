course=latest
service=all
local=false
variant=none
otel=false

while getopts "l:c:s:v:o:" opt
do
   case "$opt" in
      c ) course="$OPTARG" ;;
      s ) service="$OPTARG" ;;
      l ) local="$OPTARG" ;;
      v ) variant="$OPTARG" ;;
      o ) otel="$OPTARG" ;;
   esac
done

repo=us-central1-docker.pkg.dev/elastic-sa/tbekiares
if [ "$local" = "true" ]; then
    repo=localhost:5093
fi

export COURSE=$course
export REPO=$repo

if [ "$service" != "none" ]; then

    for file in k8s/*.yaml; do
        current_service=$(basename "$file")
        current_service="${current_service%.*}"
        echo $current_service
        if [ "$service" = "all" ] | [ "$service" = "$current_service" ]; then
            echo "deploying..."
            echo "k8s/_courses/$variant.yaml"
            if [ -f "k8s/_courses/$variant.yaml" ]; then
                echo "applying variant"
                envsubst < k8s/_courses/$variant.yaml | kubectl apply -f -
            else
                envsubst < k8s/$service.yaml | kubectl apply -f -
            fi
            kubectl -n trading rollout restart deployment/$current_service
        fi
    done

fi

if [ "$otel" = "true" ]; then

    # ---------- COLLECTOR

    cd collector
    rm -rf values.yaml
    curl -o values.yaml https://raw.githubusercontent.com/elastic/elastic-agent/refs/tags/v9.0.3/deploy/helm/edot-collector/kube-stack/values.yaml
    if [ -d "_courses/$variant" ]; then
        echo $variant;
        patch < _courses/$variant/init.patch
        envsubst < values.yaml > values.yaml.tmp && mv values.yaml.tmp values.yaml
    fi

    helm upgrade --install opentelemetry-kube-stack open-telemetry/opentelemetry-kube-stack \
    --namespace opentelemetry-operator-system \
    --values 'values.yaml' \
    --version '0.3.9'
    cd ..

    # ---------- OPERATOR

    cd operator
    if [ -d "_courses/$variant" ]; then
        echo "applying variant"
        envsubst < _courses/$variant/init.yaml | kubectl -n opentelemetry-operator-system apply -f -
    fi

    sleep 30

fi
