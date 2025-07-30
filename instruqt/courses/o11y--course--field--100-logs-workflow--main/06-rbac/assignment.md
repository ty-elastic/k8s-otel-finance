---
slug: rbac
id: nxo4fxk0dray
type: challenge
title: Protecting Data with RBAC
tabs:
- id: anstrmekrtc2
  title: Elasticsearch
  type: service
  hostname: kubernetes-vm
  path: /app/discover#/?_g=(filters:!(),query:(language:kuery,query:''),refreshInterval:(pause:!t,value:60000),time:(from:now-1h,to:now))&_a=(breakdownField:log.level,columns:!(),dataSource:(type:esql),filters:!(),hideChart:!f,interval:auto,query:(esql:'FROM%20logs-proxy.otel-default'),sort:!(!('@timestamp',desc)))
  port: 30001
- id: qxodixi0jlll
  title: Elasticsearch (Limited)
  type: service
  hostname: kubernetes-vm
  path: /app/discover#/?_g=(filters:!(),query:(language:kuery,query:''),refreshInterval:(pause:!t,value:60000),time:(from:now-1h,to:now))&_a=(breakdownField:log.level,columns:!(),dataSource:(type:esql),filters:!(),hideChart:!f,interval:auto,query:(esql:'FROM%20logs-proxy.otel-default'),sort:!(!('@timestamp',desc)))
  port: 30002
  custom_request_headers:
  - key: Authorization
    value: Basic bGltaXRlZF91c2VyOmVsYXN0aWM=
- id: poj3poztpezq
  title: Terminal
  type: terminal
  hostname: kubernetes-vm
difficulty: basic
timelimit: 600
enhanced_loading: false
---
Sometimes our data contains PII information which needs to be kept to a need-to-know basis. With Elastic's in-built support for RBAC, this is easy.

We've created a limited_user with a limited_role which restricts access to the `client.ip` and `body.text` fields (to avoid leaking the `client.ip`).

In the Elasticsearch tab, we are logged in as a user with full privileges. Let's check our access.
1. Open the [button label="Elasticsearch"](tab-0) tab
2. Open a log record
3. Note access to the `client.ip` and `body.text` fields

In the Elasticsearch (Limited) tab, we are logged in as a user with full privileges. Let's check our access.

1. Open the [button label="Elasticsearch (Limited)"](tab-1) tab
2. Open a log record
3. Note that `client.ip` and `body.text` fields don't exist

Let's change permissions and see what happens:

1. Open the [button label="Elasticsearch"](tab-0) tab
2. Navigate to `Management` > `Stack Management` > `Security` > `Roles`
3. Select `limited_viewer`
4. For Indices `logs-proxy.otel-default` click `Grant access to specific fields`
5. Update `Denied fields` to be only `client.ip`, but remove `body.text`
6. Click `Update role`

1. Open the [button label="Elasticsearch (Limited)"](tab-1) tab
2. Close the open log record flyout
3. Run the search query again
4. Open a log record
5. Note that `client.ip` doesn't exist, but `body.text` now does!

