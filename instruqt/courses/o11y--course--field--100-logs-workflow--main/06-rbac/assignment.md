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

1. Open the [button label="Elasticsearch (Limited)"](tab-1) tab
2. Note access to the `client.ip` and `body.text` fields

Remove these:

1. Navigate to `Management` > `Stack Management` > `Security` > `Roles`
2. Select `limited_viewer`
3. For Indices `/logs-proxy\.otel-default.*/` click `Grant access to specific fields`
4. Under `Denied fields` set `client.ip,body.text`
5. Click `Update role`

Reload Elasticsearch limited

Note client.ip and body.text are gone!

Click on Elasticsearch (limited). Note new user.

Open stuff.
