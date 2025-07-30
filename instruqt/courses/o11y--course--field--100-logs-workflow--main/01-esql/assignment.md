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
- id: sw6mcyxmqgcv
  title: Elasticsearch
  type: service
  hostname: kubernetes-vm
  path: /app/discover#/?_g=(filters:!(),query:(language:kuery,query:''),refreshInterval:(pause:!t,value:60000),time:(from:now-1h,to:now))&_a=(breakdownField:log.level,columns:!(),dataSource:(type:esql),filters:!(),hideChart:!f,interval:auto,query:(esql:'FROM%20logs-proxy.otel-default'),sort:!(!('@timestamp',desc)))
  port: 30001
- id: 2vem8q5ukov7
  title: Terminal
  type: terminal
  hostname: kubernetes-vm
difficulty: basic
timelimit: 600
enhanced_loading: false
---
We've gotten word from our customer service department that some users are unable to complete stock trades. We know that all of the API calls from our front end web application flow through a nginx reverse proxy, so that seems like a good place to start our investigation.

If you are generally familiar with SQL or other piped query languages, you will be right at home with ES|QL, Elastic's modern take on a piped query language.

You can enter your queries in the pane at the top of the Elasticsearch tab. Set the time range to the last hour, then click "Refresh" to load the results.

Let's have a look at the logs coming from our nginx reverse proxy.

Execute the following query:
```esql
FROM logs-proxy.otel-default
```

We can see that there are still transactions happening, but we don't know if they are successful or failing. Before we spend time parsing our logs, let's just quickly check for common "500" errors in our nginx logs.

Execute the following query:
```esql
FROM logs-proxy.otel-default
| WHERE MATCH(body.text, "500")
```

A-ha! We are clearly returning 500 errors for some users. The next thing we quickly want to understand is what percentage of users are experiencing 500 errors.

Execute the following query:
```esql
FROM logs-proxy.otel-default
| STATS bad=COUNT() WHERE MATCH(body.text, "500"), good=COUNT() WHERE MATCH(body.text, "200") BY minute = BUCKET(@timestamp, "1 min")
```

That's good. Clearly this issue is affecting only some users. Let's see if we can find when the errors started occurring. Adjust the time picker to show the last 2 hours of data.

Execute the following query:
```esql
FROM logs-proxy.otel-default
| STATS bad=COUNT() WHERE MATCH(body.text, "500"), good=COUNT() WHERE MATCH(body.text, "200") BY minute = BUCKET(@timestamp, "1 min")
```

Ok, it looks like this issue first started happening around 80 minutes ago. We can use `CHANGE_POINT` to narrow it down to a specific minute:

Execute the following query:
```esql
FROM logs-proxy.otel-default
| STATS bad=COUNT() WHERE MATCH(body.text, "500"), good=COUNT() WHERE MATCH(body.text, "200") BY minute = BUCKET(@timestamp, "1 min")
| EVAL bad = COALESCE(TO_INT(bad), 0)
| SORT minute ASC
| CHANGE_POINT bad ON minute
| WHERE type IS NOT NULL
| KEEP type, minute, bad
```

Let's take stock of what we know:
* a small percentage of users are experiencing 500 errors
* the errors started occurring around 80 minutes ago

# Parsing with ES|QL

As you can see, simply searching for known error codes in our log lines will only get us so far. Maybe the error codes vary, or aren't specifically 500, but rather something in the 400 range?

Fortunately, nginx logs are semi-structure which makes them (relatively) easy to parse.

Some of you may be familiar with GROK expressions which provides a higher-level interface on top of regex; namely, GROK allows you define patterns. If you are well versed in GROK, you may be able to write a parsing pattern yourself for nginx logs, possibly using https://grokdebugger.com to help.

If you aren't well versed, or you don't want to spend the time, you can leverage our AI Assistant to help! Click on the AI Assistant button in the upper-right and enter the following prompt:

```
can you write an ES|QL query to parse these nginx log lines?
```

copy the output from the AI assistant flyout by clicking on the clipboard icon in the response. The output should look something like the following.

```esql
FROM logs-proxy.otel-default
| GROK message "%{IPORHOST:client_ip} %{USER:ident} %{USER:auth} \\[%{HTTPDATE:timestamp}\\] \"%{WORD:http_method} %{NOTSPACE:request_path} HTTP/%{NUMBER:http_version}\" %{NUMBER:status_code} %{NUMBER:body_bytes_sent:int} \"%{DATA:referrer}\" \"%{DATA:user_agent}\""
| KEEP timestamp, client_ip, http_method, request_path, status_code, user_agent
```

Now close the flyout and execute the generated ES|QL. If you don't see the parsed fields in the result, use the exemplary ES|QL shown above and re-run the query.

Let's make use of these parsed fields to break down status_code by request_path to see if this is affecting only a specific API?

Execute the following query:
```esql
FROM logs-proxy.otel-default
| GROK message "%{IPORHOST:client_ip} %{USER:ident} %{USER:auth} \\[%{HTTPDATE:timestamp}\\] \"%{WORD:http_method} %{NOTSPACE:request_path} HTTP/%{NUMBER:http_version}\" %{NUMBER:status_code} %{NUMBER:body_bytes_sent:int} \"%{DATA:referrer}\" \"%{DATA:user_agent}\""
| WHERE status_code IS NOT NULL
| EVAL @timestamp = DATE_PARSE("dd/MMM/yyyy:HH:mm:ss Z", timestamp)
| STATS COUNT() BY status_code, request_path
```

Ok, it seems these errors are affecting all of our APIs. Ideally, we could also cross-reference against the `user_agent` field.

Execute the following query:
```esql
FROM logs-proxy.otel-default
| GROK message "%{IPORHOST:client_ip} %{USER:ident} %{USER:auth} \\[%{HTTPDATE:timestamp}\\] \"%{WORD:http_method} %{NOTSPACE:request_path} HTTP/%{NUMBER:http_version}\" %{NUMBER:status_code} %{NUMBER:body_bytes_sent:int} \"%{DATA:referrer}\" \"%{DATA:user_agent}\""
| WHERE status_code IS NOT NULL
| EVAL @timestamp = DATE_PARSE("dd/MMM/yyyy:HH:mm:ss Z", timestamp)
| WHERE TO_INT(status_code) == 500
| STATS bad = COUNT() BY user_agent
```

Unfortunately, the unparsed user_agent field is too noisy to really be useful for this kind of analysis. We could try to write a GROK expression to parse `user_agent`, but in practice, it is too complicated (it requires translation in addition to parsing). Let's put a pin in this topic and revisit it in a bit.

Let's redraw the time graph we drew before, but this time using status_code instead of looking for specific error codes.

Execute the following query:
```esql
FROM logs-proxy.otel-default
| GROK message "%{IPORHOST:client_ip} %{USER:ident} %{USER:auth} \\[%{HTTPDATE:timestamp}\\] \"%{WORD:http_method} %{NOTSPACE:request_path} HTTP/%{NUMBER:http_version}\" %{NUMBER:status_code} %{NUMBER:body_bytes_sent:int} \"%{DATA:referrer}\" \"%{DATA:user_agent}\""
| WHERE status_code IS NOT NULL
| EVAL timestamp = DATE_PARSE("dd/MMM/yyyy:HH:mm:ss Z", timestamp)
| STATS status = COUNT() BY status_code, minute = BUCKET(timestamp, "1 min")
```

This is a useful graph, and you can clearly see the advantage of parsing the log line vs. simply searching for specific error codes. Here, we can just generally graph by `status_code`, and additionally split the data by, say, `request_path`.

This is a useful graph! Let's save it to a Dashboard for future use.

1. Click on the Disk icon in the upper-left of the resulting graph
2. Add to a new dashboard
3. Save the new dashboard as `Ingress Proxy`

Let's take stock of what we know:
* a small percentage of users are experiencing 500 errors
* the errors started occurring around 80 minutes ago
* the only error type seen is 500
* the errors occur over all APIs

# Create a simple alert

We could at this point create a simple alert to notify us whenever a status_code other than 200 is received.

Execute the following query:
```esql
FROM logs-proxy.otel-default
| GROK message "%{IPORHOST:client_ip} %{USER:ident} %{USER:auth} \\[%{HTTPDATE:timestamp}\\] \"%{WORD:http_method} %{NOTSPACE:request_path} HTTP/%{NUMBER:http_version}\" %{NUMBER:status_code} %{NUMBER:body_bytes_sent:int} \"%{DATA:referrer}\" \"%{DATA:user_agent}\""
| WHERE status_code != "200"
```

1. Click Alerts in the taskbar
2. Select `Create search threshold rule`
3. Click `Test query`
4. Leave the defaults and click `Next`
5. Click `Next` on `Actions` tab
6. Click `Create rule` on `Details` tab

In practice, this alert is too simple. We probably are okay with a small percentage of non-200 errors for any large scale infrastructure. What we really want is to alert when we violate a SLO. We will come back to this in a bit.

# Summary

Let's take stock of what we know:
* a small percentage of users are experiencing 500 errors
* the errors started occurring around 80 minutes ago
* the only error type seen is 500
* the errors occur over all APIs

And what we've done:
* Created a Dashboard showing status code over time
* Created a simple alert to let us know if we ever return non-200 error codes

In the next challenge, we will leverage Elastic Streams to parse our data on ingest, allowing us to do more with the data.

