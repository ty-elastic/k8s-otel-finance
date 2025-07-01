course=latest
service=all
local=false
variant=none

while getopts "l:c:s:v:" opt
do
   case "$opt" in
      c ) course="$OPTARG" ;;
      s ) service="$OPTARG" ;;
      l ) local="$OPTARG" ;;
      v ) variant="$OPTARG" ;;
   esac
done

repo=us-central1-docker.pkg.dev/elastic-sa/tbekiares
if [ "$local" = "true" ]; then
    repo=localhost:5093
fi

export COURSE=$course
export REPO=$repo

for file in k8s/*.yaml; do
    current_service=$(basename "$file")
    current_service="${current_service%.*}"
    echo $current_service
    if [ "$service" = "all" ] | [ "$service" = "$current_service" ]; then
        echo "deploying..."
        if [ "$course" = "latest" ]; then
            sed "s,#imagePullPolicy,imagePullPolicy,g" k8s/$service.yaml | envsubst | kubectl apply -f -
        else
            echo "k8s/_courses/$course/$variant.yaml"
            if [ -f "k8s/_courses/$course/$variant.yaml" ]; then
                echo "applying variant"
                envsubst < k8s/_courses/$course/$variant.yaml | kubectl apply -f -
            else
                envsubst < k8s/$service.yaml | kubectl apply -f -
            fi
        fi
        kubectl -n trading rollout restart deployment/$current_service
    fi
done
