export $(cat ./build_vars.sh | xargs)

for f in k8s/*.yaml; do envsubst < $f | kubectl apply -f -; done
