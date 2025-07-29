---
slug: streams
id: yq40fososffi
type: challenge
title: Parsing with Streams
tabs:
- id: vawi9hfwm84x
  title: Elasticsearch
  type: service
  hostname: kubernetes-vm
  path: /app/streams
  port: 30001
- id: isa63xsajnki
  title: Terminal
  type: terminal
  hostname: kubernetes-vm
difficulty: basic
timelimit: 600
enhanced_loading: false
---
So far, we've been parsing our nginx logs at query time with ES|QL. While incredibly powerful for quick analysis, we can do even more with our logs if we parse them at ingest-time. This is a typical workflow: start with query-time parsing with ES|QL, and if you find a useful pattern, move it ingest-time parsing with Streams.

1. Select `logs-proxy.otel-default` from the list of Streams.
2. Select the `Processing` tab
3. Click `Add a processor`
4. Select `Grok` for the `Processor` if not already selected
5. Set the `Field` to `body.text` if not already filled in
6. Click `Generate pattern`

The generated pattern should look very similar to the following:
```
%{IPV4:client.ip} %{NOTSPACE:http.auth} %{NOTSPACE:http.auth2} \[%{HTTPDATE:timestamp}\] "%{WORD:http.request.method} %{URIPATH:url.path} HTTP/%{NUMBER:http.version}" %{NUMBER:http.response.status_code:int} %{NUMBER:http.response.body.bytes:int} "%{DATA:http.request.referrer}" "%{GREEDYDATA:user_agent.original}"
```

7. Click `Accept`
8. Click `Add processor`

The nginx log line includes a timestamp; let's use that as our record timestamp.

1. Click `Add a processor`
2. Select `Date`
3. Set `Field` to `timestamp`
4. Elastic should auto-recognize the format: `dd/MMM/yyyy:HH:mm:ss XX`
5. Click `Add processor`

Now let's jump back to Discover by clicking Discover in the left-hand navigation pane.

Execute the following query:
```esql
FROM logs-proxy.otel-default
| KEEP @timestamp, client.ip, http.request.method, url.path, http.response.status_code, user_agent.original
```

Let's redraw our status code graph using our newly parsed field:

Execute the following query:
```
FROM logs-proxy.otel-default
| STATS COUNT() BY TO_STRING(http.response.status_code), minute = BUCKET(@timestamp, "1 min")
```

This is a useful graph! Let's save it to a Dashboard for future use.

1. Click on the Disk icon in the upper-left of the resulting graph
2. Add to a existing dashboard "Ingress Proxy"

# Create SLO

Remember that alert we created. Now that we are parsing these fields at ingest-time, we can create a proper SLO which allows for a small amount of errors:

1. Click `SLOs` in the left-hand navigation
2. Click `Create SLO`
3. Select `Custom Query`
4. Set `Data view` to `logs-proxy.otel-default`
5. Set `Query filter` to `http.response.status_code >= 400`
6. Set `Good query` to `http.response.status_code : 200`
7. Set `Total query` to `http.response.status_code :*`
8. Set `Group by` to `url.path`
9. Set `SLO Name` to `Ingress Status`
10. Click `Create SLO`
11. Click on your newly created SLO `Ingress Status`
12. Under the `Actions` menu in the upper-right, select `Create new alert rule`

Note the flexibility in burn rates.

13. Click `Next`
14. (could add an action)
15. Click `Next`
16. Click `Create rule`

