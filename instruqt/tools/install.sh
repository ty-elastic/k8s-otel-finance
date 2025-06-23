source /opt/workshops/elastic-retry.sh

export $(curl http://kubernetes-vm:9000/env | xargs)

install=true
while getopts "i:" opt
do
   case "$opt" in
      i ) install="$OPTARG" ;;
   esac
done

cat > /workspace/workshop/build_vars.sh << EOF
COURSE=$INSTRUQT_TRACK_SLUG
EOF

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

cd k8s
if [ -d "variants/$INSTRUQT_TRACK_SLUG" ]; then
    echo $INSTRUQT_TRACK_SLUG;
    patch < variants/$INSTRUQT_TRACK_SLUG/init.patch
fi
cd ..

export COURSE=$INSTRUQT_TRACK_SLUG
for f in k8s/*.yaml; do envsubst < $f > $f.tmp && mv $f.tmp $f; done

if [ "$install" = "true" ]; then
  ./install.sh
fi
