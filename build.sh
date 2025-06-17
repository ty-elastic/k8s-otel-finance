arch=linux/amd64

for dir in ../../src/*/; do
  echo $dir
  if [[ -d "$dir" ]]; then
    service=$(basename "$dir")
    echo $service
    echo $COURSE
    docker build --platform $arch --build-arg COURSE=$COURSE --progress plain -t us-central1-docker.pkg.dev/elastic-sa/tbekiares/$service:$IMAGE_VERSION $dir
    docker push us-central1-docker.pkg.dev/elastic-sa/tbekiares/$service:$IMAGE_VERSION
  fi
done
