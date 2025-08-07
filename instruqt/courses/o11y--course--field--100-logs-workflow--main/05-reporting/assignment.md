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

# Generating a breakdown of user agents

In general, it would be nice to have a graphical breakdown of the makeup of our clients.

We can accomplish this using our parsed User Agent string and ES|QL.

Execute the following query:
```
FROM logs-proxy.otel-default
| WHERE user_agent.os.name IS NOT NULL
| STATS COUNT() by user_agent.os.name, user_agent.os.version
```

1. Click on the pencil icon to the right of the existing graph
2. Select `Treemap` from the visualizations drop-down menu
3. Click `Apply and close`

Let's save it to our Dashboard for future use.

1. Click on the Disk icon in the upper-left of the resulting graph
2. Name the visualization
  ```
  Client OSs
  ```
3. Select `Existing` under `Add to dashboard`
4. Select the existing dashboard `Ingress Proxy`
5. Click `Save and go to Dashboard`
6. Once the dashboard has loaded, click the `Save` button in the upper-right

Let's also create a chart depicting the overall breakdown of Browsers.

Navigate back to Discover.

Execute the following query:
```
FROM logs-proxy.otel-default
| WHERE user_agent.name IS NOT NULL
| STATS COUNT() by user_agent.name
```

1. Click on the pencil icon to the right of the existing graph
2. Select `Pie` from the visualizations drop-down menu
3. Click `Apply and close`

Let's save it to our Dashboard for future use.

1. Click on the Disk icon in the upper-left of the resulting graph
2. Name the visualization
  ```
  Client Browsers
  ```
3. Select `Existing` under `Add to dashboard`
4. Select the existing dashboard `Ingress Proxy`
5. Click `Save and go to Dashboard`
6. Once the dashboard has loaded, click the `Save` button in the upper-right

# Generating a table of user agents

It would also be helpful is to keep track of new User Agents as they appear in the wild.

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
| SORT @timestamp.min ASC // sort first seen to last seen
| STATS first_country_iso_code = TOP(client.geo.country_iso_code , 1, "asc"), first_seen = MIN(@timestamp.min), last_seen = MAX(@timestamp.max) BY user_agent.full
| SORT user_agent.full, first_seen, last_seen, first_country_iso_code
```

Fabulous! Now we can see every User Agent we encounter, when we first encountered it, and in what region it was first seen.

Say you also wanted to know when a given User Agent was released by the developer?

We could try to maintain our own User Agent lookup table and use ES|QL `LOOKUP JOIN`s to match browser versions to release dates:

Execute the following query:
```
FROM ua_lookup
```

We built this table by hand; it is far from comprehensive. Now let's use `LOOKUP JOIN` to do a real-time lookup for each row:

Execute the following query:
```
FROM logs-proxy.otel-default
| WHERE user_agent.full IS NOT NULL
| EVAL user_agent.name_and_vmajor = SUBSTRING(user_agent.full, 0, LOCATE(user_agent.full, ".")-1)
| STATS @timestamp.min = MIN(@timestamp), @timestamp.max = MAX(@timestamp) BY user_agent.name_and_vmajor, client.geo.country_iso_code
| SORT @timestamp.min ASC // sort first seen to last seen
| STATS first_country_iso_code = TOP(client.geo.country_iso_code , 1, "asc"), first_seen = MIN(@timestamp.min), last_seen = MAX(@timestamp.max) BY user_agent.name_and_vmajor
| SORT user_agent.name_and_vmajor, first_seen, last_seen, first_country_iso_code
| LOOKUP JOIN ua_lookup ON user_agent.name_and_vmajor
| KEEP release_date, user_agent.name_and_vmajor, first_country_iso_code, first_seen, last_seen
```

We can quickly see the problem with maintaining our own `ua_lookup` index. It would take a lot of work to truly track the release date of every Browser version in the wild.

Fortunately, Elastic makes it possible to leverage an external Large Language Model (LLM) to lookup those browser release dates for us!

Execute the following query:
```
FROM logs-proxy.otel-default
| WHERE user_agent.full IS NOT NULL
| STATS @timestamp.min = MIN(@timestamp), @timestamp.max = MAX(@timestamp) BY user_agent.full, client.geo.country_iso_code
| SORT @timestamp.min ASC // sort first seen to last seen
| STATS first_country_iso_code = TOP(client.geo.country_iso_code , 1, "asc"), first_seen = MIN(@timestamp.min), last_seen = MAX(@timestamp.max) BY user_agent.full
| SORT first_seen DESC
| LIMIT 10 // intentionally limit to top 10 first_seen to limit LLM completions
| EVAL prompt = CONCAT(
   "when did this version of this browser come out? output only a version of the format mm/dd/yyyy",
   "browser: ", user_agent.full
  ) | COMPLETION release_date = prompt WITH openai_completion
| EVAL release_date = DATE_PARSE("MM/dd/YYYY", release_date)
| KEEP release_date, first_country_iso_code, user_agent.full, first_seen, last_seen
```

> [!NOTE]
> If this encounters a timeout, try executing the query again.

You'll note that we are limiting our results to only the top 10 last seen User Agents. This is intentional to limit the number of `COMPLETION` commands executed, as each one will result in a call to our configured external Large Language Model (LLM). Notably, the use of the `COMPLETION` command is in Tech Preview; future revisions of ES|QL may include a means to more practically scale the use of the `COMPLETION` command.

Let's save this search for future reference:

1. Click `Save`
2. Set `Title` to
  ```
  ua_release_dates
  ```

Now let's add this as a table to our dashboard

1. Navigate to Dashboards and open `Ingress Status`
2. Click `Add from library`
3. Find `ua_release_dates`
4. Click `Save`

# Scheduling a report

The CIO is concerned about us not testing new browsers sufficiently, and for some time wants a nightly report of our dashboard. No problem!

1. Click `Download` icon
2. Select `Schedule exports`
3. Click `Schedule exports`

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
8. Click `> Next`
9. Set the `Transform ID` to
  ```
  user_agents
  ```
10. Set `Time field` to `@timestamp.min`
11. Set `Continuous mode`
12. Open `Advanced settings` and set the Frequency to `5s`
13. Click `Next`
14. Click `Create and start`

> [!NOTE]
> Because we are moving quickly, Elasticsearch may take some time to update field lists in the UI. If you encounter a situation where Elasticsearch doesn't recognize one of the fields we just parsed, click the Refresh icon in the upper-right of the Instruqt tab and try again to create the Map.

Let's create a new alert which will fire whenever a new User Agent is seen.

1. Navigate to `Alerts`
2. Click `Manage Rules`
2. Click `Create Rule`
4. Select `Custom threshold`
5. Set `DATA VIEW` to `user_agents`
6. Set `IS ABOVE` to `1`
7. Set `FOR THE LAST` to `5 minutes`
8. Set `Rule schedule` to `5 seconds`
9. Set `Rule name` to `New UA Detected`
10. Set `Tags` to
  ```
  ingress
  ```
11. Set `Related dashboards` to `Ingress Proxy`
12. Click `Create rule`

# Let's test it

1. Navigate to the [button label="Terminal"](tab-1) tab
2. Run the following command:
```bash,run
curl -X POST http://kubernetes-vm:32003/err/browser/chrome
```

This will create a new Chrome UA 137. Let's go to our dashboard and see if we can spot it.

1. Navigate to the [button label="Elasticsearch"](tab-0) tab
2. Navigate to Dashboards
3. Select `Ingress Proxy`

Look at the table of UAs that we added and note the addition of Chrome 137! You'll also note a new active alert `New UA Detected`!

# Summary

Let's take stock of what we know:

* a small percentage of users are experiencing 500 errors
* the errors started occurring around 80 minutes ago
* the only error type seen is 500
* the errors occur over all APIs
* the errors occur only in the `TH` region
* the errors occur only with browsers based on Chrome v136

And what we've done:

* Created a Dashboard showing ingress status
* Created a simple alert to let us know if we ever return non-200 error codes
* Parsed the logs for quicker and more powerful analysis
* Create a SLO to let us know if we ever return non-200 error codes over time
* Created a Pie Graph showing errors by region
* Created a Map to help us visually geo-locate the errors
* Created graphs in our dashboard showing the breakdown of User Agents
* Created a table in our dashboard iterating seen User Agents
* Created a nightly report to snapshot our Dashboard
* Created an alert to let us know when a new User Agent string appears