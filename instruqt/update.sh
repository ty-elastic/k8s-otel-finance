arch=linux/amd64

build=true
course=all
while getopts "b:c:" opt
do
   case "$opt" in
      b ) build="$OPTARG" ;;
      c ) course="$OPTARG" ;;
   esac
done

# git add -u
# git commit -m "updates"
# git push origin main

for dir in ./courses/*/; do
  echo $dir
  if [[ -d "$dir" ]]; then
    current_course=$(basename "$dir")
    echo $current_course
    
    if [ "$course" = "all" ] | [ "$course" = "$current_course" ]; then
      if [ "$build" = "true" ]; then
        for service_dir in ../src/*/; do
            echo $service_dir
            if [[ -d "$service_dir" ]]; then
                service=$(basename "$service_dir")
                echo $service
                echo $current_course
                docker build --platform $arch --build-arg current_course=$current_course --progress plain -t us-central1-docker.pkg.dev/elastic-sa/tbekiares/$service:$current_course $service_dir
                docker push us-central1-docker.pkg.dev/elastic-sa/tbekiares/$service:$current_course
            fi
        done

        cd ../lib
        ./build.sh -c $current_course -a $arch
        cd ../instruqt
      fi

      cd courses/$current_course
      instruqt track push --force
      cd ../..
    fi
  fi
done





