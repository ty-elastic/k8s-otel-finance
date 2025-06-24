export COURSE=latest
export arch=linux/arm64

arch=linux/amd64

build=true
while getopts "b:" opt
do
   case "$opt" in
      b ) build="$OPTARG" ;;
   esac
done

if [ "$build" = "true" ]; then
    for service_dir in ./src/*/; do
        echo $service_dir
        if [[ -d "$service_dir" ]]; then
            service=$(basename "$service_dir")
            echo $service
            echo $COURSE
            docker build --platform $arch --build-arg COURSES=false --build-arg COURSE=$COURSE --progress plain -t us-central1-docker.pkg.dev/elastic-sa/tbekiares/$service:$COURSE $service_dir
        fi
    done
fi

for f in k8s/*.yaml; do sed "s,#imagePullPolicy: Always,imagePullPolicy: Never,g" $f | envsubst | kubectl apply -f -; done
