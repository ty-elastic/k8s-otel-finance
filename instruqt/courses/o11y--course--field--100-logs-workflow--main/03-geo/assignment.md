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

Let's jump back to Discover by clicking Discover in the left-hand navigation pane. It will take a minute for the new processing chain to take effect.

Execute the following query:
```esql
FROM logs-proxy.otel-default
| WHERE client.geo.country_iso_code IS NOT NULL AND http.response.status_code IS NOT NULL
| STATS COUNT() BY http.response.status_code, client.geo.country_iso_code
```

Let's make this a pie chart to allow for more intuitive visualization.

1. Click the pencil icon to the right of the graph
2. Select `Pie` from the dropdown menu

So it looks like all of our 500 errors are contained in the `TW` region. Interesting!

This is a useful graph! Let's save it to a Dashboard for future use.

1. Click on the Disk icon in the upper-left of the resulting graph
2. Add to a existing dashboard "Ingress Proxy"
3. Click `Save and go to dashboard`
4. Click `Save` in the upper-right

# Maps

1. Navigate to `Other tools` > `Maps`
2. Click `Add layer`
3. Select `Elasticsearch`
4. Select `Documents`
5. Select `Data view` to `logs-proxy.otel-default`
6. Set `Geospatial field` to `client.geo.location`
7. Click `Add and continue`
8. Scroll down to `Layer style`
9. Set `Fill color` to `By value`
10. Set `Select a field` to `http.response.status_code`
11. Set `As number` to `As category`
12. Set `Symbol Size` to `By value`
12. Set `Select a field` to `http.response.status_code`
13. Click `Keep changes`
14. Click `Save`
15. Name the Map `Status Code by Location`
15. Select existing dashboard `Ingress Status`
16. Click `Save and go to dashboard`

