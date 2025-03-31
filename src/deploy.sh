arch=linux/amd64
for dir in *; do
  if [[ -d "$dir" ]]; then
    cd "$dir"
    docker build --platform $arch --progress plain -t us-central1-docker.pkg.dev/elastic-sa/tbekiares/$dir:v1 .
    docker push us-central1-docker.pkg.dev/elastic-sa/tbekiares/$dir:v1
    cd ..
  fi
done
