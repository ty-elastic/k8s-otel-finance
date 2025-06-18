source /opt/workshops/elastic-retry.sh

export $(curl http://kubernetes-vm:9000/env | xargs)
export $(cat /workspace/workshop/instruqt/$INSTRUQT_TRACK_SLUG/build_vars.sh | xargs)

cp -f /workspace/workshop/instruqt/$INSTRUQT_TRACK_SLUG/build_vars.sh /workspace/workshop/build_vars.sh

/opt/workshops/vscode-start.sh

/workspace/workshop/instruqt/tools/otel.sh

/workspace/workshop/instruqt/tools/install.sh

#retry_command_lin curl --silent --fail --output /dev/null --header "Authorization: Basic $ELASTICSEARCH_AUTH_BASE64" "$ELASTICSEARCH_URL/_cat/indices/.ds-traces-*?allow_no_indices=false"
