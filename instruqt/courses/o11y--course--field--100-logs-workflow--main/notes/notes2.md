# CLEANUP

POST logs-generic.otel-default/_rollover



# SETUP

## streams

POST kbn:/internal/kibana/settings
{"changes":{"observability:enableStreamsUI":true}}

## ai assistant

POST kbn:/internal/kibana/settings
{"changes":{"aiAssistant:preferredAIAssistantType":"observability"}}

PUT /_inference/completion/openai_completion
{
    "service": "openai",
    "service_settings": {
        "model_id": "gpt-4.1",
        "api_key": "sk-AdHQ6LsuPOpsN_USc14C6w",
        "url": "https://litellm-proxy-service-1059491012611.us-central1.run.app/v1/chat/completions"
    }
}


## mappings

PUT _component_template/logs-otel@custom
{
  "template": {
    "mappings": {

      "properties": {
        
        "parsed": {
          "dynamic": true,
          "type": "object"
        }
      }
    }
  }
}

## enrich

PUT /networks
{
  "mappings": {
    "properties": {
      "range": { "type": "ip_range" },
      "isp": { "type": "keyword" }
    }
  }
}

POST networks/_bulk
{"index":{}}
{"range":"107.80.0.0/16","isp":"AT&T Enterprises, LLC"}
{"index":{}}
{"range":"186.189.224.0/20","isp":"NSS S.A."}
{"index":{}}
{"range":"149.254.212.0/24","isp":"T-Mobile(UK) Internet"}
{"index":{}}
{"range":"95.85.100.0/24","isp":"Turkmentelecom"}
{"index":{}}
{"range":"101.136.0.0/14","isp":"Asia Pacific Telecom"}

PUT /_enrich/policy/networks-policy
{
  "range": {
    "indices": "networks",
    "match_field": "range",
    "enrich_fields": ["isp"]
  }
}

POST /_enrich/policy/networks-policy/_execute?wait_for_completion=false


`curl -X POST http://127.0.0.1:9393/monkey/err/ua/region/APAC`

# ------- ES|QL

## Discover

service.name : "proxy"

## ES|QL

```
FROM logs-*
| WHERE service.name == "proxy"
```

### Generate GROK

Click log line
AI

can you help me generate ESQL to parse this nginx access log?

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
| STATS success = COUNT() BY status_code, minute = BUCKET(timestamp, "1 min")

this graph is useful. add to dashboard

# Streams

Look only at proxy logs

`service.name: "proxy" and attributes.log.iostream :"stdout"`

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

- add saved query

# ES|QL

speed

FROM logs-*
| WHERE service.name == "proxy"
| STATS count = COUNT() BY TO_STRING(parsed.http.response.status_code), minute = BUCKET(@timestamp, "1 min")

this graph is useful. add to dashboard

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
| WHERE parsed.user_agent.original IS NOT NULL
| GROK parsed.user_agent.original "%{DATA:browser_family}/%{NUMBER:browser_version} \\(%{DATA:os_details}\\)"
| STATS count = COUNT() BY TO_STRING(parsed.http.response.status_code), browser_version

FROM logs-*
| WHERE parsed.user_agent.original IS NOT NULL
| GROK parsed.user_agent.original "%{DATA:browser_family}/%{NUMBER:browser_version} \\(%{DATA:os_details}\\)"
| STATS count = COUNT() BY TO_STRING(parsed.http.response.status_code), browser_version, parsed.geo.country_iso_code


## USER_AGENT

Field: `parsed.user_agent.original`
Target: `parsed.user_agent`
Ignore Missing


# correlation

FROM logs-*
| WHERE service.name == "proxy" AND parsed.geo.country_iso_code == "TW" AND parsed.user_agent.original IS NOT NULL
| GROK parsed.user_agent.original "%{DATA:browser_family}/%{NUMBER:browser_version} \\(%{DATA:os_details}\\)"
| STATS bad = COUNT(parsed.http.response.status_code == 500 OR NULL), good = COUNT(parsed.http.response.status_code == 200 OR NULL) BY parsed.user_agent.os.full, minute = BUCKET(@timestamp, "1 min")


FROM logs-*
| WHERE parsed.user_agent.original IS NOT NULL
| GROK parsed.user_agent.original "%{DATA:browser_family}/%{NUMBER:browser_version} \\(%{DATA:os_details}\\)"
| WHERE LOCATE(os_details,"Android") > 0
| SAMPLE 0.05
| LIMIT 10
| KEEP os_details
| EVAL prompt = CONCAT(
   "parse this os string from a user agent string and tell me when this version of the os was released. output only a version of the format mm/dd/yyyy",
   "OS: ", os_details
  ) | COMPLETION release_date = prompt WITH openai_completion | KEEP release_date, os_details

# change point

FROM logs-* | WHERE service.name == "proxy" AND parsed.user_agent.os.name == "Android" | LIMIT 100000 | EVAL version = TO_INTEGER(parsed.user_agent.os.version) | STATS mversion = MAX(version) BY parsed.user_agent.os.name, second = BUCKET(@timestamp, 15 second) | CHANGE_POINT mversion ON second | WHERE type IS NOT NULL | KEEP type, second, mversion, parsed.user_agent.os.name

with lookup to release date

FROM logs-* | WHERE service.name == "proxy" AND parsed.user_agent.os.name == "Android" | LIMIT 100000 | EVAL version = TO_INTEGER(parsed.user_agent.os.version) | STATS mversion = MAX(version) BY parsed.user_agent.os.name, second = BUCKET(@timestamp, 15 second) | CHANGE_POINT mversion ON second | WHERE type IS NOT NULL | KEEP type, second, mversion, parsed.user_agent.os.name | EVAL prompt = CONCAT(
   "When did this version of the OS come out? Output only a date in the format of MM/DD/YYYY\n",
   "OS: ", parsed.user_agent.os.name, "\n",
   "Version: ", TO_STRING(mversion), "\n"
  ) | COMPLETION release_date = prompt WITH openai_completion | KEEP release_date, mversion

# Create SLO

query= parsed.http.response.status_code >= 400
good=parsed.http.response.status_code : 200
total=parsed.http.response.status_code :*
groupby: parsed.url.path

Create New ALert Rule

- talk about burn rates

# Create Ml to look for new UAs

multi-metric

distinct_count("parsed.user_agent.os.full")

### Dashboards

- show scheduled export in PDF


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