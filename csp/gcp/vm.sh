project="elastic-sa"
name="tbekiares-keep"
zone="us-central1-c"
labels="division=field,org=sa,team=pura,project=tyronebekiares"

gcloud compute instances delete $name \
    --project=$project \
    --zone=$zone \

gcloud compute instances create $name \
    --project=$project \
    --zone=$zone \
    --machine-type=n2-standard-8 \
    --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --service-account=1059491012611-compute@developer.gserviceaccount.com \
    --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/trace.append \
    --create-disk=auto-delete=yes,boot=yes,device-name=$name,image=projects/debian-cloud/global/images/debian-12-bookworm-v20250812,mode=rw,size=1024,type=pd-balanced \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --labels=$labels \
    --reservation-affinity=any
