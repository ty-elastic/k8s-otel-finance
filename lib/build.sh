arch=linux/amd64
course=latest

while getopts "b:c:" opt
do
case "$opt" in
    a ) arch="$OPTARG" ;;
    c ) course="$OPTARG" ;;
esac
done

for dir in java/*/; do
    echo $dir
    if [[ -d "$dir" ]]; then
        extension=$(basename "$dir")
        docker build --platform $arch --progress plain -t us-central1-docker.pkg.dev/elastic-sa/tbekiares/$extension:$course $dir
        docker push us-central1-docker.pkg.dev/elastic-sa/tbekiares/$extension:$course
    fi
done
