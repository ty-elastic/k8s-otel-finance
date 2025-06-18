source /opt/workshops/elastic-retry.sh

export $(curl http://kubernetes-vm:9000/env | xargs)
export $(cat /workspace/workshop/instruqt/$INSTRUQT_TRACK_SLUG/build_vars.sh | xargs)

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
