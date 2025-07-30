---
slug: reporting
id: lxkd6xcqmk0m
type: challenge
title: Dashboards
tabs:
- id: ijfyyxmq23sz
  title: Elasticsearch
  type: service
  hostname: kubernetes-vm
  path: /app/streams
  port: 30001
- id: kkeiiypxhfht
  title: Terminal
  type: terminal
  hostname: kubernetes-vm
difficulty: basic
timelimit: 600
enhanced_loading: false
---

```
FROM logs-proxy.otel-default
| WHERE parsed.user_agent.version IS NOT NULL
| STATS versions = VALUES(CONCAT(parsed.user_agent.name, " ", parsed.user_agent.version))
| EVAL versions = MV_DEDUPE(versions)
| STATS version = MV_SORT(versions) BY versions
```

would be nice to know when we first started seeing new versions, and alert when another new version is seen.
We can do this with a transform!

Create transform:
1. Navigate to `Management` > `Stack Management` > `Transforms`
2. Click `Create a transform`
3. Select `logs-proxy.otel-default`
4. Select `Pivot`
5. Set `Search filter` to `user_agent.full :*`
5. Set `Group by` to `terms(user_agent.full)`
6. Add an aggregation for `@timestamp.max`
7. Add an aggregation for `@timestamp.min`
8. Set the `Transform ID` to `user_agents`
9. Set `Continuous mode`
9. Click `Next`
10. Click `Create and start`


Go to Discover.

```
FROM user_agents
```

Lookup for user_agent release date.

```
FROM user_agents
| SORT @timestamp.max DESC
| LIMIT 10
| LOOKUP JOIN ua_lookup ON user_agent.full
| KEEP release_date, user_agent.full, @timestamp.min, @timestamp.max
```

But this would take too long. use completion!

```
FROM user_agents
| SORT @timestamp.max DESC
| LIMIT 10
| EVAL prompt = CONCAT(
   "when did this version of this browser come out? output only a version of the format mm/dd/yyyy",
   "browser: ", user_agent.full
  ) | COMPLETION release_date = prompt WITH openai_completion
  | KEEP release_date, user_agent.full, @timestamp.min, @timestamp.max
```

Save search

1. Dashboards
2. Click `Add Panel`
3. Select `ES|QL` (saved search?)
4. Enter:
```
FROM user_agents
| SORT @timestamp.max DESC
| LIMIT 10
| EVAL prompt = CONCAT(
   "when did this version of this browser come out? output only a version of the format mm/dd/yyyy",
   "browser: ", user_agent.full
  ) | COMPLETION release_date = prompt WITH openai_completion
  | KEEP release_date, user_agent.full, @timestamp.min, @timestamp.max
```
5. Click `Run query`
6. Click `Apply and close`

Now let's setup a schedule to automatically export our dashboard as a PDF every night for the exec office.

1. Click `Download` icon
2. Click `Schedule export`

# Alert

Let's create a new alert!

1. Navigate to `Management` > `Stack Management` > `Alerts and Insights` > `Rules`
2. Click `Create rule`
4. Select `Index threshold`
5. Set `INDEX` to `user_agents` and `Time field` to `@timestamp_max`
6. Set `IS ABOVE` to `1`
7. Set `FOR THE LAST` to `5 minutes`
8. Set `Rule name` to `New UA Detected`
9. Set `Related dashboards` to `Ingress Proxy`
10. Click `Create rule`
