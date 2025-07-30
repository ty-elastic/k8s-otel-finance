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
8. Add an aggregation for `top_metrics(user_agent.original)`
9. Set the `Transform ID` to `user_agents`
10. Set `Continuous mode`
11. Click `Next`
12. Click `Create and start`


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
  | KEEP release_date, user_agent.full, @timestamp.min, @timestamp.max, top_metrics.user_agent.original
```

Let's save this search for future reference:

1. Click `Save`
2. Set `Title` to `ua_release_dates`

Now let's add this as a table to our dashboard

1. Navigate to Dashboards and open `Ingress Status`
2. Click `Add from library`
3. Find `ua_release_dates`
4. Click `Save`

Now let's setup a schedule to automatically export our dashboard as a PDF every night for the exec office.

1. Click `Download` icon
2. Click `Schedule exports`
3. Click `Schedule export`

# Alert

Let's create a new alert!

1. Navigate to `Management` > `Stack Management` > `Alerts and Insights` > `Rules`
2. Click `Create rule`
4. Select `Index threshold`
5. Click `INDEX`
6. Set `Indices to query` to `user_agents` and `Time field` to `@timestamp_max`
6. Set `IS ABOVE` to `1`
7. Set `FOR THE LAST` to `5 minutes`
8. Set `Rule name` to `New UA Detected`
9. Set `Related dashboards` to `Ingress Proxy`
10. Click `Create rule`

Now, let's test it!

1. Navigate to the Terminal tab
2. Run the following command:
```bash,run
curl -X POST http://kubernetes-vm:32003/err/browser/chrome
```

Let's see if we fired an alert:

1. Navigate to `Management` > `Stack Management` > `Alerts and Insights` > `Rules`