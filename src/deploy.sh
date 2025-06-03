arch=linux/amd64
BUILD_TAG=$(date +%F)

for dir in *; do
  if [[ -d "$dir" ]]; then
    cd "$dir"
    docker build --platform $arch --progress plain -t us-central1-docker.pkg.dev/elastic-sa/tbekiares/$dir:$BUILD_TAG .
    docker push us-central1-docker.pkg.dev/elastic-sa/tbekiares/$dir:$BUILD_TAG
    cd ..
  fi
done
