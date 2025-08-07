---
slug: esql
id: 5jclgckaczpm
type: challenge
title: Parsing with ES|QL
notes:
- type: text
  contents: |-
    You are an on-call SRE for a company which operates an online stock trading service. You were just notified that some users are experiencing issues when trying to perform stock trades.

    In this lab, we will leverage Elastic's comprehensive suite of modern log analytic tools to unlock the hidden information in your logs that will enable you to quickly perform Root Cause Analysis (RCA) of the problem. We will also create dashboards and alerts to ensure this problem doesn't happen again.
tabs:
- id: bt0a2nr0ysiz
  title: Elasticsearch
  type: service
  hostname: kubernetes-vm
  path: /app/discover#/?_g=(filters:!(),query:(language:kuery,query:''),refreshInterval:(pause:!t,value:60000),time:(from:now-1h,to:now))&_a=(breakdownField:log.level,columns:!(),dataSource:(type:esql),filters:!(),hideChart:!f,interval:auto,query:(esql:'FROM%20logs-proxy.otel-default'),sort:!(!('@timestamp',desc)))
  port: 30001
- id: 2vem8q5ukov7
  title: Terminal
  type: terminal
  hostname: kubernetes-vm
- id: sw6mcyxmqgcv
  title: Elasticsearch (breakout)
  type: service
  hostname: kubernetes-vm
  path: /app/discover#/?_g=(filters:!(),query:(language:kuery,query:''),refreshInterval:(pause:!t,value:60000),time:(from:now-1h,to:now))&_a=(breakdownField:log.level,columns:!(),dataSource:(type:esql),filters:!(),hideChart:!f,interval:auto,query:(esql:'FROM%20logs-proxy.otel-default'),sort:!(!('@timestamp',desc)))
  port: 30001
  new_window: true
difficulty: basic
timelimit: 600
enhanced_loading: false
---
We've gotten word from our customer service department that some users are unable to complete stock trades. We know that all of the REST API calls from our front end web application flow through a nginx reverse proxy, so that seems like a good place to start our investigation.

![proxy_arch.mmd.png](../assets/proxy_arch.mmd.png)

# Ingest vs. query-time parsing

We will also be pivoting back and forth between query-time parsing using [ES|QL](https://www.elastic.co/docs/explore-analyze/query-filter/languages/esql) and ingest-time parsing using [Streams](https://www.elastic.co/docs/solutions/observability/logs/streams/streams). ES|QL lets us quickly test theories and look for possible tells in our log data. Once we've determined value in parsing our logs using ES|QL at query-time, we can shift that parsing to ingest-time using Streams. As we will see in this lab, ingest-time parsing allows for more advanced and complex parsing. Moving parsing to ingest-time also facilitates much faster query-time searches. Regardless of where the parsing is done, we will leverage ES|QL to perform aggregations, analysis, and visualization.

![1_arch.mmd.png](../assets/1_arch.mmd.png)

# Getting started

We will start our investigation using ES|QL to interrogate our nginx reverse proxy logs. You can enter your queries in the pane at the top of the Elasticsearch tab. Set the time field to the last hour, then click "Refresh" to load the results.

![1_discover.png](../assets/1_discover.png)

# Finding the errors

Let's have a look at the logs coming from our nginx reverse proxy.

Execute the following query:
```esql
FROM logs-proxy.otel-default
```

We can see that there are still transactions occurring, but we don't know if they are successful or failing. Before we spend time parsing our logs, let's just quickly search for common HTTP "500" errors in our nginx logs.

Execute the following query:
```esql
FROM logs-proxy.otel-default
| WHERE body.text LIKE "* 500 *" // look for messages containing " 500 " in the body
```

If we didn't find "500", we could of course add additional `LIKE` criteria to our `WHERE` clause, like `WHERE body.text LIKE "* 500 *" OR body.text LIKE "* 404 *"`. We will do a better job of handling more types of errors once we start parsing our logs. For now, though, we got lucky: indeed, we are clearly returning 500 errors for some users.

# Is it affecting everyone?

The next thing we quickly want to understand is what percentage of users are experiencing 500 errors?

Execute the following query:
```esql
FROM logs-proxy.otel-default
| EVAL status = CASE(body.text LIKE "* 500 *", "bad", "good") // label messages containing " 500 " as "bad", else "good"
| STATS count = COUNT() BY status // count good and bad
```

Let's visualize this as a pie graph to make it a little easier to understand.

![1_pie.png](../assets/1_pie.png)

1. Click on the pencil icon to the right of the existing graph
2. Select `Pie` from the visualizations drop-down menu
3. Click `Apply and close`

This error appears to only be affecting a small percentage of our overall API queries.

Let's also confirm that we are still seeing a mix of 500 and 200 errors (e.g., the problem wasn't transitory and somehow fixed itself).

Execute the following query:
```esql
FROM logs-proxy.otel-default
| EVAL status = CASE(body.text LIKE "* 500 *", "bad", "good") // label messages containing " 500 " as "bad", else "good"
| STATS COUNT() BY minute = BUCKET(@timestamp, "1 min"), status
```

Then change the resulting graph to a bar graph over time:

1. Click on the pencil icon to the right of the existing graph
2. Select `Bar` from the visualizations drop-down menu
3. Click `Apply and close`

Indeed, we are still seeing a mix of 500 and 200 errors.

# When did it start?

Let's see if we can find when the errors started occurring. Adjust the time field to show the last 2 hours of data.

![1_time_field.png](../assets/1_time_field.png)

Execute the following query:
```esql
FROM logs-proxy.otel-default
| EVAL status = CASE(body.text LIKE "* 500 *", "bad", "good") // label messages containing " 500 " as "bad", else "good"
| STATS COUNT() BY minute = BUCKET(@timestamp, "1 min"), status
```

Ok, it looks like this issue first started happening around 80 minutes ago. We can use `CHANGE_POINT` to narrow it down to a specific minute:

Execute the following query:
```esql
FROM logs-proxy.otel-default
| EVAL status = CASE(body.text LIKE "* 500 *", "bad", "good") // label messages containing " 500 " as "bad", else "good"
| STATS count = COUNT() BY minute = BUCKET(@timestamp, "1 min"), status
| CHANGE_POINT count ON minute AS type, pval // look for distribution change
| WHERE type IS NOT NULL
| KEEP type, minute
```

Let's take stock of what we know:

* a small percentage of users are experiencing 500 errors
* the errors started occurring around 80 minutes ago

# Parsing with ES|QL

As you can see, simply searching for known error codes in our log lines will only get us so far. Maybe the error codes vary, maybe we want to analyze status code vs. request URL.

Fortunately, nginx logs are semi-structured which makes them (relatively) easy to parse.

Some of you may be familiar with GROK expressions which provides a higher-level interface on top of regex; namely, GROK allows you define patterns. If you are well versed in GROK, you may be able to write a parsing pattern yourself for nginx logs, possibly using tools like [GROK Debugger](https://grokdebugger.com) to help.

If you aren't well versed in GROK expressions, or you don't want to spend the time to debug an expression yourself, you can leverage our AI Assistant to help! Click on the AI Assistant button in the upper-right and enter the following prompt:

```
can you write an ES|QL query to parse these nginx log lines?
```

> [!NOTE]
> The output should look something like the following. Notably, the AI Assistant may generate slightly different field names on each generating. Because we rely on those field names in subsequent analysis, please close the flyout and copy and paste the following ES|QL expression into the ES|QL query entry box.

```esql
FROM logs-proxy.otel-default
| GROK body.text "%{IPORHOST:client_ip} %{USER:ident} %{USER:auth} \\[%{HTTPDATE:timestamp}\\] \"%{WORD:http_method} %{NOTSPACE:request_path} HTTP/%{NUMBER:http_version}\" %{NUMBER:status_code} %{NUMBER:body_bytes_sent:int} \"%{DATA:referrer}\" \"%{DATA:user_agent}\""
| WHERE status_code IS NOT NULL
| EVAL @timestamp = DATE_PARSE("dd/MMM/yyyy:HH:mm:ss Z", timestamp)
| KEEP @timestamp, client_ip, http_method, request_path, status_code, user_agent
```

# Is this affecting all APIs?

Let's make use of these parsed fields to break down `status_code` by `request_path` to see if this is affecting only a specific API?

Execute the following query:
```esql
FROM logs-proxy.otel-default
| GROK body.text "%{IPORHOST:client_ip} %{USER:ident} %{USER:auth} \\[%{HTTPDATE:timestamp}\\] \"%{WORD:http_method} %{NOTSPACE:request_path} HTTP/%{NUMBER:http_version}\" %{NUMBER:status_code} %{NUMBER:body_bytes_sent:int} \"%{DATA:referrer}\" \"%{DATA:user_agent}\""
| WHERE status_code IS NOT NULL
| STATS COUNT() BY status_code, request_path
```

Ok, it seems these errors are affecting all of our APIs.

> [!NOTE]
> You'll note that our search has gotten a little slower when we added query-time GROK parsing. In our next challenge, we will show you how we can retain fast-search over long time windows WITH parsing using ingest-time parsing.

# Is this affecting all User Agents?

Ideally, we could also cross-reference the errors against the `user_agent` field to understand if it is affecting all browsers.

Execute the following query:
```esql
FROM logs-proxy.otel-default
| GROK body.text "%{IPORHOST:client_ip} %{USER:ident} %{USER:auth} \\[%{HTTPDATE:timestamp}\\] \"%{WORD:http_method} %{NOTSPACE:request_path} HTTP/%{NUMBER:http_version}\" %{NUMBER:status_code} %{NUMBER:body_bytes_sent:int} \"%{DATA:referrer}\" \"%{DATA:user_agent}\""
| WHERE status_code IS NOT NULL
| WHERE TO_INT(status_code) == 500
| STATS bad = COUNT() BY user_agent
```

Unfortunately, the unparsed `user_agent` field is too unstructured to really be useful for this kind of analysis. We could try to write a GROK expression to further parse `user_agent`, but in practice, it is too complicated (it requires translations and lookups in addition to parsing). Let's put a pin in this topic and revisit it in a bit when we have more tools at our disposal.

# A better way to query

Let's redraw the time graph we drew before, but this time using `status_code` instead of looking for specific error codes.

Execute the following query:
```esql
FROM logs-proxy.otel-default
| GROK body.text "%{IPORHOST:client_ip} %{USER:ident} %{USER:auth} \\[%{HTTPDATE:timestamp}\\] \"%{WORD:http_method} %{NOTSPACE:request_path} HTTP/%{NUMBER:http_version}\" %{NUMBER:status_code} %{NUMBER:body_bytes_sent:int} \"%{DATA:referrer}\" \"%{DATA:user_agent}\""
| WHERE status_code IS NOT NULL
| EVAL @timestamp = DATE_PARSE("dd/MMM/yyyy:HH:mm:ss Z", timestamp) // use embedded timestamp as record timestamp
| STATS status = COUNT() BY status_code, minute = BUCKET(@timestamp, "1 min")
```

> [!NOTE]
> If the resulting graph does not default to a bar graph plotted over time, click on the Pencil icon in the upper-right of the graph and change the graph type to `Bar`

This is a useful graph, and you can clearly see the advantage of parsing the log line vs. simply searching for specific error codes. Here, we can just generally graph by `status_code` and additionally split the data by, say, `request_path`.

Let's save this graph to a Dashboard for future use.

![1_save.png](../assets/1_save.png)

1. Click on the Disk icon in the upper-left of the resulting graph
2. Name the visualization
  ```
  Status Code Over Time (ESQL)
  ```
3. Select `New` under `Add to dashboard`
4. Click `Save and go to Dashboard`
5. Once the new dashboard has loaded, click the `Save` button in the upper-right
6. Enter the title of the new dashboard as
  ```
  Ingress Proxy
  ```
7. Click `Save`

![1_dashboard.png](../assets/1_dashboard.png)

# Setting up a simple alert

Navigate back to `Discover` using the left-hand navigation pane.

Let's create a simple alert to notify us whenever a `status_code` >= 400 is received:

Execute the following query:
```esql
FROM logs-proxy.otel-default
| GROK body.text "%{IPORHOST:client_ip} %{USER:ident} %{USER:auth} \\[%{HTTPDATE:timestamp}\\] \"%{WORD:http_method} %{NOTSPACE:request_path} HTTP/%{NUMBER:http_version}\" %{NUMBER:status_code:int} %{NUMBER:body_bytes_sent:int} \"%{DATA:referrer}\" \"%{DATA:user_agent}\""
| WHERE status_code >= 400
```

![1_alert.png](../assets/1_alert.png)

1. Click `Alerts` in the taskbar
2. Select `Create search threshold rule`
3. Click `Test query`
4. Leave the defaults and click `Next`
5. Click `Next` on `Actions` tab
6. Set `Rule name` to
  ```
  status_code >= 400
  ```
7. Set `Tags` to
  ```
  ingress
  ```
8. Click `Create rule` on `Details` tab

In practice, this alert is too simple. We probably are okay with a small percentage of non-200 errors for any large scale infrastructure. What we really want is to alert when we violate a SLO. We will come back to this in a bit.

# Summary

Let's take stock of what we know:

* a small percentage of users are experiencing 500 errors
* the errors started occurring around 80 minutes ago
* the only error type seen is 500
* the errors occur over all APIs

And what we've done:

* Created a Dashboard showing ingress status
* Created a simple alert to let us know if we ever return non-200 error codes

