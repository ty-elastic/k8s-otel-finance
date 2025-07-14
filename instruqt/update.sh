arch=linux/amd64
build=true
course=all
while getopts "a:b:c:" opt
do
   case "$opt" in
      a ) arch="$OPTARG" ;;
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
    echo $course
    
    if [[ "$course" == "all" || "$course" == "$current_course" ]]; then

      if [ "$build" = "true" ]; then
        cd ..
        ./build.sh -c $current_course -a $arch -v $current_course
        cd instruqt
      fi

      cd courses/$current_course
      instruqt track push --force
      cd ../..
    fi
  fi
done





