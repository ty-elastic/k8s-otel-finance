source build_vars.sh

for f in ../../k8s/*.yaml; do envsubst < $f | kubectl apply -f -; done
