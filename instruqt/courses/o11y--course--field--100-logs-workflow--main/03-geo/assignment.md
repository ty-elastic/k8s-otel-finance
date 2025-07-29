---
slug: geo
id: wex8hob0j9kz
type: challenge
title: Analyzing by GEO
tabs:
- id: eqsvxidyavvw
  title: Elasticsearch
  type: service
  hostname: kubernetes-vm
  path: /app/streams
  port: 30001
- id: enj1oldehuby
  title: Terminal
  type: terminal
  hostname: kubernetes-vm
difficulty: basic
timelimit: 600
enhanced_loading: false
---

Now that we are parsing our logs at ingest, let's see if we can do some analysis around the geography of our clients.

1. Select `logs-proxy.otel-default` from the list of Streams.
2. Select the `Processing` tab
3. Click `Add a processor`
4. Select `GeoIP`
5. Set the `Field` to `client.ip`
6. Open `Optional fields` and set `Target field` to `client.geo`
7. Set `Ignore missing` to true
8. Click `Add processor`
9. Click `Save changes`

Now let's jump back to Discover by clicking Discover in the left-hand navigation pane.

Execute the following query:
```esql
FROM logs-proxy.otel-default
| WHERE parsed.geo.country_iso_code IS NOT NULL
| STATS COUNT() BY parsed.http.response.status_code, parsed.geo.country_iso_code
```

1. Change to PIE graph?

This is a useful graph! Let's save it to a Dashboard for future use.

1. Click on the Disk icon in the upper-left of the resulting graph
2. Add to a existing dashboard "Ingress Proxy"

and we can get really fancy and lookup

FROM logs-proxy.otel-default
| WHERE parsed.http.response.status_code == 500
| ENRICH networks-policy ON parsed.client.ip
| STATS COUNT() BY parsed.geo.country_iso_code, isp

could add to dashboard, but lets make a map

# Maps

Layer Style

Fill Color

By Value `parsed.http.response.status_code`
200
500

this graph is useful. add to dashboard
