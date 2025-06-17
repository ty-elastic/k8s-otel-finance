arch=linux/amd64

while getopts "s:" opt
do
   case "$opt" in
      s ) service="$OPTARG" ;;
   esac
done
echo "service=$service"

echo $service
echo $COURSE
echo $IMAGE_VERSION

docker build --platform $arch --build-arg COURSE=$COURSE --progress plain -t us-central1-docker.pkg.dev/elastic-sa/tbekiares/$service:$IMAGE_VERSION src/$service
#docker push us-central1-docker.pkg.dev/elastic-sa/tbekiares/$service:$IMAGE_VERSION

sed "s,#imagePullPolicy,imagePullPolicy,g" k8s/$service.yaml | envsubst | kubectl apply -f -

