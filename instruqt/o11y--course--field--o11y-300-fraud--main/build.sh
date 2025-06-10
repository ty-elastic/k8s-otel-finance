arch=linux/amd64

source build_vars.sh

for dir in ../../src/*/; do
  echo $dir
  if [[ -d "$dir" ]]; then
    service=$(basename "$dir")
    echo $service
    echo $COURSE
    echo $BUILD_TAG
    docker build --platform $arch --build-arg COURSE=$COURSE --progress plain -t us-central1-docker.pkg.dev/elastic-sa/tbekiares/$service:$COURSE_$BUILD_TAG $dir
    docker push us-central1-docker.pkg.dev/elastic-sa/tbekiares/$service:$COURSE_$BUILD_TAG
  fi
done
