arch=linux/amd64

# git add -u
# git commit -m "updates"
# git push origin main

for dir in ./courses/*/; do
  if [[ -d "$dir" ]]; then
    COURSE=$(basename "$dir")
    echo $COURSE

    for dir in ../src/*/; do
        echo $dir
        if [[ -d "$dir" ]]; then
            service=$(basename "$dir")
            echo $service
            echo $COURSE
            docker build --platform $arch --build-arg COURSE=$COURSE --progress plain -t us-central1-docker.pkg.dev/elastic-sa/tbekiares/$service:$COURSE $dir
            docker push us-central1-docker.pkg.dev/elastic-sa/tbekiares/$service:$COURSE
        fi
    done

    cd $COURSE
    instruqt track push --force
    cd ..
  fi
done





