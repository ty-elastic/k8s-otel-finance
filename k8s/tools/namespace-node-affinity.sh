git clone https://github.com/idgenchev/namespace-node-affinity.git
kubectl apply -k namespace-node-affinity/deployments/base
rm -rf namespace-node-affinity
