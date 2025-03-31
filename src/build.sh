for dir in *; do
  if [[ -d "$dir" ]]; then
    cd "$dir"
    docker build --progress plain -t us-central1-docker.pkg.dev/elastic-sa/tbekiares/$dir:v1 .
    cd ..
  fi
done
