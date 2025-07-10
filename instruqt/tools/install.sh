source /opt/workshops/elastic-retry.sh

export $(curl http://kubernetes-vm:9000/env | xargs)

deploy=true
while getopts "i:o:" opt
do
   case "$opt" in
      d ) deploy="$OPTARG" ;;
      o ) otel="$OPTARG" ;;
   esac
done

for dir in /workspace/workshop/src/*/; do
  if [[ -d "$dir" ]]; then
    service=$(basename "$dir")
    echo $service
    if [ -d "$dir/_courses/$INSTRUQT_TRACK_SLUG" ]; then
        echo "patching"
        cd /workspace/workshop/src/$service
        patch < _courses/$INSTRUQT_TRACK_SLUG/init.patch
    fi
  fi
done

cd /workspace/workshop

cd k8s
if [ -d "_courses/$INSTRUQT_TRACK_SLUG" ]; then
    echo $INSTRUQT_TRACK_SLUG;
    patch < _courses/$INSTRUQT_TRACK_SLUG/init.patch
fi
cd ..

if [ "$deploy" = "true" ]; then
  ./deploy.sh -c $INSTRUQT_TRACK_SLUG -o $otel
fi
