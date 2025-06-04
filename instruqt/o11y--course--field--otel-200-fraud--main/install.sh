source build_vars.sh

export BUILD_TAG=$COURSE_$BUILD_TAG
for f in k8s/*.yaml; do envsubst < $f | kubectl apply -f -; done
