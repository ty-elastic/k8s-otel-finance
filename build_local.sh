export COURSE=latest
export arch=linux/arm64

arch=linux/amd64

build=true
push=false
while getopts "b:p:a:" opt
do
   case "$opt" in
      a ) arch="$OPTARG" ;;
      b ) build="$OPTARG" ;;
      p ) push="$OPTARG" ;;
   esac
done

COURSE=latest

if [ "$build" = "true" ]; then
    for service_dir in ./src/*/; do
        echo $service_dir
        if [[ -d "$service_dir" ]]; then
            service=$(basename "$service_dir")
            echo $service
            echo $COURSE
            docker build --platform $arch --build-arg COURSES=false --build-arg COURSE=$COURSE --progress plain -t us-central1-docker.pkg.dev/elastic-sa/tbekiares/$service:$COURSE $service_dir
            if [ "$push" = "true" ]; then
                docker push us-central1-docker.pkg.dev/elastic-sa/tbekiares/$service:$COURSE
            fi
        fi
    done
fi

if [ "$push" = "true" ]; then
    for f in k8s/*.yaml;do sed "s,#imagePullPolicy: Always,imagePullPolicy: Always,g" $f | envsubst | kubectl apply -f -; done
else
    for f in k8s/*.yaml; do sed "s,#imagePullPolicy: Always,imagePullPolicy: Never,g" $f | envsubst | kubectl apply -f -; done
fi