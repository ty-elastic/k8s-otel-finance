source /opt/workshops/elastic-retry.sh

export $(curl http://kubernetes-vm:9000/env | xargs)
export $(cat /workspace/workshop/instruqt/$INSTRUQT_TRACK_SLUG/build_vars.sh | xargs)

for dir in /workspace/workshop/src/*/; do
  if [[ -d "$dir" ]]; then
    service=$(basename "$dir")
    echo $service
    if [ -d "$dir/variants/$COURSE" ]; then
        echo "patching"
        cd /workspace/workshop/src/$service
        patch < variants/$COURSE/init.patch
    fi
  fi
done

cd /workspace/workshop

if [ -d "k8s/variants/$COURSE" ]; then \
    echo $COURSE; \
    patch < variants/$COURSE/init.patch
fi

./install.sh
