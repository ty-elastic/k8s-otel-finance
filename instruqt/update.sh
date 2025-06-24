arch=linux/amd64

build=true
while getopts "b:" opt
do
   case "$opt" in
      b ) build="$OPTARG" ;;
   esac
done

# git add -u
# git commit -m "updates"
# git push origin main

for dir in ./courses/*/; do
  echo $dir
  if [[ -d "$dir" ]]; then
    COURSE=$(basename "$dir")
    echo $COURSE

    if [ "$build" = "true" ]; then
      for service_dir in ../src/*/; do
          echo $service_dir
          if [[ -d "$service_dir" ]]; then
              service=$(basename "$service_dir")
              echo $service
              echo $COURSE
              docker build --platform $arch --build-arg COURSE=$COURSE --progress plain -t us-central1-docker.pkg.dev/elastic-sa/tbekiares/$service:$COURSE $service_dir
              docker push us-central1-docker.pkg.dev/elastic-sa/tbekiares/$service:$COURSE
          fi
      done
    fi

    cd courses/$COURSE
    instruqt track push --force
    cd ../..
  fi
done





