export BUILD_TAG=2025-06-03
for f in k8s/*.yaml; do envsubst < $f | kubectl apply -f -; done
