    arch=linux/amd64
    
    for dir in java/*/; do
        echo $dir
        if [[ -d "$dir" ]]; then
            extension=$(basename "$dir")
            docker build --platform $arch --progress plain -t us-central1-docker.pkg.dev/elastic-sa/tbekiares/$extension:new4 $dir
            docker push us-central1-docker.pkg.dev/elastic-sa/tbekiares/$extension:new4
        fi
    done