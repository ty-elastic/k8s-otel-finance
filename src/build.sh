arch=linux/amd64
course=latest
repo=us-central1-docker.pkg.dev/elastic-sa/tbekiares
service=all
while getopts "r:a:c:s:" opt
do
   case "$opt" in
      a ) arch="$OPTARG" ;;
      c ) course="$OPTARG" ;;
      r ) repo="$OPTARG" ;;
      s ) service="$OPTARG" ;;
   esac
done

for service_dir in ./*/; do
    echo $service_dir
    if [[ -d "$service_dir" ]]; then
        current_service=$(basename "$service_dir")
        if [ "$service" = "all" ] | [ "$service" = "$current_service" ]; then
            echo $service
            echo $course
            docker build --platform $arch --build-arg COURSE=$course --progress plain -t $repo/$current_service:$course $service_dir
            docker push $repo/$current_service:$course
        fi
    fi
done
