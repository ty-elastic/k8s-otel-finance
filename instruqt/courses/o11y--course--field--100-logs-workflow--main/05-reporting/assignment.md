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


To prevent this from happening in the future, it would be helpful to have a table of User Agents we are seeing in the field, along with the first time they were seen.

We can accomplish this partially using ES|QL:

Execute the following query:
```
FROM logs-proxy.otel-default
| WHERE user_agent.full IS NOT NULL
| STATS @timestamp.min = MIN(@timestamp), @timestamp.max = MAX(@timestamp) BY user_agent.full
```

This is great, but let's say we want to know when a given version of a UA was released:


```
FROM ua_lookup
```

and then use `LOOKUP JOIN` to do a real-time lookup for each row:


Now it would be great to match up these User Agents with their release date. We could maintain our own lookup table like this:

```
FROM logs-proxy.otel-default
| WHERE user_agent.version IS NOT NULL
| EVAL user_agent.name_and_vmajor = CONCAT(user_agent.name, " ", SUBSTRING(user_agent.version, 0, LOCATE(user_agent.version, ".")-1))
| STATS @timestamp.min = MIN(@timestamp), @timestamp.max = MAX(@timestamp) BY user_agent.name_and_vmajor
| LOOKUP JOIN ua_lookup ON user_agent.name_and_vmajor
| WHERE release_date IS NOT NULL
| KEEP release_date, user_agent.name_and_vmajor, @timestamp.min, @timestamp.max
```


But this would take too long. use completion!

```
FROM logs-proxy.otel-default
| WHERE user_agent.full IS NOT NULL
| STATS @timestamp.min = MIN(@timestamp), @timestamp.max = MAX(@timestamp) BY user_agent.full
| SORT @timestamp.max DESC
| LIMIT 10
| EVAL prompt = CONCAT(
   "when did this version of this browser come out? output only a version of the format mm/dd/yyyy",
   "browser: ", user_agent.full
  ) | COMPLETION release_date = prompt WITH openai_completion
| EVAL release_date = DATE_PARSE("MM/dd/YYYY", release_date)
| KEEP release_date, user_agent.full, @timestamp.min, @timestamp.max
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

# Alert with Transform


Let's say we want to know both the first and last time a particular user_agent was seen. And let's say we want to alert when a new UA is detected. To do the latter, we will need to keep track of what UAs we've seen and when. Elastic Transforms make this easy!

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
10. Set `Time field` to `@timestamp.min`
10. Set `Continuous mode`
11. Click `Next`
12. Click `Create and start`

Let's create a new alert!

1. Navigate to `Alerts`
2. Click `Manage Rules`
2. Click `Create Rule`
4. Select `Custom threshold`
5. Set `DATA VIEW` to `user_agents`
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