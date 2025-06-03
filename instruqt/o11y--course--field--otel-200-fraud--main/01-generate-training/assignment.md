---
slug: generate-training
id: icjbgncknxen
type: challenge
title: Generate Training
tabs:
- id: mym97vj0hmjv
  title: Elastic
  type: service
  hostname: kubernetes-vm
  path: /app/dev_tools#/console/shell
  port: 30001
- id: allim22boynn
  title: Trader
  type: service
  hostname: host-1
  path: /#/train
  port: 9090
- id: grqljfnk8gzv
  title: Terminal (host-1)
  type: terminal
  hostname: host-1
  workdir: /workspace/workshop
- id: cfmasc9oibxh
  title: Terminal (kubernetes-vm)
  type: terminal
  hostname: kubernetes-vm
difficulty: ""
timelimit: 0
enhanced_loading: null
---

# Create Data View

1. [button label="Elastic"](tab-0)
2. Copy and paste the following into the left-hand pane of Elasticsearch Developer Tools
```
POST /_aliases
{
  "actions": [
    {
      "add": {
        "index": "traces-*",
        "alias": "traces-trader",
        "filter": {
          "bool": {
            "must": [
              {
                "term": {
                  "service.name": "trader"
                }
              },
              {
                "exists": {
                  "field": "attributes.com.example.shares"
                }
              }
            ]
          }
        }
      }
    }
  ]
}
```
3. Execute the `POST` command by clicking on the play triangle on the right side of the first line of the POST
4. Confirm the response
```
{
  "acknowledged": true,
  "errors": false
}
```

# Generate Training Data

1. [button label="Trader"](tab-1)
2. Configure classification (leave `Classification` and `Data Source` fields as is)
3. Click `SUBMIT`
4. Wait for spinner to complete

# Validate Training Data

1. [button label="Elastic"](tab-0)
2. Navigation menu > Discover
3. Set `Data view` to `traces-trader`
4. Set `Filter` to `attributes.com.example.data_source : "training"`
5. Verify data
6. Set `Filter` to `attributes.com.example.data_source : "training" and attributes.com.example.classification : "fraud"`
7. Verify data
