---
slug: reporting
id: lxkd6xcqmk0m
type: challenge
title: Reporting
tabs:
- id: ijfyyxmq23sz
  title: Elasticsearch
  type: service
  hostname: kubernetes-vm
  path: /app/discover#/?_g=(filters:!(),query:(language:kuery,query:''),refreshInterval:(pause:!t,value:60000),time:(from:now-1h,to:now))&_a=(breakdownField:log.level,columns:!(),dataSource:(type:esql),filters:!(),hideChart:!f,interval:auto,query:(esql:'FROM%20logs-proxy.otel-default'),sort:!(!('@timestamp',desc)))
  port: 30001
- id: kkeiiypxhfht
  title: Terminal
  type: terminal
  hostname: kubernetes-vm
difficulty: basic
timelimit: 600
enhanced_loading: false
---
Now that we know what happened, let's try to be sure this never happens again.

# Generating a table of user agents

One thing that would be helpful is to keep track of new User Agents as they appear in the wild.

We can accomplish this using our parsed User Agent string and ES|QL:

Execute the following query:
```
FROM logs-proxy.otel-default
| WHERE user_agent.full IS NOT NULL
| STATS @timestamp.min = MIN(@timestamp), @timestamp.max = MAX(@timestamp) BY user_agent.full
```

This is good, but it would also be helpful, based on what we saw, to know the first country that a given User Agent appeared in.

Execute the following query:
```
FROM logs-proxy.otel-default
| WHERE user_agent.full IS NOT NULL
| STATS @timestamp.min = MIN(@timestamp), @timestamp.max = MAX(@timestamp) BY user_agent.full, client.geo.country_iso_code
| EVAL first_ts = LEAST(@timestamp.min)
| STATS client.geo.country_iso_code = TOP(client.geo.country_iso_code, 1, "desc"), user_agent.full = TOP(user_agent.full, 1, "desc") WHERE @timestamp.min == first_ts BY @timestamp.min, @timestamp.max
| SORT @timestamp.min DESC
| KEEP client.geo.country_iso_code, user_agent.full, @timestamp.min, @timestamp.max
```

Fabulous! Say you also wanted to know when a given User Agent was released?

We could try to maintain our own User Agent lookup table and use ES|QL `LOOKUP JOIN`s to match browser versions to release dates:

Execute the following query:
```
FROM ua_lookup
```

Now let's use `LOOKUP JOIN` to do a real-time lookup for each row:

Execute the following query:
```
FROM logs-proxy.otel-default
| WHERE user_agent.full IS NOT NULL
| EVAL user_agent.name_and_vmajor = CONCAT(user_agent.name, " ", SUBSTRING(user_agent.version, 0, LOCATE(user_agent.version, ".")-1))
| STATS @timestamp.min = MIN(@timestamp), @timestamp.max = MAX(@timestamp) BY user_agent.name_and_vmajor, client.geo.country_iso_code
| EVAL first_ts = LEAST(@timestamp.min)
| STATS client.geo.country_iso_code = TOP(client.geo.country_iso_code, 1, "desc"), user_agent.name_and_vmajor = TOP(user_agent.name_and_vmajor, 1, "desc") WHERE @timestamp.min == first_ts BY @timestamp.min, @timestamp.max
| SORT @timestamp.min DESC
| LIMIT 25
| LOOKUP JOIN ua_lookup ON user_agent.name_and_vmajor
| WHERE release_date IS NOT NULL
| KEEP release_date, user_agent.name_and_vmajor, client.geo.country_iso_code, @timestamp.min, @timestamp.max
```

Wow! This is great! But maintaining that `ua_lookup` index looks like a lot of work. Fortunately, Elastic makes it possible to leverage an external Large Language Model to lookup those browser release dates for us!

Execute the following query:
```
FROM logs-proxy.otel-default
| WHERE user_agent.full IS NOT NULL
| STATS @timestamp.min = MIN(@timestamp), @timestamp.max = MAX(@timestamp) BY user_agent.full, client.geo.country_iso_code
| EVAL first_ts = LEAST(@timestamp.min)
| STATS client.geo.country_iso_code = TOP(client.geo.country_iso_code, 1, "desc"), user_agent.full = TOP(user_agent.full, 1, "desc") WHERE @timestamp.min == first_ts BY @timestamp.min, @timestamp.max
| SORT @timestamp.min DESC
| LIMIT 25
| EVAL prompt = CONCAT(
   "when did this version of this browser come out? output only a version of the format mm/dd/yyyy",
   "browser: ", user_agent.full
  ) | COMPLETION release_date = prompt WITH openai_completion
| EVAL release_date = DATE_PARSE("MM/dd/YYYY", release_date)
| KEEP release_date, client.geo.country_iso_code, user_agent.full, @timestamp.min, @timestamp.max
```

Yes! Let's save this search for future reference:

1. Click `Save`
2. Set `Title` to `ua_release_dates`

Now let's add this as a table to our dashboard

1. Navigate to Dashboards and open `Ingress Status`
2. Click `Add from library`
3. Find `ua_release_dates`
4. Click `Save`

The CIO is concerned about us not testing new browsers sufficiently, and for some time wants a nightly report of our dashboard. No problem!

1. Click `Download` icon
2. Click `Schedule exports`
3. Click `Schedule export`

# Alert when a new UA is seen

Ideally, we can send an alert whenever a new User Agent is seen. To do that, we need to keep state of what User Agents we've already seen. Fortunately, Elastic Transforms makes this easy!

Create transform:
1. Navigate to `Management` > `Stack Management` > `Transforms`
2. Click `Create a transform`
3. Select `logs-proxy.otel-default`
4. Select `Pivot`
5. Set `Search filter` to `user_agent.full :*`  (if this field isn't available, refresh the Instruqt virtual browser tab)
5. Set `Group by` to `terms(user_agent.full)`
6. Add an aggregation for `@timestamp.max`
7. Add an aggregation for `@timestamp.min`
8. Set the `Transform ID` to `user_agents`
9. Set `Time field` to `@timestamp.min`
10. Set `Continuous mode`
11. Click `Next`
12. Click `Create and start`

Let's create a new alert which will fire when

1. Navigate to `Alerts`
2. Click `Manage Rules`
2. Click `Create Rule`
4. Select `Custom threshold`
5. Set `DATA VIEW` to `user_agents`
6. Set `IS ABOVE` to `1`
7. Set `FOR THE LAST` to `5 minutes`
8. Set `Rule schedule` to `5 seconds`
9. Set `Rule name` to `New UA Detected`
9. Set `Related dashboards` to `Ingress Proxy`
10. Click `Create rule`

Now, let's test it!

1. Navigate to the [button label="Terminal"](tab-1) tab
2. Run the following command:
```bash,run
curl -X POST http://kubernetes-vm:32003/err/browser/chrome
```

This will create a new Chrome UA 137. Let's go to our dashboard and see if we can spot it.

1. Navigate to the [button label="Elasticsearch"](tab-0) tab
2. Navigate to Dashboards
3. Select `Ingress Proxy`
4. Look at the table of UAs that we added and note the addition of Chrome 137!

Let's see if we fired an alert:

1. Navigate to `Alerts`
2. Note the active alert
