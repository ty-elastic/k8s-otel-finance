source /opt/workshops/elastic-retry.sh

export $(curl http://kubernetes-vm:9000/env | xargs)

deploy=true
otel=true
wait=true
while getopts "i:o:w:" opt
do
   case "$opt" in
      d ) deploy="$OPTARG" ;;
      o ) otel="$OPTARG" ;;
      w ) wait="$OPTARG" ;;
   esac
done

WORKSPACE_DIR=/workspace
WORKSHOP_DIR=$WORKSPACE_DIR/workshop
echo '{
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "terminal",
            "type": "shell",
            "command": "/usr/bin/bash",
            "args": [
                "-l"
            ],
            "isBackground": true,
            "problemMatcher": [],
            "presentation": {
                "group": "none"
            },
            "runOptions": {
                "runOn": "folderOpen"
            },
        }
    ]
}' >> $WORKSPACE_DIR/.vscode/tasks.json
/opt/workshops/vscode-start.sh

echo "Enable Streams"
enable_streams() {
    local http_status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$KIBANA_URL/internal/kibana/settings" \
    -H 'Content-Type: application/json'\
    --header "kbn-xsrf: true" --header "Authorization: Basic $ELASTICSEARCH_AUTH_BASE64" \
    -d '{"changes":{"observability:enableStreamsUI":true}}')

    if echo $http_status | grep -q '^2'; then
        echo "Enabled Streams: $http_status"
        return 0
    else
        echo "Failed to enable streams. HTTP status: $http_status"
        return 1
    fi
}
retry_command_lin enable_streams

if [ "$otel" = "true" ]; then
    /workspace/workshop/instruqt/tools/otel.sh
fi

/workspace/workshop/instruqt/tools/install.sh -d $deploy -o $otel

if [ "$wait" = "true" ]; then
   retry_command_lin curl --silent --fail --output /dev/null --header "Authorization: Basic $ELASTICSEARCH_AUTH_BASE64" "$ELASTICSEARCH_URL/_cat/indices/.ds-traces-*?allow_no_indices=false"
fi