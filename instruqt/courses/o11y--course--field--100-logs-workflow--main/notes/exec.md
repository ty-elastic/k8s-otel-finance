# STEP 1 - ESQL

* in discover

## ES|QL

FROM logs-*
| WHERE service.name == "proxy"

FROM logs-*
| WHERE service.name == "proxy" AND MATCH(body.text, "500")

FROM logs-*
| WHERE service.name == "proxy" AND MATCH(body.text, "500")
| KEEP body.text, @timestamp
| STATS COUNT() BY minute = BUCKET(@timestamp, "1 min")

### Generate GROK

* expand log line
* ai assistant
* can you help me generate ESQL to parse this nginx access log?

```
FROM logs-*
| WHERE service.name == "proxy"
| GROK message "%{IPORHOST:client_ip} %{USER:ident} %{USER:auth} \\[%{HTTPDATE:timestamp}\\] \"%{WORD:http_method} %{NOTSPACE:request_path} HTTP/%{NUMBER:http_version}\" %{NUMBER:status_code} %{NUMBER:body_bytes_sent:int} \"%{DATA:referrer}\" \"%{DATA:user_agent}\""
| EVAL timestamp = DATE_PARSE("dd/MMM/yyyy:HH:mm:ss Z", timestamp)
| WHERE status_code IS NOT NULL
| SORT @timestamp DESC
| LIMIT 100
```

### Draw picture of result code

FROM logs-*
| WHERE service.name == "proxy"
| GROK message "%{IPORHOST:client_ip} %{USER:ident} %{USER:auth} \\[%{HTTPDATE:timestamp}\\] \"%{WORD:http_method} %{NOTSPACE:request_path} HTTP/%{NUMBER:http_version}\" %{NUMBER:status_code} %{NUMBER:body_bytes_sent:int} \"%{DATA:referrer}\" \"%{DATA:user_agent}\""
| WHERE status_code IS NOT NULL
| EVAL timestamp = DATE_PARSE("dd/MMM/yyyy:HH:mm:ss Z", timestamp)
| STATS status = COUNT() BY status_code, minute = BUCKET(timestamp, "1 min")

- this graph is useful. add to dashboard
- save this query

## Alerts

FROM logs-*
| WHERE service.name == "proxy"
| GROK message "%{IPORHOST:client_ip} %{USER:ident} %{USER:auth} \\[%{HTTPDATE:timestamp}\\] \"%{WORD:http_method} %{NOTSPACE:request_path} HTTP/%{NUMBER:http_version}\" %{NUMBER:status_code} %{NUMBER:body_bytes_sent:int} \"%{DATA:referrer}\" \"%{DATA:user_agent}\""
| WHERE status_code != "200"

- cancel

# STEP 2 - Streams

* in streams

Look only at proxy logs

service.name: "proxy" and attributes.log.iostream :"stdout"

## GROK

Generate pattern

Field: `body.text`
Grok patterns:
```
%{IPV4:parsed.client.ip} - %{NOTSPACE:parsed.http.request.auth.user} \[%{HTTPDATE:parsed.timestamp}\] "%{WORD:parsed.http.request.method} %{NOTSPACE:parsed.url.path} HTTP/%{NUMBER:parsed.http.version}" %{NONNEGINT:parsed.http.response.status_code:int} %{NONNEGINT:parsed.http.response.body.bytes:int} "%{DATA:parsed.http.request.referrer}" "%{GREEDYDATA:parsed.user_agent.original}"
```

## DATE

Field: parsed.timestamp
Format: `dd/MMM/yyyy:HH:mm:ss XX`

## GEOIP

Field: `parsed.client.ip`
Target Field: `parsed.geo`
Ignore Missing

# ES|QL

FROM logs-*
| WHERE service.name == "proxy"
| STATS COUNT() BY TO_STRING(parsed.http.response.status_code), minute = BUCKET(@timestamp, "1 min")

- this graph is useful. add to dashboard

FROM logs-*
| WHERE parsed.http.response.status_code == 500
| STATS COUNT() BY parsed.geo.country_iso_code

and we can get really fancy and lookup

FROM logs-*
| WHERE parsed.http.response.status_code == 500
| ENRICH networks-policy ON parsed.client.ip 
| STATS COUNT() BY parsed.geo.country_iso_code, isp

could add to dashboard, but lets make a map

# Maps

Layer Style

Fill Color

By Value `parsed.http.response.status_code`
200
500

this graph is useful. add to dashboard

# by user agent

FROM logs-*
| WHERE parsed.user_agent.original IS NOT NULL AND parsed.http.response.status_code IS NOT NULL
| STATS good = COUNT(parsed.http.response.status_code == 200 OR NULL), bad=COUNT(parsed.http.response.status_code == 500 OR NULL) BY parsed.user_agent.original


## USER_AGENT

Field: `parsed.user_agent.original`
Target: `parsed.user_agent`
Ignore Missing


# correlation

FROM logs-*
| WHERE service.name == "proxy" AND parsed.user_agent.original IS NOT NULL
| STATS good = COUNT(parsed.http.response.status_code == 200 OR NULL), bad = COUNT(parsed.http.response.status_code == 500 OR NULL) BY parsed.user_agent.version


FROM logs-*
| WHERE parsed.user_agent.original IS NOT NULL AND parsed.http.response.status_code IS NOT NULL
| STATS COUNT() BY parsed.user_agent.version, parsed.geo.country_iso_code


FROM logs-*
| WHERE service.name == "proxy" AND parsed.user_agent.original IS NOT NULL
| WHERE (parsed.http.response.status_code == 500)
| SAMPLE 0.05
| LIMIT 10
| EVAL prompt = CONCAT(
   "when did this version of this browser come out? output only a version of the format mm/dd/yyyy",
   "browser: ", parsed.user_agent.name,
   "version: ", parsed.user_agent.version
  ) | COMPLETION release_date = prompt WITH openai_completion | KEEP release_date, parsed.user_agent.name, parsed.user_agent.version


# Create SLO

query= parsed.http.response.status_code >= 400
good=parsed.http.response.status_code : 200
total=parsed.http.response.status_code :*
groupby: parsed.url.path

Create New ALert Rule

- talk about burn rates

# Create Ml to look for new UAs

multi-metric

distinct_count("parsed.user_agent.version")

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