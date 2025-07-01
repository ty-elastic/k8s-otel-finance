source /opt/workshops/elastic-retry.sh

export $(curl http://kubernetes-vm:9000/env | xargs)

deploy=true
operator=true
wait=true
while getopts "i:o:w:" opt
do
   case "$opt" in
      d ) deploy="$OPTARG" ;;
      o ) operator="$OPTARG" ;;
      w ) wait="$OPTARG" ;;
   esac
done

/opt/workshops/vscode-start.sh

if [ "$operator" = "true" ]; then
    /workspace/workshop/instruqt/tools/otel.sh
fi

/workspace/workshop/instruqt/tools/install.sh -d $deploy

if [ "$wait" = "true" ]; then
   retry_command_lin curl --silent --fail --output /dev/null --header "Authorization: Basic $ELASTICSEARCH_AUTH_BASE64" "$ELASTICSEARCH_URL/_cat/indices/.ds-traces-*?allow_no_indices=false"
fi