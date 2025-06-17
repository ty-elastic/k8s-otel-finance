for dir in /workspace/workshop/src/*/; do
  if [[ -d "$dir" ]]; then
    service=$(basename "$dir")
    echo $service
    if [ -d "$dir/variants/$INSTRUQT_TRACK_SLUG" ]; then
        echo "patching"
        cd /workspace/workshop/src/$service
        patch < variants/$INSTRUQT_TRACK_SLUG/init.patch
    fi
  fi
done
cd /workspace/workshop
./install.sh