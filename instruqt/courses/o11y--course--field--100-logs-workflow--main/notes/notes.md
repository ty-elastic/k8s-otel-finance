# mappings


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

FROM logs-* | WHERE service.name == "proxy" AND parsed.user_agent.os.version IS NOT NULL | LIMIT 100000 | EVAL version = TO_INTEGER(parsed.user_agent.os.version) | STATS mversion = MAX(version) BY parsed.user_agent.os.name, second = BUCKET(@timestamp, 1 second) | CHANGE_POINT mversion ON second | WHERE type IS NOT NULL


FROM logs-* | WHERE service.name == "proxy" AND parsed.user_agent.os.version IS NOT NULL | LIMIT 100000 | EVAL version = TO_INTEGER(parsed.user_agent.os.version) | STATS mversion = MAX(version) BY parsed.user_agent.os.name, second = BUCKET(@timestamp, 15 second)
| WHERE `parsed.user_agent.os.name`=="Android" | CHANGE_POINT mversion ON second | WHERE type IS NOT NULL | KEEP type, second, mversion, parsed.user_agent.os.name | EVAL prompt = CONCAT(
   "When did this version of the OS come out: \n",
   "OS: ", parsed.user_agent.os.name, "\n",
   "Version: ", TO_STRING(mversion), "\n"
  ) | COMPLETION summary = prompt WITH underbar_test


PUT /_inference/completion/underbar_test_new
  {
    "service": "openai",
 "service_settings": {
   "model_id": "gpt-4.1",
   "api_key": "sk-UCM_uJmwt1VRW2PMEoqnVQ",
   "url": "https://litellm-proxy-service-1059491012611.us-central1.run.app/v1/chat/completions"
 }

  FROM logs-* | WHERE service.name == "proxy" AND parsed.user_agent.os.version IS NOT NULL | LIMIT 100000 | EVAL version = TO_INTEGER(parsed.user_agent.os.version) | STATS mversion = MAX(version) BY parsed.user_agent.os.name, second = BUCKET(@timestamp, 15 second)
| WHERE `parsed.user_agent.os.name`=="Android" | CHANGE_POINT mversion ON second | WHERE type IS NOT NULL | KEEP type, second, mversion, parsed.user_agent.os.name | EVAL prompt = CONCAT(
   "When did this version of the OS come out? Format as a date:\n",
   "OS: ", parsed.user_agent.os.name, "\n",
   "Version: ", TO_STRING(mversion) 
  ) | COMPLETION summary = prompt WITH underbar_test_new

# ENRICH

```
FROM logs-* | WHERE service.name == "proxy" | ENRICH networks-policy ON remote_ip WITH isp | RENAME attributes.isp = isp | WHERE attributes.isp IS NOT NULL
```

```

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
```

# pipelines

```
%{IPV4:attributes.remote_ip} - %{DATA:user_name} \[%{HTTPDATE:time}\] \"%{WORD:method} %{DATA:url} HTTP/%{NUMBER:http_version}\" %{NUMBER:attributes.response_code} %{NUMBER:body_sent_bytes} \"%{DATA:referrer}\" \"%{DATA:attributes.agent}\"```

```

# assistant

first, query logs from the proxy service for records where attributes.response_code is not equal to "200" and record the resulting values of the attributes.remote_ip field. then, for the first 5 attribute.remote_ip values found, query logs from the trader service for records where an exception field contains the attribute.remote_ip and give me aha list of the matching exception fields

# esql

FROM logs-generic.otel-default |
WHERE service.name == "proxy" |
GROK message "%{IPV4:clientip} %{NOTSPACE:httprequestreferreroriginal} %{NOTSPACE:username} \\[%{HTTPDATE:timestamp}\\] \"%{WORD:httprequestmethod} %{URIPATHPARAM:urloriginal} HTTP/%{NUMBER:httpversion}\" %{NUMBER:httpresponsestatus_code:int} %{NUMBER:httpresponsebodybytes:int} \"%{DATA:httprequestreferreroriginal2}\" \"%{DATA:user_agentoriginal}\" \"%{DATA:httprequestid}\"" | WHERE httpresponsestatus_code == 200 | KEEP @timestamp, httpresponsestatus_code

FROM logs-generic.otel-default |
WHERE service.name == "proxy" |
GROK message "%{IPV4:remote_ip} - %{DATA:user_name} \\[%{HTTPDATE:time}\\] \"%{WORD:method} %{DATA:url} HTTP/%{NUMBER:http_version}\" %{NUMBER:response_code:int} %{NUMBER:body_sent_bytes} \"%{DATA:referrer}\" \"%{DATA:agent}\"" | WHERE response_code != 200 | KEEP @timestamp, response_code, agent, remote_ip

