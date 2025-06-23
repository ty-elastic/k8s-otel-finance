for dir in ./*/; do
  if [[ -d "$dir" ]]; then
    course=$(basename "$dir")
    echo $course
    cd $course
    instruqt track push --force
    cd ..
  fi
done