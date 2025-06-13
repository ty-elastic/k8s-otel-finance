arch=linux/amd64

source build_vars.sh

for dir in ../../src/*/; do
  echo $dir
  if [[ -d "$dir" ]]; then
    service=$(basename "$dir")
    echo $service
    echo $COURSE
    docker build --platform $arch --build-arg COURSE=$COURSE --progress plain -t us-central1-docker.pkg.dev/elastic-sa/tbekiares/$service:$IMAGE_VERSION $dir
    #docker push us-central1-docker.pkg.dev/elastic-sa/tbekiares/$service:$IMAGE_VERSION
  fi
done

for f in ../../k8s/*.yaml; do 
    sed "s,#imagePullPolicy,imagePullPolicy,g" $f | envsubst | kubectl apply -f -
done

kubectl -n trading rollout restart deployment
