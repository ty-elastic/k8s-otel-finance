source /opt/workshops/elastic-retry.sh

export $(curl http://kubernetes-vm:9000/env | xargs)

install=true
operator=true
while getopts "i:o:" opt
do
   case "$opt" in
      i ) install="$OPTARG" ;;
      i ) operator="$OPTARG" ;;
   esac
done

/opt/workshops/vscode-start.sh

if [ "$operator" = "true" ]; then
    /workspace/workshop/instruqt/tools/otel.sh
fi

/workspace/workshop/instruqt/tools/install.sh -i $install

#retry_command_lin curl --silent --fail --output /dev/null --header "Authorization: Basic $ELASTICSEARCH_AUTH_BASE64" "$ELASTICSEARCH_URL/_cat/indices/.ds-traces-*?allow_no_indices=false"
