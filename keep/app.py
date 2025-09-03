from flask import Flask, request, abort
import logging
import json
import requests
import os
from datetime import datetime, timezone
import re

app = Flask(__name__)
app.logger.setLevel(logging.INFO)

KB_ADDRESS = os.environ['KB_ADDRESS']
ES_ADDRESS = os.environ['ES_ADDRESS']
ES_USER = os.environ['ES_USER']
ES_PASS = os.environ['ES_PASS']
TIMEOUT = 120

def parse_alerts(keep_alerts_string):
    alerts_cleaned_string = keep_alerts_string.replace('AlertDto', 'dict') \
        .replace('context.', 'context_') \
        .replace('rule.', 'rule_') \
        .replace('AnyHttpUrl', 'str')
        
    alerts = eval(alerts_cleaned_string)

    clean_alerts = []
    clean_alert_ids = []

    for alert in alerts:
        clean = {}
        if 'email' in alert:
            clean['email'] = alert['email']
        if 'team' in alert:
            clean['team'] = alert['team']
        if 'slack' in alert:
            clean['slack'] = alert['slack']
        if 'repository' in alert:
            clean['repository'] = alert['repository']

        clean['keep_id'] = alert['id']
        clean['severity'] = alert['severity']
        clean['environment'] = alert['environment']
        clean['description'] = alert['description']
        clean['keep_event_id'] = alert['event_id']
        clean['kibana_alert_url'] = alert['url']
        clean['kibana_rule_id'] = alert['ruleId']
        clean['kibana_rule_name'] = alert['name']
        clean['kibana_alert_id'] = alert['fingerprint']
        clean['host'] = alert['host']
        clean_alert_ids.append(clean['kibana_alert_id'])
        clean_alerts.append(clean)

    return clean_alerts, clean_alert_ids

@app.get('/health')
def get_health():
    return {'kernel': 'ok' }

@app.post('/alarms/clean')
def post_alarms_clean():
    body = request.get_json()
    clean_alarms, clean_alert_ids = parse_alerts(body)
    return {'alarms': json.dumps(clean_alarms), 'alert_ids': json.dumps(clean_alert_ids) }

def alarms_rca(prompt, alert_ids):    
    now_utc = datetime.now(timezone.utc)

    content = prompt + " alert_ids = " + ", ".join(alert_ids)
    print(content)

    body = {
        "connectorId": "Elastic-Managed-LLM",
        "disableFunctions": False,
        "messages": [
            {
                "@timestamp": f"{now_utc.strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3] + 'Z'}",
                "message": {
                    "role": "user",
                    "content": content
                }
            }
        ],
        "persist": True,
        "actions": [],
        "instructions": ["return a json-formatted object with a field called 'title' that is a short 3 word title for the incident, a field called 'description' which is a 15 word description for the incident, and a field called 'summary' which is a detailed summary of the issue and the root cause analysis"]
    }
    resp = requests.post(f"{KB_ADDRESS}/api/observability_ai_assistant/chat/complete",
                                    json=body,
                                     timeout=TIMEOUT,
                                     auth=(ES_USER, ES_PASS),
                                     headers={"kbn-xsrf": "reporting", "Content-Type": "application/json"})
    #print(resp.text)

    resp_json = []
    for line in resp.text.strip().split('\n'):
        jline = json.loads(line)
        if jline['type'] == 'chatCompletionMessage':
            resp_json.append(jline)

    #print(resp_json)
    last_msg = resp_json[len(resp_json)-1]
    print(last_msg)
    if 'function_call' in last_msg['message']:
        response = last_msg['message']['function_call']['arguments']['response']
    else:
        response = last_msg['message']['content']
    print(response)

    pattern = re.escape('```json') + r"(.*?)" + re.escape('```')
    match = re.search(pattern, response, re.DOTALL)

    if match:
        extracted_content = match.group(1)
        print(extracted_content)
    else:
        print("No match found.")

    print(extracted_content)
    return extracted_content

    # repaired_json_string = repair_json(resp.text)
    # test = json.loads(repaired_json_string)
    # print(test)

@app.post('/alarms/rca')
def post_alarms_rca():
    body = request.get_json()
    print(body)
    body_json=body
    #body_json = json.loads(body)
    alarms = body_json['alarms']
    print(alarms)

    clean_alarms, clean_alert_ids = parse_alerts(alarms)
    print(clean_alarms)
    print(clean_alert_ids)

    prompt = body_json['prompt']

    res = alarms_rca(prompt, clean_alert_ids)
    print(res)
    return {'result': json.dumps(res)}

def get_connectors():
    res = requests.get(f"{KB_ADDRESS}/api/cases/configure/connectors/_find",
                                     timeout=TIMEOUT,
                                     auth=(ES_USER, ES_PASS),
                                     headers={"kbn-xsrf": "reporting", "Content-Type": "application/json"})

    connectors_by_type = {}
    json = res.json()
    for connector in json:
        if connector['actionTypeId'] not in connectors_by_type:
            connectors_by_type[connector['actionTypeId']] = []
        connectors_by_type[connector['actionTypeId']].append(connector)

    print(connectors_by_type)
    return connectors_by_type

#get_connectors()

def get_custom_fields():

    res = requests.get(f"{KB_ADDRESS}/api/cases/configure",
                                     timeout=TIMEOUT,
                                     auth=(ES_USER, ES_PASS),
                                     headers={"kbn-xsrf": "reporting", "Content-Type": "application/json"})
    json = res.json()
    #print(json)
    customFields = {}
    for setting in json:
        for customField in setting['customFields']:
            customFields[customField['label']] = customField['key']
    #print(customFields)
    return customFields

def create_case(incident, message, alarms):

    connectors = get_connectors()
    if '.servicenow' in connectors:
        connector = {
            "id": connector['id'],
            "type": ".servicenow",
            "fields": {
                "urgency": "1",
                "severity": "2",
                "impact": "3",
                "category": "software",
                "subcategory": None,
                "additionalFields": None
            },
            "name": connector['name']
        }
    else:
        connector = {
            "id": "none",
            "name": "none",
            "type": ".none",
            "fields": []
        }

    case_custom_fields = {}

    custom_fields = get_custom_fields()
    for custom_field in custom_fields.keys():
        case_custom_fields[custom_field] = {}
        case_custom_fields[custom_field]['values'] = []
        case_custom_fields[custom_field]['type'] = custom_field['type']
        case_custom_fields[custom_field]['key'] = custom_field['key']   

    for alarm in alarms:
        for custom_field in custom_fields.keys():
            if custom_field in alarm and alarm[custom_field] not in case_custom_fields[custom_field]['values']:
                case_custom_fields[custom_field]['values'].append(alarm[custom_field])

    for case_custom_field in case_custom_fields.keys():
        case_custom_fields[case_custom_field]['value'] = ", ".join(case_custom_fields[custom_field]['values'])
        del case_custom_fields[custom_field]['values']

    print(case_custom_fields.values())
    customFields = case_custom_fields.values(
    
    body = {
        "tags":["keep"],
        "owner":"observability",
        "title":message['title'],
        "settings":{"syncAlerts":False},
        "connector":connector,
        "description":message['description'],
        "customFields":customFields
    }

    print(body)

    res = requests.post(f"{KB_ADDRESS}/api/cases",
                                    json=body,
                                     timeout=TIMEOUT,
                                     auth=(ES_USER, ES_PASS),
                                     headers={"kbn-xsrf": "reporting", "Content-Type": "application/json"})
    print(res)
    case_id = res.json()['id']
    print(case_id)

    for alarm in alarms:
        body= {
            "query": {
                "term": {
                "_id": {
                    "value": alarm['kibana_alert_id']
                }
                }
            }
        }
        res = requests.get(f"{ES_ADDRESS}/.alerts-observability.*/_search",
                                    json=body,
                                     timeout=TIMEOUT,
                                     auth=(ES_USER, ES_PASS),
                                     headers={"kbn-xsrf": "reporting", "Content-Type": "application/json"})
        json = res.json()
        index = json['hits']['hits'][0]['_index']

        body = {
            "type": "alert",
            "owner": "observability",
            "alertId": alarm['kibana_alert_id'],
            "index": index,
            "rule": {
                "id": alarm['kibana_rule_id'],
                "name": alarm['kibana_rule_name'],
            }
        }
        print(body)
        
        comment = requests.post(f"{KB_ADDRESS}/api/cases/{case_id}/comments",
                                        json=body,
                                        timeout=TIMEOUT,
                                        auth=(ES_USER, ES_PASS),
                                        headers={"kbn-xsrf": "reporting", "Content-Type": "application/json"})

        print(comment)

    body = {
        "type": "user",
        "owner": "observability",
        "comment": message['summary']
    }
    print(body)
    
    comment = requests.post(f"{KB_ADDRESS}/api/cases/{case_id}/comments",
                                    json=body,
                                    timeout=TIMEOUT,
                                    auth=(ES_USER, ES_PASS),
                                    headers={"kbn-xsrf": "reporting", "Content-Type": "application/json"})


@app.post('/case/create')
def post_case():
    body = request.get_json()
    body_json = json.loads(body)
    print(body_json)
    incident = body_json['incident']
    message = body_json['message']
    print(message)
    test = json.loads(message)
    alarms = body_json['alarms']

    clean_alarms, clean_alert_ids = parse_alerts(alarms)
    print(clean_alarms)
    print(clean_alert_ids)

    create_case(incident, test, clean_alarms)
    return {'result': 'success'}


# response = "ty\n```json\nblah\n```nah"
# pattern = re.escape('```json') + r"(.*?)" + re.escape('```')
# match = re.search(pattern, response, re.DOTALL)

# if match:
#     extracted_content = match.group(1)
#     print(extracted_content)
# else:
#     print("No match found.")


