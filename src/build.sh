for dir in *; do
  if [[ -d "$dir" ]]; then
    cd "$dir"
    docker build -t $dir .
    cd ..
  fi
done
