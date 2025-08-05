---
slug: pii
id: nxo4fxk0dray
type: challenge
title: Protecting Data
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
Sometimes our data contains PII information which needs to be kept to a need-to-know basis and only for a given time.

# Limiting access

With Elastic's in-built support for RBAC, we can limit access at the index, document, or field level.

In this example, we've created a limited_user with a limited_role which restricts access to the `client.ip` and `body.text` fields (to avoid leaking the `client.ip`).

In the Elasticsearch tab, we are logged in as a user with full privileges. Let's check our access.
1. Open the [button label="Elasticsearch"](tab-0) tab
2. Open a log record and click on the `Table` tab in the flyout
3. Note access to the `client.ip` and `body.text` fields

In the Elasticsearch (Limited) tab, we are logged in as a user with full privileges. Let's check our access.

1. Open the [button label="Elasticsearch (Limited)"](tab-1) tab
2. Open a log record and click on the `Table` tab in the flyout
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

# Limiting retention

Say your records department requires you to keep these logs generally accessible only for a very specific period of time. We can ask Elasticsearch to automatically delete them after some number of days.

1. Open the [button label="Elasticsearch"](tab-0) tab
2. Navigate to `Streams`
3. Select `logs-proxy.otel-default` from the list of Streams
4. Click on the `Data retention` tab
5. Click `Edit data retention`
6. Set to `30` days

Elasticsearch will now remove this data from its online indices after 30 days. At that time, it will only be available in backups.

# Summary

Let's take stock of what we know:

* a small percentage of users are experiencing 500 errors
* the errors started occurring around 80 minutes ago
* the only error type seen is 500
* the errors occur over all APIs
* the errors occur only in the `TW` region
* the errors occur only with browsers based on Chrome v136

And what we've done:

* Created a Dashboard showing status code over time
* Created a simple alert to let us know if we ever return non-200 error codes
* Parsed the logs for quicker and more powerful analysis
* Create a SLO to let us know if we ever return non-200 error codes over time
* Created a Pie Graph showing errors by region
* Created a Map to help us visually geo-locate the errors
* Created a table in our dashboard iterating seen User Agents
* Created a nightly report to snapshot our Dashboard
* Created an alert to let us know when a new User Agent string appears
* Setup RBAC to restrict access to `client.ip`
* Setup retention to keep the logs online for only 30 days
