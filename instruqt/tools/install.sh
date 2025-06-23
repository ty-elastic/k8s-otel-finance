source /opt/workshops/elastic-retry.sh

export $(curl http://kubernetes-vm:9000/env | xargs)

cat > /workspace/workshop/instruqt/$INSTRUQT_TRACK_SLUG/build_vars.sh << EOF
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

if [ -d "k8s/variants/$INSTRUQT_TRACK_SLUG" ]; then \
    echo $INSTRUQT_TRACK_SLUG; \
    patch < variants/$INSTRUQT_TRACK_SLUG/init.patch
fi

./install.sh
