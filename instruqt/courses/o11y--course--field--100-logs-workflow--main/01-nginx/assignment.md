---
slug: nginx
id: bghh0aks5bvy
type: challenge
title: Making sense of nginx logs
tabs:
- id: yofmaqrbv6qc
  title: Elasticsearch
  type: service
  hostname: kubernetes-vm
  path: /app/discover#/?_g=(filters:!(),refreshInterval:(pause:!t,value:60000),time:(from:now-1h,to:now))&_a=(breakdownField:log.level,columns:!(),dataSource:(type:esql),filters:!(),hideChart:!f,interval:auto,query:(esql:'FROM%20logs-proxy.otel-default'),sort:!(!('@timestamp',desc)))
  port: 30001
- id: lc4tpizxrz5g
  title: Terminal
  type: terminal
  hostname: kubernetes-vm
difficulty: basic
timelimit: 600
enhanced_loading: null
---
In this lab, we will work through a practical log workflow with modern Elasticsearch.

Getting Our Bearings
===

In this lab, we will be working with an exemplary stock trading system, instrumented using [OpenTelemetry](https://opentelemetry.io). The "front door" to our backend services is a nginx reverse proxy.

We've gotten word from our customer service department that some users are getting errors when trying to access our website. Since we know that all requests go through our nginx reverse proxy, that's a good place to start our investigation.

ES|QL
===

1. Open the [button label="Elasticsearch"](tab-0) tab

Here we have the most basic of ES|QL queries looking at our proxy logs:
```esql
FROM logs-proxy.otel-default
```

Let's first check for errors:
```esql
FROM logs-proxy.otel-default
| WHERE service.name == "proxy" AND MATCH(body.text, "500")
```

Yup! there are some 500 errors... but what percentage is failing?

```esql
FROM logs-proxy.otel-default
| FORK (WHERE MATCH(body.text, "500") | STATS bad=COUNT()) (WHERE MATCH(body.text, "200") | STATS good=COUNT())
| KEEP bad, good
```

and when did they start failing?

```esql
FROM logs-proxy.otel-default
| MATCH(body.text, "500")
| KEEP body.text, @timestamp
| STATS COUNT() BY minute = BUCKET(@timestamp, "1 min")
```


Let's parse

* expand log line
* ai assistant
* can you help me generate ESQL to parse this nginx access log?

```
FROM logs-proxy.otel-default
| GROK message "%{IPORHOST:client_ip} %{USER:ident} %{USER:auth} \\[%{HTTPDATE:timestamp}\\] \"%{WORD:http_method} %{NOTSPACE:request_path} HTTP/%{NUMBER:http_version}\" %{NUMBER:status_code} %{NUMBER:body_bytes_sent:int} \"%{DATA:referrer}\" \"%{DATA:user_agent}\""
| EVAL timestamp = DATE_PARSE("dd/MMM/yyyy:HH:mm:ss Z", timestamp)
| WHERE status_code IS NOT NULL
| SORT @timestamp DESC
| KEEP @timestamp, request_path, status_code
```

and then graph over time!

FROM logs-proxy.otel-default
| GROK message "%{IPORHOST:client_ip} %{USER:ident} %{USER:auth} \\[%{HTTPDATE:timestamp}\\] \"%{WORD:http_method} %{NOTSPACE:request_path} HTTP/%{NUMBER:http_version}\" %{NUMBER:status_code} %{NUMBER:body_bytes_sent:int} \"%{DATA:referrer}\" \"%{DATA:user_agent}\""
| WHERE status_code IS NOT NULL
| EVAL timestamp = DATE_PARSE("dd/MMM/yyyy:HH:mm:ss Z", timestamp)
| STATS status = COUNT() BY status_code, minute = BUCKET(timestamp, "1 min")

- this graph is useful. add to dashboard
- save this query

## Create a simple alert

FROM logs-proxy.otel-default
| GROK message "%{IPORHOST:client_ip} %{USER:ident} %{USER:auth} \\[%{HTTPDATE:timestamp}\\] \"%{WORD:http_method} %{NOTSPACE:request_path} HTTP/%{NUMBER:http_version}\" %{NUMBER:status_code} %{NUMBER:body_bytes_sent:int} \"%{DATA:referrer}\" \"%{DATA:user_agent}\""
| WHERE status_code != "200"

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

### Dashboards

- show scheduled export in PDF

### show redaction

- custom role



-----------------------------------




##### CUSTOM LOGS

FROM logs-* | WHERE service.name == "trader" | GROK message "current market share price for %{WORD:stock}: \\$%{NUMBER:price}" | WHERE stock IS NOT NULL | STATS AVG(TO_INT(price)) BY stock, minute = BUCKET(@timestamp, "1 min")

## Streams

current market share price for %{WORD:parsed.stock_symbol}: \$%{NUMBER:parsed.stock_price:float}

cond:
body.text contains current market share price

## Lens
Lens

## ML from Lens

# show redaction of fields