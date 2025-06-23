    for dir in java/*/; do
        echo $dir
        if [[ -d "$dir" ]]; then
            extension=$(basename "$dir")
            docker build --progress plain -t us-central1-docker.pkg.dev/elastic-sa/tbekiares/$extension $dir
            docker push us-central1-docker.pkg.dev/elastic-sa/tbekiares/$extension
        fi
    done