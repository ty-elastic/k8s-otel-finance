export $(cat ./build_vars.sh | xargs)

ARCH=linux/amd64
LOCAL_DOCKER_REPO=localhost:5000
IMAGE_VERSION=latest

docker run -d -p 5000:5000 --restart=always --name registry registry:2

while getopts "s:" opt
do
   case "$opt" in
      s ) service="$OPTARG" ;;
   esac
done

echo $service
echo $COURSE
echo $IMAGE_VERSION
echo $LOCAL_DOCKER_REPO

docker build --platform $ARCH --build-arg VARIANTS=false --build-arg COURSE=$COURSE --progress plain -t $LOCAL_DOCKER_REPO/$service:$IMAGE_VERSION src/$service
docker push $LOCAL_DOCKER_REPO/$service:$IMAGE_VERSION

sed "s,#imagePullPolicy,imagePullPolicy,g" k8s/$service.yaml | sed "s,us-central1-docker.pkg.dev/elastic-sa/tbekiares,$LOCAL_DOCKER_REPO,g" | envsubst | kubectl apply -f -

kubectl -n trading rollout restart deployment/$service

