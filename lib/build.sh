arch=linux/amd64
course=latest
repo=us-central1-docker.pkg.dev/elastic-sa/tbekiares
while getopts "a:c:r:" opt
do
    case "$opt" in
        a ) arch="$OPTARG" ;;
        c ) course="$OPTARG" ;;
        r ) repo="$OPTARG" ;;
    esac
done

for dir in java/*/; do
    echo $dir
    if [[ -d "$dir" ]]; then
        extension=$(basename "$dir")
        docker build --platform $arch --progress plain -t $repo/$extension:$course $dir
        docker push $repo/$extension:$course
    fi
done
