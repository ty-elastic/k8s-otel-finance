export $(cat ./build_vars.sh | xargs)

arch=linux/amd64

for dir in ../../src/*/; do
  echo $dir
  if [[ -d "$dir" ]]; then
    service=$(basename "$dir")
    echo $service
    echo $COURSE
    docker build --platform $arch --build-arg COURSE=$COURSE --progress plain -t us-central1-docker.pkg.dev/elastic-sa/tbekiares/$service:$COURSE $dir
    docker push us-central1-docker.pkg.dev/elastic-sa/tbekiares/$service:$COURSE
  fi
done
