export BUILD_TAG=latest

for f in k8s/*.yaml; do envsubst < $f | kubectl apply -f -; done
