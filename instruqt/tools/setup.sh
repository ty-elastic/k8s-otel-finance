source /opt/workshops/elastic-retry.sh

export $(curl http://kubernetes-vm:9000/env | xargs)

install=true
while getopts "i:" opt
do
   case "$opt" in
      i ) install="$OPTARG" ;;
   esac
done

/opt/workshops/vscode-start.sh

/workspace/workshop/instruqt/tools/otel.sh

/workspace/workshop/instruqt/tools/install.sh -i $install

#retry_command_lin curl --silent --fail --output /dev/null --header "Authorization: Basic $ELASTICSEARCH_AUTH_BASE64" "$ELASTICSEARCH_URL/_cat/indices/.ds-traces-*?allow_no_indices=false"
