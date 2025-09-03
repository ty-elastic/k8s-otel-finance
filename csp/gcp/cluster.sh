project="elastic-sa"
name="tbekiares-demo"
zone="us-central1-a"
labels="division=field,org=sa,team=pura,project=tyronebekiares"

while getopts "p:n:z:l:" opt
do
   case "$opt" in
      p ) project="$OPTARG" ;;
      n ) name="$OPTARG" ;;
      z ) zone="$OPTARG" ;;
      l ) labels="$OPTARG" ;;
   esac
done

gcloud beta container clusters delete $name

gcloud beta container --project $project clusters create $name --zone $zone --tier "standard" --no-enable-basic-auth --cluster-version "1.33.2-gke.1240000" --release-channel "regular" --machine-type "n2-standard-4" --image-type "COS_CONTAINERD" --disk-type "pd-balanced" --disk-size "1000" --metadata disable-legacy-endpoints=true --num-nodes "2" --logging=NONE --enable-ip-alias --network "projects/$project/global/networks/default" --subnetwork "projects/$project/regions/us-central1/subnetworks/default" --no-enable-intra-node-visibility --default-max-pods-per-node "110" --enable-ip-access --security-posture=standard --workload-vulnerability-scanning=disabled --no-enable-google-cloud-access --addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver --enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0 --labels $labels --binauthz-evaluation-mode=DISABLED --no-enable-managed-prometheus --enable-shielded-nodes --shielded-integrity-monitoring --no-shielded-secure-boot --node-locations $zone

gcloud container clusters get-credentials $name --zone $zone --project $project

#------- TOOLS

source ../../k8s/tools/ksm.sh
source ../../k8s/tools/namespace-node-affinity.sh

#------- LABEL NODES

# Get the names of all nodes in the cluster
NODES=$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}')

REGION=0

# Loop through each node and apply the label
for NODE in $NODES; do
   REGION=$(expr $REGION + 1)
   echo "Applying label region=$REGION to node: $NODE"
   kubectl label node "$NODE" "region=$REGION" --overwrite
done
