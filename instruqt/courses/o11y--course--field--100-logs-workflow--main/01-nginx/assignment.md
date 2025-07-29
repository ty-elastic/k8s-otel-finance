---
slug: nginx
id: 5jclgckaczpm
type: challenge
title: Making sense of nginx logs
notes:
- type: text
  contents: |-
    You are an on-call SRE for a company which operates an online stock trading service. You were just notified that some users are experiencing issues when trying to perform stock trades.

    In the lab, we will leverage Elastic's comprehensive suite of modern log analytic tools to unlock the hidden information in your logs that will enable you to quickly perform Root Cause Analysis (RCA) of the problem. We will also create alerts to ensure this problem doesn't happen again.
tabs:
- id: sw6mcyxmqgcv
  title: Elasticsearch
  type: service
  hostname: kubernetes-vm
  path: /app/discover#/?_g=(filters:!(),refreshInterval:(pause:!t,value:60000),time:(from:now-1h,to:now))&_a=(breakdownField:log.level,columns:!(),dataSource:(type:esql),filters:!(),hideChart:!f,interval:auto,query:(esql:'FROM%20logs-proxy.otel-default'),sort:!(!('@timestamp',desc)))
  port: 30001
- id: 2vem8q5ukov7
  title: Terminal
  type: terminal
  hostname: kubernetes-vm
difficulty: basic
timelimit: 600
enhanced_loading: false
---

We've gotten word from our customer service department that some users are unable to complete stock trades. We know that all of the API calls from our front-end web application flow through a nginx reverse proxy, so that seems like a good place to start our investigation.

If you are generally familiar with SQL or other piped query languages, you will be right at home with ES|QL, Elastic's modern take on a piped query language.

You can enter your queries in the pane at the top of the window on the left. Select an appropriate time frame (currently the last hour), then click "Refresh" to load the results.

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

Yup! We are clearly returning 500 errors for some users. Are all transactions failing?

Execute the following query:
```esql
FROM logs-proxy.otel-default
| STATS bad=COUNT() WHERE MATCH(body.text, "500"), good=COUNT() WHERE MATCH(body.text, "200") BY minute = BUCKET(@timestamp, "1 min")
```

That's good. Clearly this is affecting only some users. Let's see if we can find when the errors started occurring. Let's zoom out the time picker to, say, the last 24 hours.

Execute the following query:
```esql
FROM logs-proxy.otel-default
| STATS bad=COUNT() WHERE MATCH(body.text, "500"), good=COUNT() WHERE MATCH(body.text, "200") BY minute = BUCKET(@timestamp, "1 min")
```

Ok, it looks like this started happening around 6 hours ago. We can use `CHANGE_POINT` to narrow it down to a specific minute:

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

# Parsing with ES|QL

As you can see, simply searching for known error codes in our log lines will only get us so far. Maybe the error codes vary, or aren't "500", but rather something in the 400 range.

Fortunately, nginx logs are semi-structured log lines which makes them (relatively) easy to parse.

Some of you may be familiar with GROK which provides a higher-level interface on top of regex; namely, it allows you define patterns. If you are well versed in GROK, you may be able to write a parsing pattern yourself for nginx logs, possibly using https://grokdebugger.com to help.

If you aren't so well versed, or you don't want to spend the time, you can leverage our AI Assistant to help. Click on the AI Assistant button in the upper-right and enter the following prompt:

```
can you help me generate ESQL to parse this nginx access log?
```

now we can copy the GROK expression and add some useful directives to reproduce the graph we made above, but better:
```esql
FROM logs-proxy.otel-default
| GROK message "%{IPORHOST:client_ip} %{USER:ident} %{USER:auth} \\[%{HTTPDATE:timestamp}\\] \"%{WORD:http_method} %{NOTSPACE:request_path} HTTP/%{NUMBER:http_version}\" %{NUMBER:status_code} %{NUMBER:body_bytes_sent:int} \"%{DATA:referrer}\" \"%{DATA:user_agent}\""
| WHERE status_code IS NOT NULL
| EVAL @timestamp = DATE_PARSE("dd/MMM/yyyy:HH:mm:ss Z", timestamp)
| SORT @timestamp ASC
| KEEP @timestamp, request_path, status_code
```

This is nice, since we don't have to know the error codes we are looking for. We can also start to split our data around, say, request_path to understand if this problem is perhaps related



Let's parse

* expand log line
* ai assistant
* can you help me generate ESQL to parse this nginx access log?

```
FROM logs-proxy.otel-default
| GROK message "%{IPORHOST:client_ip} %{USER:ident} %{USER:auth} \\[%{HTTPDATE:timestamp}\\] \"%{WORD:http_method} %{NOTSPACE:request_path} HTTP/%{NUMBER:http_version}\" %{NUMBER:status_code} %{NUMBER:body_bytes_sent:int} \"%{DATA:referrer}\" \"%{DATA:user_agent}\""
| WHERE status_code IS NOT NULL
| EVAL @timestamp = DATE_PARSE("dd/MMM/yyyy:HH:mm:ss Z", timestamp)
| SORT @timestamp ASC
| KEEP @timestamp, request_path, status_code
```

and then graph over time!

```esql
FROM logs-proxy.otel-default
| GROK message "%{IPORHOST:client_ip} %{USER:ident} %{USER:auth} \\[%{HTTPDATE:timestamp}\\] \"%{WORD:http_method} %{NOTSPACE:request_path} HTTP/%{NUMBER:http_version}\" %{NUMBER:status_code} %{NUMBER:body_bytes_sent:int} \"%{DATA:referrer}\" \"%{DATA:user_agent}\""
| WHERE status_code IS NOT NULL
| EVAL timestamp = DATE_PARSE("dd/MMM/yyyy:HH:mm:ss Z", timestamp)
| STATS status = COUNT() BY status_code, minute = BUCKET(timestamp, "1 min")
```

- this graph is useful. add to dashboard
- save this query

## Create a simple alert

```esql
FROM logs-proxy.otel-default
| GROK message "%{IPORHOST:client_ip} %{USER:ident} %{USER:auth} \\[%{HTTPDATE:timestamp}\\] \"%{WORD:http_method} %{NOTSPACE:request_path} HTTP/%{NUMBER:http_version}\" %{NUMBER:status_code} %{NUMBER:body_bytes_sent:int} \"%{DATA:referrer}\" \"%{DATA:user_agent}\""
| WHERE status_code != "200"
```

- alerts
- create search theshold rule
- test query
- cancel

Streams
===

* in streams

logs-proxy.otel-default

- Processing

## GROK

-- Add processor

- Generate pattern
- accept

Field: `body.text`
Grok patterns:
```
%{IPV4:parsed.client.ip} - %{NOTSPACE:parsed.http.request.auth.user} \[%{HTTPDATE:parsed.timestamp}\] "%{WORD:parsed.http.request.method} %{NOTSPACE:parsed.url.path} HTTP/%{NUMBER:parsed.http.version}" %{NONNEGINT:parsed.http.response.status_code:int} %{NONNEGINT:parsed.http.response.body.bytes:int} "%{DATA:parsed.http.request.referrer}" "%{GREEDYDATA:parsed.user_agent.original}"
```
- add processor

## DATE

Field: parsed.timestamp
Format: `dd/MMM/yyyy:HH:mm:ss XX`

ES|QL
===

```
FROM logs-proxy.otel-default
| STATS COUNT() BY TO_STRING(parsed.http.response.status_code), minute = BUCKET(@timestamp, "1 min")
```

- this graph is useful. add to dashboard

ah!

Maybe the problem is with the geo?

Streams
===

## GEOIP

Field: `parsed.client.ip`
Target Field: `parsed.geo`
Ignore Missing

ES|QL
===


FROM logs-proxy.otel-default
| WHERE parsed.geo.country_iso_code IS NOT NULL
| STATS COUNT() BY parsed.http.response.status_code, parsed.geo.country_iso_code

- PIE CHART

and we can get really fancy and lookup

FROM logs-proxy.otel-default
| WHERE parsed.http.response.status_code == 500
| ENRICH networks-policy ON parsed.client.ip
| STATS COUNT() BY parsed.geo.country_iso_code, isp

could add to dashboard, but lets make a map

Maps
===

Layer Style

Fill Color

By Value `parsed.http.response.status_code`
200
500

this graph is useful. add to dashboard

# by user agent

FROM logs-proxy.otel-default
| WHERE parsed.http.response.status_code == 500
| STATS bad = COUNT() BY parsed.user_agent.original


Streams
===

Field: `parsed.user_agent.original`
Target: `parsed.user_agent`
Ignore Missing


# correlation

FROM logs-proxy.otel-default
| WHERE parsed.user_agent.original IS NOT NULL
| STATS good = COUNT(parsed.http.response.status_code == 200 OR NULL), bad = COUNT(parsed.http.response.status_code == 500 OR NULL) BY parsed.user_agent.version

seems to be version related...


FROM logs-proxy.otel-default
| WHERE parsed.geo.country_iso_code IS NOT NULL AND parsed.user_agent.version IS NOT NULL AND parsed.http.response.status_code IS NOT NULL
| EVAL version_major = SUBSTRING(parsed.user_agent.version,0,LOCATE(parsed.user_agent.version, ".")-1)
| WHERE TO_INT(version_major) == 136
| STATS COUNT() BY parsed.geo.country_iso_code


FROM logs-proxy.otel-default
| WHERE parsed.user_agent.version IS NOT NULL
| STATS versions = VALUES(CONCAT(parsed.user_agent.name, " ", parsed.user_agent.version))
| EVAL versions = MV_DEDUPE(versions)
| STATS version = MV_SORT(versions) BY versions
| EVAL prompt = CONCAT(
   "when did this version of this browser come out? output only a version of the format mm/dd/yyyy",
   "browser: ", version
  ) | COMPLETION release_date = prompt WITH openai_completion | KEEP release_date, version


# Create SLO

query= parsed.http.response.status_code >= 400
good=parsed.http.response.status_code : 200
total=parsed.http.response.status_code :*
groupby: parsed.url.path

Create New ALert Rule

- talk about burn rates

# Create Ml to look for new UAs

FROM user_agents
| SORT @timestamp.min DESC
| LIMIT 10
| EVAL prompt = CONCAT(
   "when did this version of this browser come out? output only a version of the format mm/dd/yyyy",
   "browser: ", parsed.user_agent.full
  ) | COMPLETION release_date = prompt WITH openai_completion
  | KEEP release_date, parsed.user_agent.full, @timestamp.min, @timestamp.max

multi-metric

distinct_count("parsed.user_agent.version")

{
  "id": "user_agents",
  "authorization": {
    "roles": [
      "superuser"
    ]
  },
  "version": "10.0.0",
  "create_time": 1753492082711,
  "source": {
    "index": [
      "logs-proxy.otel-default"
    ],
    "query": {
      "match_all": {}
    }
  },
  "dest": {
    "index": "user_agents"
  },
  "sync": {
    "time": {
      "field": "@timestamp",
      "delay": "60s"
    }
  },
  "pivot": {
    "group_by": {
      "parsed.user_agent.full": {
        "terms": {
          "field": "parsed.user_agent.full"
        }
      }
    },
    "aggregations": {
      "@timestamp.max": {
        "max": {
          "field": "@timestamp"
        }
      },
      "@timestamp.min": {
        "min": {
          "field": "@timestamp"
        }
      }
    }
  },
  "settings": {}
}

alert on new docs

then table
then add completion!

### Dashboards

- show scheduled export in PDF

### show redaction

RBAC
- custom role



-----------------------------------

