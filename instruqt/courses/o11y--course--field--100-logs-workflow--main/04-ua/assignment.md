---
slug: ua
id: y89elnycbugj
type: challenge
title: Analyzing by User Agent
tabs:
- id: b6ohgb7enbox
  title: Elasticsearch
  type: service
  hostname: kubernetes-vm
  path: /app/streams
  port: 30001
- id: tphygyq6udbv
  title: Terminal
  type: terminal
  hostname: kubernetes-vm
difficulty: basic
timelimit: 600
enhanced_loading: false
---
Now that we are parsing our logs at ingest, let's see if we can do some analysis around the user_agent of our clients.

1. Select `logs-proxy.otel-default` from the list of Streams.
2. Select the `Processing` tab
3. Click `Add a processor`
4. Select `User agent`
5. Set the `Field` to `user_agent.original`
6. Set `Ignore missing` to true
7. Click `Add processor`

In addition to the fields produced by the User Agent processor, we also want a simplified combination of browser name and version. We can easily craft one using the Set processor.

1. Click `Add a processor`
2. Click `Set`
3. Set `Field` to `user_agent.full`
4. Set `Value` to `{{user_agent.name}} {{user_agent.version}}`
5. Click `Ignore failures for this processor`
6. Click `Add processor`
7. Click `Save changes`

Now let's jump back to Discover by clicking Discover in the left-hand navigation pane.

Execute the following query:
```esql
FROM logs-proxy.otel-default
| WHERE user_agent.full IS NOT NULL
| STATS good = COUNT(http.response.status_code == 200 OR NULL), bad = COUNT(http.response.status_code == 500 OR NULL) BY user_agent.full
| SORT bad DESC
```

Ah-ha, this seems to be related to the Browser version!

```esql
FROM logs-proxy.otel-default
| WHERE user_agent.full IS NOT NULL
| STATS good = COUNT(http.response.status_code == 200 OR NULL), bad = COUNT(http.response.status_code == 500 OR NULL) BY user_agent.version
| SORT bad DESC
```

Execute the following query:
```esql
FROM logs-proxy.otel-default
| WHERE client.geo.country_iso_code IS NOT NULL AND user_agent.version IS NOT NULL AND http.response.status_code IS NOT NULL
| EVAL version_major = SUBSTRING(user_agent.version,0,LOCATE(user_agent.version, ".")-1)
| WHERE TO_INT(version_major) == 136
| STATS COUNT() BY client.geo.country_iso_code
```

Congrats! we found our problem! Let's find a way to make this easier to catch in the future.